derelict-git2 [![Page on DUB](https://img.shields.io/dub/v/derelict-libarchive.svg)](http://code.dlang.org/packages/derelict-libarchive) [![License](https://img.shields.io/dub/l/derelict-libarchive.svg)](https://github.com/ohdatboi/derelict-libarchive/blob/master/LICENSE)
=============

A dynamic binding to [libarchive](http://www.libarchive.org/) for the D programming language.

Please see the sections on [Compiling and Linking](http://derelictorg.github.io/building/overview/) and [The Derelict Loader](http://derelictorg.github.io/loading/loader/) in the Derelict documentation for information on how to build DerelictPQ and load libpq at run time. In the meantime, here's some sample code.

## Example:
```d
import derelict.libarchive;

void main() {
	DerelictLibArchive.load(); // Load libarchive

	// Now you can call libarchive functions
}
```

Check out `./examples` directory for more examples.
