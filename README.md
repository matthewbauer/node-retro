[![Stories in Ready](https://badge.waffle.io/matthewbauer/node-retro.png?label=ready&title=Ready)](https://waffle.io/matthewbauer/node-retro)
node-retro [![Build Status](https://travis-ci.org/matthewbauer/node-retro.svg?branch=master)](https://travis-ci.org/matthewbauer/node-retro)
============================================================================================================================================

Use node-retro to run libretro cores from within node. This is used by gametime-player to load cores for emulation.

DESIGN
------

node-retro is designed to be minimilistic to let users decide how they want to use libretro cores. Methods should be bound by .on'ing them.

One lingering concern is how to store binary data in Javascript. There are two implementations of basically the same thing available:

-	node's Buffer
-	v8's ArrayBuffer

Both have been used in node-retro for different purposes. When a file is probably going to be loaded/accessed it will expect a node Buffer (so the fs commands work without fixes). During video/audio callbacks ArrayBuffer is used because they are expected by the two dominant APIs:

-	AudioContext
-	WebGL

EXAMPLE
-------

For an example implementation of node-retro, look at my repo [gametime-player](http://github.com/matthewbauer/gametime-player). It uses Web APIs to run libretro cores.
