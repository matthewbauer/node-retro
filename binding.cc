// Copyright 2015 Matthew Bauer <mjbauer95@gmail.com>
#include <nan.h>
#include <node.h>

#include <stdarg.h>
#include <stdio.h>

#include <string>

#include "./libretro.h"

using v8::Isolate;
using v8::Value;
using v8::Local;
using v8::String;
using v8::Function;
using v8::Object;
using v8::Number;
using v8::Handle;
using v8::Integer;
using v8::Boolean;
using v8::ArrayBuffer;  // not support in node 0.10!

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
bool (*pretro_load_game_special)(unsigned, const struct retro_game_info*, size_t);
void (*pretro_unload_game)(void);
unsigned (*pretro_get_region)(void);
void *(*pretro_get_memory_data)(unsigned);
size_t (*pretro_get_memory_size)(unsigned);

// Our only reference to Javascript-land in retro calls
NanCallback* listener;

// bytes for video
int bytes_per_pixel = 2;

// Should this be deferred to Javascript?
void Log(enum retro_log_level level, const char* fmt, ...) {
  char error[1024];
  va_list argptr;
  va_start(argptr, fmt);
  vsnprintf(error, sizeof(error), fmt, argptr);
  va_end(argptr);
  Local<Value> args[] = {
    NanNew("log"),
    NanNew(level),
    NanNew(error)
  };
  listener->Call(3, args);
}

// Most of this will have to be done in C, but use JS callback wherever possible
bool Environment_cb(unsigned cmd, void* data) {
  if (cmd == RETRO_ENVIRONMENT_GET_LOG_INTERFACE) {
    struct retro_log_callback* cb = reinterpret_cast<struct retro_log_callback*>(data);
    cb->log = Log;
    return true;
  }

  Local<Value> value;

  switch (cmd) {
    case RETRO_ENVIRONMENT_SET_VARIABLES: {
      const struct retro_variable* vars = reinterpret_cast<const struct retro_variable*>(data);
      Local<Object> settings = NanNew<Object>();
      for (const struct retro_variable* var = vars;
        var->key && var->value; var++) {
        settings->Set(NanNew(var->key), NanNew(var->value));
      }
      value = settings;
      break;
    }
    case RETRO_ENVIRONMENT_SET_PERFORMANCE_LEVEL: {
      value = NanNew(*reinterpret_cast<const unsigned*>(data));
      break;
    }
    case RETRO_ENVIRONMENT_SET_SUPPORT_NO_GAME: {
      value = NanNew(*reinterpret_cast<const bool*>(data));
      break;
    }
    case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT: {
      enum retro_pixel_format pix_fmt = *reinterpret_cast<const enum retro_pixel_format*>(data);
      value = NanNew(pix_fmt);
      break;
    }
    case RETRO_ENVIRONMENT_GET_VARIABLE: {
      struct retro_variable* var = reinterpret_cast<struct retro_variable*>(data);
      value = NanNew(var->key);
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
    }
  }

  Local<Value> args[] = {
    NanNew("environment"),
    NanNew(cmd),
    value
  };
  Handle<Value> out = listener->Call(3, args);

  switch (cmd) {
    case RETRO_ENVIRONMENT_GET_OVERSCAN:
    case RETRO_ENVIRONMENT_GET_CAN_DUPE:
    case RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE: {
      *reinterpret_cast<bool*>(data) = out->BooleanValue();
      return out->BooleanValue();
    }
    case RETRO_ENVIRONMENT_GET_VARIABLE: {
      struct retro_variable *v = reinterpret_cast<struct retro_variable*>(data);
      String::Utf8Value str(out->ToString());
      v->value = *str;
      break;
    }
    case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_USERNAME:
    case RETRO_ENVIRONMENT_GET_CORE_ASSETS_DIRECTORY: {
      String::Utf8Value str(out->ToString());
      *reinterpret_cast<const char**>(data) = *str;
      break;
    }
    case RETRO_ENVIRONMENT_GET_LANGUAGE: {
      *reinterpret_cast<unsigned*>(data) = out->Uint32Value();
      break;
    }
  }

  return true;
}

