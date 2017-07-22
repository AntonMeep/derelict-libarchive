#!/usr/bin/env dub
/+
dub.json:
{
	"name": "compressor",
	"description": "Compresses file using libarchive",
	"dependencies": {
		"derelict-libarchive": {
			"path": "./../"
		}
	}
}
+/
/**
 * Compresses file
 * See Also: https://github.com/libarchive/libarchive/wiki/Examples#a-universal-decompressor
 */

import derelict.libarchive;
import std.conv : octal;
import std.stdio : File, stdin, stdout, stderr, writeln, writefln;
import std.string : toStringz, fromStringz;

shared static this() {
	DerelictLibArchive.load();
}

int main(string[] args) {
	if(args.length < 3) {
		writeln("Usage:");
		writeln("\tcompressor input output \tFile -> file");
		writeln("\tcompressor input -      \tFile -> STDIN");
		return 0;
	}

	File input = File(args[1], "rb");

	File output;
	if(args[2] == "-") {
		output = stdout;
	} else {
		output = File(args[2], "wb");
	}

	archive* ar = archive_write_new();
	scope(exit) archive_write_free(ar);

	archive_write_add_filter_gzip(ar);
	archive_write_set_format_pax_restricted(ar);

	auto r = archive_write_open_FILE(ar, output.getFP);
	if(r < ARCHIVE_OK) {
		stderr.writefln("Libarchive error: %s", archive_error_string(ar).fromStringz);
		return r;
	}

	archive_entry* entry = archive_entry_new();
	scope(exit) archive_entry_free(entry);

	archive_entry_set_pathname(entry, input.name.toStringz);
	archive_entry_set_size(entry, input.size);
	archive_entry_set_filetype(entry, AE_IFREG);
	archive_entry_set_perm(entry, octal!644);
	archive_write_header(ar, entry);

	foreach(ubyte[] buffer; input.byChunk(8192))
		archive_write_data(ar, buffer.ptr, buffer.length);

	return 0;
}
