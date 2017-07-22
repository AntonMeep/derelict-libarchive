#!/usr/bin/env dub
/+
dub.json:
{
	"name": "untar",
	"description": "Extracts tar archive using libarchive",
	"dependencies": {
		"derelict-libarchive": {
			"path": "./../"
		}
	}
}
+/
/**
 * Simple untar implementation
 * See Also: https://github.com/libarchive/libarchive/blob/master/examples/untar.c
 */

import derelict.libarchive;
import std.getopt;
import std.stdio : File, stderr, write, writeln, writefln;
import std.string : toStringz, fromStringz;
import std.format : format;

shared static this() {
	DerelictLibArchive.load();
}

bool verbose;
int main(string[] args) {
	int flags = ARCHIVE_EXTRACT_TIME;
	bool do_extract = false;
	string file;

	args.getopt(
		"file|f", "input file", &file,
		"test|t", "do not write any files", () { do_extract = false; },
		"extract|x", "extract files", () { do_extract = true; },
		"verbose|v", "be verbose", &verbose);

	if(file.length == 0) {
		writeln("Usage: untar [-tvx] [-f=file]");
		return 0;
	}

	return extract(file, do_extract, flags);
}

void warn(alias fun, string f = __FILE__, size_t l = __LINE__, A...)(archive* a, A args) {
	auto r = fun(a, args);
	if(r != ARCHIVE_OK)
		stderr.writefln("Warning: %s", archive_error_string(a).fromStringz);
}

void fail(alias fun, string f = __FILE__, size_t l = __LINE__, A...)(archive* a, A args) {
	auto r = fun(a, args);
	if(r != ARCHIVE_OK)
		throw new Exception("Error: %s".format(archive_error_string(a).fromStringz));
}

int extract(string file, bool do_extract, int flags) {
	auto a = archive_read_new();
	scope(exit) {
		archive_read_close(a);
		archive_read_free(a);
	}
	auto ext = archive_write_disk_new();
	scope(exit) {
		archive_write_close(ext);
		archive_write_free(ext);
	}

	archive_write_disk_set_options(ext, flags);

	archive_read_support_format_tar(a);

	fail!archive_read_open_filename(a, file == "-" ? null : file.toStringz, 1337);

	archive_entry* entry;

	while(true) {
		auto r = archive_read_next_header(a, &entry);
		if(r == ARCHIVE_EOF)
			break;
		if(r != ARCHIVE_OK)
			throw new Exception("Error: %s".format(archive_error_string(a).fromStringz));

		if(verbose && do_extract)
			write("x ");

		if(verbose || !do_extract)
			write(archive_entry_pathname(entry).fromStringz);

		if(do_extract) {
			r = archive_write_header(ext, entry);
			if(r != ARCHIVE_OK) {
				stderr.writefln("Warn: %s", archive_error_string(ext).fromStringz);
			} else {
				copy_data(a, ext);
				fail!archive_write_finish_entry(ext);
			}
		}

		if(verbose || !do_extract)
			writeln;
	}

	return 0;
}

void copy_data(archive* ar, archive* aw) {
	const(void)* buff;
	size_t size;
	long offset;

	while(true) {
		auto r = archive_read_data_block(ar, &buff, &size, &offset);
		if(r == ARCHIVE_EOF)
			return;
		if(r != ARCHIVE_OK)
			throw new Exception("Error: %s".format(archive_error_string(ar).fromStringz));
		fail!archive_write_data_block(aw, buff, size, offset);
	}
}

