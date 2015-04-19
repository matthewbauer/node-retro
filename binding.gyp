{
  "targets": [
    {
      "target_name": "libretro",
      "sources": [ "binding.cc" ],
	  "include_dirs": [
	  	"<!(node -p -e \"require('path').dirname(require.resolve('nan'))\")"
	  ]
    }
  ]
}
