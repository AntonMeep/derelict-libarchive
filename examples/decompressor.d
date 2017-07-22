#!/usr/bin/env dub
/+
dub.json:
{
	"name": "decompressor",
	"description": "Decompresses using libarchive",
	"dependencies": {
		"derelict-libarchive": {
			"path": "./../"
		},
		"derelict-util": "~>3.0.0-beta.1"
	}
}
+/
/**
 * Decompresses file
 * See Also: https://github.com/libarchive/libarchive/wiki/Examples#a-universal-decompressor
 */

import derelict.libarchive;
import std.stdio : File, stdin, stdout, stderr, writeln, writefln;
import std.string : fromStringz;


import derelict.util.exception : ShouldThrow;
ShouldThrow missingSymCB(string symbol) {
	import std.algorithm : canFind;
	return [
		"archive_read_new",
		"archive_read_data",
		"archive_read_free",
		"archive_read_support_filter_all",
		"archive_read_support_format_raw",
		"archive_read_open_FILE",
		"archive_error_string",
		"archive_read_next_header"
	].canFind(symbol) ? ShouldThrow.Yes : ShouldThrow.No;
}

shared static this() {
	DerelictLibArchive.missingSymbolCallback = &missingSymCB;
	DerelictLibArchive.load();
}

int main(string[] args) {
	if(args.length < 3) {
		writeln("Usage:");
		writeln("\tdecompressor input output \tFile -> file");
		writeln("\tdecompressor -     output \tSTDIN -> file");
		writeln("\tdecompressor -     -      \tSTDIN -> STDIN");
		writeln("\tdecompressor input -      \tFile -> STDIN");
		return 0;
	}

	File input;
	if(args[1] == "-") {
		input = stdin;
	} else {
		input = File(args[1], "rb");
	}

	File output;
	if(args[2] == "-") {
		output = stdout;
	} else {
		output = File(args[2], "wb");
	}

	archive* ar = archive_read_new();
	scope(exit) archive_read_free(ar);

	archive_read_support_filter_all(ar);
	archive_read_support_format_raw(ar);

	auto r = archive_read_open_FILE(ar, input.getFP);
	if(r < ARCHIVE_OK) {
		stderr.writefln("Libarchive error: %s", archive_error_string(ar).fromStringz);
		return r;
	}

	archive_entry* entry;
	r = archive_read_next_header(ar, &entry);
	if(r < ARCHIVE_OK) {
		stderr.writefln("Libarchive error: %s", archive_error_string(ar).fromStringz);
		return r;
	}

	ubyte[8192] buffer;
	while(true) {
		auto size = archive_read_data(ar, buffer.ptr, buffer.length);
		if(size < 0) {
			stderr.writefln("Libarchive error: %s", archive_error_string(ar).fromStringz);
			return cast(int) size;
		}
		if(size == 0)
			break;

		output.rawWrite(buffer[0..size]);
	}

	return 0;
}
