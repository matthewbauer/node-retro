// Copyright 2015 Matthew Bauer <mjbauer95@gmail.com>
#include <nan.h>
#include <node.h>

#include <stdarg.h>
#include <stdio.h>
#include <dlfcn.h>

#include <string>

#include "./libretro.h"

using v8::Value;
using v8::Local;
using v8::String;
using v8::Function;
using v8::Object;
using v8::Number;
using v8::Handle;
using v8::Integer;
using v8::Boolean;
using namespace node;

// pointer to core
void* lib_handle;

// core methods, not included in libretro.h?
void (*pretro_init)(void);
void (*pretro_deinit)(void);
unsigned (*pretro_api_version)(void);
void (*pretro_get_system_info)(struct retro_system_info*);
void (*pretro_get_system_av_info)(struct retro_system_av_info*);
void (*pretro_set_environment)(retro_environment_t);
void (*pretro_set_video_refresh)(retro_video_refresh_t);
void (*pretro_set_audio_sample)(retro_audio_sample_t);
void (*pretro_set_audio_sample_batch)(retro_audio_sample_batch_t);
void (*pretro_set_input_poll)(retro_input_poll_t);
void (*pretro_set_input_state)(retro_input_state_t);
void (*pretro_set_controller_port_device)(unsigned, unsigned);
void (*pretro_reset)(void);
void (*pretro_run)(void);
size_t (*pretro_serialize_size)(void);
bool (*pretro_serialize)(void*, size_t);
bool (*pretro_unserialize)(const void*, size_t);
void (*pretro_cheat_reset)(void);
void (*pretro_cheat_set)(unsigned, bool, const char*);
bool (*pretro_load_game)(const struct retro_game_info*);
bool (*pretro_load_game_special)(unsigned,
  const struct retro_game_info*, size_t);
void (*pretro_unload_game)(void);
unsigned (*pretro_get_region)(void);
void *(*pretro_get_memory_data)(unsigned);
size_t (*pretro_get_memory_size)(unsigned);

// Our only reference to Javascript-land in retro calls
NanCallback* listener;

// Should this be deferred to Javascript?
void Log(enum retro_log_level level, const char* fmt, ...) {
  char error[1024];
  va_list argptr;
  va_start(argptr, fmt);
  vsnprintf(error, sizeof(error), fmt, argptr);
  va_end(argptr);
  Local<Value> args[] = { NanNew<String>("log"),
    NanNew<Number>(level),
    NanNew<String>(error) };
  listener->Call(3, args);
}

// Most of this will have to be done in C, but use callback wherever possible
bool Environment_cb(unsigned cmd, void* data) {
  if (cmd == RETRO_ENVIRONMENT_GET_LOG_INTERFACE) {
    struct retro_log_callback* cb = (struct retro_log_callback*) data;
    cb->log = Log;
    return true;
  }

  Local<Value> value;

  switch (cmd) {
    case RETRO_ENVIRONMENT_SET_VARIABLES: {
      const struct retro_variable* vars = (const struct retro_variable*) data;
      Local<Object> settings = NanNew<Object>();
      for (const struct retro_variable* var = vars;
        var->key && var->value; var++) {
        settings->Set(NanNew<String>(var->key), NanNew<String>(var->value));
      }
      value = settings;
      break;
    }
    case RETRO_ENVIRONMENT_SET_PERFORMANCE_LEVEL: {
      value = NanNew<Number>(*(const unsigned*)data);
      break;
    }
    case RETRO_ENVIRONMENT_SET_SUPPORT_NO_GAME: {
      value = NanNew<Boolean>(*(const bool*)data);
      break;
    }
    case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT: {
      enum retro_pixel_format pix_fmt = *(const enum retro_pixel_format*)data;
      value = NanNew<Number>(pix_fmt);
      break;
    }
    case RETRO_ENVIRONMENT_GET_VARIABLE: {
      struct retro_variable* var = (struct retro_variable*)data;
      value = NanNew<String>(var->key);
      break;
    }
    case RETRO_ENVIRONMENT_GET_OVERSCAN:
    case RETRO_ENVIRONMENT_GET_CAN_DUPE:
    case RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE:
    case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_USERNAME:
    case RETRO_ENVIRONMENT_GET_CORE_ASSETS_DIRECTORY:
      value = NanNull();
      break;
    default: {
      value = NanNull();
      printf("Unhandled environment command %i\n", cmd);
    }
  }

  Local<Value> args[] = { NanNew<String>("environment"),
    NanNew<Number>(cmd),
    value };
  Handle<Value> out = listener->Call(3, args);

  switch (cmd) {
    case RETRO_ENVIRONMENT_GET_OVERSCAN:
    case RETRO_ENVIRONMENT_GET_CAN_DUPE:
    case RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE: {
      *(bool*)data = out->BooleanValue();
      break;
    }
    case RETRO_ENVIRONMENT_GET_VARIABLE: {
      struct retro_variable *var = (struct retro_variable*)data;
      String::Utf8Value str(out->ToString());
      var->value = *str;
      break;
    }
    case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_USERNAME:
    case RETRO_ENVIRONMENT_GET_CORE_ASSETS_DIRECTORY: {
      String::Utf8Value str(out->ToString());
      *(const char**)data = *str;
      break;
    }
    case RETRO_ENVIRONMENT_GET_LANGUAGE: {
      *(unsigned*)data = out->Uint32Value();
      break;
    }
  }

  return out->BooleanValue();  // this may run give us problems with nonerrors
}