void VideoRefresh(const void* data, unsigned w, unsigned h, size_t pitch) {
  char* buffer = reinterpret_cast<char*>(malloc(h * w * bytes_per_pixel));
  for (unsigned line = 0; line < h; line++) {
    memcpy(buffer + line * w * bytes_per_pixel, reinterpret_cast<const char*>(data) + line * pitch, w * bytes_per_pixel);
  }
  Local<Value> args[] = {
    NanNew("videorefresh"),
    ArrayBuffer::New(Isolate::GetCurrent(), buffer, h * w * bytes_per_pixel),
    NanNew(w),
    NanNew(h)
  };
  listener->Call(4, args);
}

void AudioSample(int16_t left, int16_t right) {
  Local<Value> args[] = {
    NanNew("audiosample"),
    NanNew(left),
    NanNew(right)
  };
  listener->Call(3, args);
}

size_t AudioSampleBatch(const int16_t* data, size_t frames) {
  float* left = reinterpret_cast<float*>(malloc(frames * 4));
  float* right = reinterpret_cast<float*>(malloc(frames * 4));
  for (size_t frame = 0; frame < frames; frame++) {
    left[frame] = static_cast<float>(data[frame * 2]) / 0x8000;
    right[frame] = static_cast<float>(data[frame * 2 + 1]) / 0x8000;
  }
  Local<Value> args[] = {
    NanNew("audiosamplebatch"),
    ArrayBuffer::New(Isolate::GetCurrent(), left, frames * 4),
    ArrayBuffer::New(Isolate::GetCurrent(), right, frames * 4),
    NanNew<Number>(frames)
  };
  return listener->Call(4, args)->Uint32Value();
}

void InputPoll() {
  Local<Value> args[] = {
    NanNew("inputpoll")
  };
  listener->Call(1, args);
}

int16_t InputState(unsigned port, unsigned device, unsigned idx, unsigned id) {
  Local<Value> args[] = {
    NanNew("inputstate"),
    NanNew(port),
    NanNew(device),
    NanNew(idx),
    NanNew(id)
  };
  return listener->Call(5, args)->Uint32Value();
}

NAN_METHOD(Listen) {
  NanScope();
  listener = new NanCallback(Local<Function>::Cast(args[0]));
  NanReturnUndefined();
}

#define SYM(sym) if (uv_dlsym(libretro, #sym, reinterpret_cast<void**>(&p##sym))) { \
  return NanThrowError("retro.LoadCore: Could not link " #sym "."); \
}

NAN_METHOD(LoadCore) {
  NanScope();
  NanUtf8String path(args[0]);

  uv_lib_t* libretro = reinterpret_cast<uv_lib_t*>(malloc(sizeof(uv_lib_t)));
  if (uv_dlopen(*path, libretro)) {
    return NanThrowError("retro.LoadCore: Shared library not found.");
  }

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
  SYM(retro_serialize_size);
  SYM(retro_serialize);
  SYM(retro_unserialize);
  SYM(retro_cheat_reset);  // UNIMPLEMENTED
  SYM(retro_cheat_set);  // UNIMPLEMENTED
  SYM(retro_load_game_special);  // UNIMPLEMENTED
  SYM(retro_get_memory_data);  // UNIMPLEMENTED
  SYM(retro_get_memory_size);  // UNIMPLEMENTED

  pretro_set_environment(Environment_cb);
  pretro_init();
  pretro_set_video_refresh(VideoRefresh);
  pretro_set_audio_sample(AudioSample);
  pretro_set_audio_sample_batch(AudioSampleBatch);
  pretro_set_input_poll(InputPoll);
  pretro_set_input_state(InputState);

  NanReturnUndefined();
}

NAN_METHOD(Run) {
  NanScope();
  pretro_run();
  NanReturnUndefined();
}

uv_timer_t timer;

void run(uv_timer_t* handle) {
  pretro_run();
}

void start_async(uv_work_t* request) {
  uv_timer_init(uv_default_loop(), &timer);
  uv_timer_start(&timer, &run, 0, *reinterpret_cast<uint32_t*>(request->data));
}

NAN_METHOD(Start) {
  NanScope();
  uint32_t* interval = reinterpret_cast<uint32_t*>(malloc(4));
  *interval = args[0]->Uint32Value();
  uv_work_t* request = reinterpret_cast<uv_work_t*>(malloc(sizeof(uv_work_t)));
  request->data = interval;
  uv_queue_work(uv_default_loop(), request, &start_async, NULL);
  NanReturnUndefined();
}

