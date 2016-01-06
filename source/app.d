import std.stdio;

import jade;

import arsd.jsvar;

void main(string[] args) {
	import std.getopt;
	string filename = "views/mixins.jade";
	bool doCompileTime=false, doBoth=false;
	auto helpInfo = getopt(args,
		"filename|f", "File to parse", &filename
		);
	if (args.length > 1) {
		filename = args[1];
	}
	static if (false) {
		writeln("compileTime");
		enum compileTime = render!"mixins.jade";
		writeln("templates count: ", compileTime.length);

		enum script = compileTime[0].getOutput(compileTime);
		pragma(msg, script);
		writeln("compileTime render:");
		string host = "localhost";
		mixin(script);
		writeln(buf.data);
	}
	writeln("runtime:");
	auto runtime = render(filename);
	runtime[0].getOutput(runtime).writeln;
}
