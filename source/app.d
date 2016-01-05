import std.stdio;

import jade;

void main(string[] args) {
	auto filename = "plaintext.jade";
	if (args.length > 1) {
		filename = args[1];
	}
	enum compileTime = render!"plaintext.jade";
	writeln("templates count: ", compileTime.length);

	enum script = compileTime[0].getOutput(compileTime);
	pragma(msg, script);
	writeln("compileTime render:");
	mixin(script);
	writeln(buf);
	writeln("runtime:");
	auto runtime = render(filename);
	runtime[0].getOutput(runtime).writeln;
}