NAN_METHOD(Stop) {
  NanScope();
  uv_timer_stop(&timer);
  NanReturnUndefined();
}

NAN_METHOD(Reset) {
  NanScope();
  pretro_reset();
  NanReturnUndefined();
}

NAN_METHOD(APIVersion) {
  NanScope();
  NanReturnValue(NanNew(pretro_api_version()));
}

NAN_METHOD(GetRegion) {
  NanScope();
  NanReturnValue(NanNew(pretro_get_region()));
}

#define SET(obj, i, attr) obj->Set(NanNew(#attr), NanNew(i.attr));

NAN_METHOD(GetSystemInfo) {
  NanScope();
  struct retro_system_info info;
  pretro_get_system_info(&info);
  Local<Object> object = NanNew<Object>();
  SET(object, info, library_name);
  SET(object, info, library_version);
  SET(object, info, valid_extensions);
  SET(object, info, need_fullpath);
  SET(object, info, block_extract);
  NanReturnValue(object);
}

NAN_METHOD(GetSystemAVInfo) {
  NanScope();
  struct retro_system_av_info info;
  pretro_get_system_av_info(&info);
  Local<Object> object = NanNew<Object>();
  Local<Object> timing = NanNew<Object>();
  SET(timing, info.timing, fps);
  SET(timing, info.timing, sample_rate);
  object->Set(NanNew("timing"), timing);
  Local<Object> geometry = NanNew<Object>();
  SET(geometry, info.geometry, base_width);
  SET(geometry, info.geometry, base_height);
  SET(geometry, info.geometry, max_width);
  SET(geometry, info.geometry, max_height);
  SET(geometry, info.geometry, aspect_ratio);
  object->Set(NanNew("geometry"), geometry);
  NanReturnValue(object);
}

NAN_METHOD(LoadGamePath) {
  NanScope();
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
  NanScope();
  struct retro_game_info game;
  Local<Object> bufferObj = args[0]->ToObject();
  game.size = node::Buffer::Length(bufferObj);
  game.data = node::Buffer::Data(bufferObj);
  pretro_load_game(&game);
  NanReturnUndefined();
}

NAN_METHOD(UnloadGame) {
  NanScope();
  pretro_unload_game();
  NanReturnUndefined();
}

NAN_METHOD(Serialize) {
  NanScope();
  size_t size = pretro_serialize_size();
  void* memory = malloc(size);
  if (pretro_serialize(memory, size)) {
    NanReturnValue(NanNewBufferHandle(reinterpret_cast<char*>(memory), size));
  }
}

NAN_METHOD(Unserialize) {
  NanScope();
  Local<Object> buffer = args[0]->ToObject();
  void* data = reinterpret_cast<void*>(node::Buffer::Data(buffer));
  NanReturnValue(NanNew(pretro_unserialize(data, node::Buffer::Length(buffer))));
}

void InitAll(Handle<Object> exports) {
  NODE_SET_METHOD(exports, "loadCore", LoadCore);
  NODE_SET_METHOD(exports, "loadGame", LoadGame);
  NODE_SET_METHOD(exports, "loadGamePath", LoadGamePath);
  NODE_SET_METHOD(exports, "unloadGame", UnloadGame);
  NODE_SET_METHOD(exports, "getSystemInfo", GetSystemInfo);
  NODE_SET_METHOD(exports, "getSystemAVInfo", GetSystemAVInfo);
  NODE_SET_METHOD(exports, "unserialize", Unserialize);
  NODE_SET_METHOD(exports, "serialize", Serialize);
  NODE_SET_METHOD(exports, "api_version", APIVersion);
  NODE_SET_METHOD(exports, "getRegion", GetRegion);
  NODE_SET_METHOD(exports, "reset", Reset);
  NODE_SET_METHOD(exports, "listen", Listen);
  NODE_SET_METHOD(exports, "run", Run);
  NODE_SET_METHOD(exports, "start", Start);
  NODE_SET_METHOD(exports, "stop", Stop);
}

NODE_MODULE(addon, InitAll)