void VideoRefresh(const void *data, unsigned width, unsigned height,
  size_t pitch) {
  if (data == NULL) {
    return;
  }
  if (pitch == 0) {
    pitch = 4 * width;
  }
  Local<Value> args[] = {
    NanNew<String>("videorefresh"),
    NanNewBufferHandle((char*)data, height * pitch),
    NanNew<Number>(width),
    NanNew<Number>(height),
    NanNew<Number>(pitch) };
  listener->Call(5, args);
}

void AudioSample(int16_t left, int16_t right) {
  Local<Value> args[] = {
    NanNew<String>("audiosample"),
    NanNew<Number>(left),
    NanNew<Integer>(right)
  };
  listener->Call(3, args);
}

size_t AudioSampleBatch(const int16_t* data, size_t frames) {
  // convert to floats for AudioContext
  // maybe better to do this in Javascript.
  float* newData = (float*) malloc(frames * 2 * sizeof(float));
  for (size_t i = 0; i < frames * 2; i++) {
    newData[i] = (float)data[i] / 0x8000;
  }
  Local<Value> args[] = {
    NanNew<String>("audiosamplebatch"),
    NanNewBufferHandle((char*)newData, frames * 2 * sizeof(float)),
    NanNew<Number>(frames)
  };
  return listener->Call(3, args)->Uint32Value();
}

void InputPoll() {
  Local<Value> args[] = {
    NanNew<String>("inputpoll")
  };
  listener->Call(1, args);
}

int16_t InputState(unsigned port, unsigned device, unsigned idx, unsigned id) {
  Local<Value> args[] = {
    NanNew<String>("inputstate"),
    NanNew<Number>(port),
    NanNew<Number>(device),
    NanNew<Number>(idx),
    NanNew<Number>(id)
  };
  return listener->Call(5, args)->Uint32Value();
}

NAN_METHOD(Listen) {
  listener = new NanCallback(Local<Function>::Cast(args[0]));
  NanReturnUndefined();
}

