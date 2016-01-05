import std.stdio;

import jade;

import arsd.jsvar;

void main(string[] args) {
	auto filename = "index.jade";
	if (args.length > 1) {
		filename = args[1];
	}
	enum compileTime = render!"index.jade";
	writeln("templates count: ", compileTime.length);

	enum script = compileTime[0].getOutput(compileTime);
	pragma(msg, script);
	writeln("compileTime render:");
	string host = "localhost";
	mixin(script);
	writeln(buf.data);
	//writeln("runtime:");
	//auto runtime = render(filename);
	//runtime[0].getOutput(runtime).writeln;
}