#define SYM(x) { void* func = dlsym(lib_handle, #x); \
  memcpy(&p##x, &func, sizeof(func)); \
  if (p##x == NULL) { } }

NAN_METHOD(LoadCore) {
  NanUtf8String path(args[0]);
  lib_handle = dlopen(*path, RTLD_LAZY);
  SYM(retro_init);
  SYM(retro_deinit);
  SYM(retro_set_environment);
  SYM(retro_set_video_refresh);
  SYM(retro_set_audio_sample);
  SYM(retro_set_audio_sample_batch);
  SYM(retro_set_input_poll);
  SYM(retro_set_input_state);
  SYM(retro_set_controller_port_device);
  SYM(retro_reset);
  SYM(retro_run);
  SYM(retro_load_game);
  SYM(retro_unload_game);
  SYM(retro_api_version);
  SYM(retro_get_system_info);
  SYM(retro_get_system_av_info);
  SYM(retro_get_region);
  SYM(retro_serialize_size);  // unused
  SYM(retro_serialize);  // unused
  SYM(retro_unserialize);  // unused
  SYM(retro_cheat_reset);  // unused
  SYM(retro_cheat_set);  // unused
  SYM(retro_load_game_special);  // unused
  SYM(retro_get_memory_data);  // unused
  SYM(retro_get_memory_size);  // unused
  pretro_set_environment(Environment_cb);
  pretro_init();
  pretro_set_video_refresh(VideoRefresh);
  pretro_set_audio_sample(AudioSample);
  pretro_set_audio_sample_batch(AudioSampleBatch);
  pretro_set_input_poll(InputPoll);
  pretro_set_input_state(InputState);
  NanReturnUndefined();
}

NAN_METHOD(Run) {  // TODO(matthewbauer): lessen overhead of this function
  pretro_run();
  NanReturnUndefined();
}

NAN_METHOD(Reset) {
  pretro_reset();
  NanReturnUndefined();
}

NAN_METHOD(APIVersion) {
  NanReturnValue(NanNew<Integer>(pretro_api_version()));
}

NAN_METHOD(GetRegion) {
  NanReturnValue(NanNew<Number>(pretro_get_region()));
}

NAN_METHOD(GetSystemInfo) {
  struct retro_system_info info;
  pretro_get_system_info(&info);
  Local<Object> object = NanNew<Object>();
  object->Set(NanNew<String>("library_name"), NanNew<String>(info.library_name));
  object->Set(NanNew<String>("library_version"), NanNew<String>(info.library_version));
  object->Set(NanNew<String>("valid_extensions"), NanNew<String>(info.valid_extensions));
  object->Set(NanNew<String>("need_fullpath"), NanNew<Boolean>(info.need_fullpath));
  object->Set(NanNew<String>("block_extract"), NanNew<Number>(info.block_extract));
  NanReturnValue(object);
}

NAN_METHOD(GetSystemAVInfo) {
  struct retro_system_av_info info;
  pretro_get_system_av_info(&info);
  Local<Object> timing = NanNew<Object>();
  timing->Set(NanNew<String>("fps"), NanNew<Number>(info.timing.fps));
  timing->Set(NanNew<String>("sample_rate"), NanNew<Number>(info.timing.sample_rate));
  Local<Object> geometry = NanNew<Object>();
  geometry->Set(NanNew<String>("base_width"), NanNew<Number>(info.geometry.base_width));
  geometry->Set(NanNew<String>("base_height"), NanNew<Number>(info.geometry.base_height));
  geometry->Set(NanNew<String>("max_width"), NanNew<Number>(info.geometry.max_width));
  geometry->Set(NanNew<String>("max_height"), NanNew<Number>(info.geometry.max_height));
  geometry->Set(NanNew<String>("aspect_ratio"), NanNew<Number>(info.geometry.aspect_ratio));
  Local<Object> object = NanNew<Object>();
  object->Set(NanNew<String>("timing"), timing);
  object->Set(NanNew<String>("geometry"), geometry);
  NanReturnValue(object);
}

NAN_METHOD(LoadGamePath) {
  NanUtf8String path(args[0]);
  struct retro_game_info game;
  game.path = *path;
  FILE *fp = fopen(game.path, "r");
  fseek(fp, 0L, SEEK_END);
  game.size = ftell(fp);
  fseek(fp, 0L, SEEK_SET);
  void *buffer = malloc(game.size);
  fread(buffer, 1, game.size, fp);
  game.data = buffer;
  fclose(fp);
  pretro_load_game(&game);
  NanReturnUndefined();
}

NAN_METHOD(LoadGame) {
  struct retro_game_info game;
  Local<Object> bufferObj = args[0]->ToObject();
  game.size = Buffer::Length(bufferObj);
  game.data = Buffer::Data(bufferObj);
  pretro_load_game(&game);
  NanReturnUndefined();
}

NAN_METHOD(Close) {
  delete listener;
  pretro_unload_game();
  pretro_deinit();
  dlclose(lib_handle);
  NanReturnUndefined();
}

void InitAll(Handle<Object> exports) {
  NODE_SET_METHOD(exports, "loadCore", LoadCore);
  NODE_SET_METHOD(exports, "loadGame", LoadGame);
  NODE_SET_METHOD(exports, "loadGamePath", LoadGamePath);
  NODE_SET_METHOD(exports, "run", Run);
  NODE_SET_METHOD(exports, "getSystemInfo", GetSystemInfo);
  NODE_SET_METHOD(exports, "getSystemAVInfo", GetSystemAVInfo);
  NODE_SET_METHOD(exports, "api_version", APIVersion);
  NODE_SET_METHOD(exports, "getRegion", GetRegion);
  NODE_SET_METHOD(exports, "listen", Listen);
  NODE_SET_METHOD(exports, "reset", Reset);
  NODE_SET_METHOD(exports, "close", Close);
}

NODE_MODULE(addon, InitAll)
