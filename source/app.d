import std.stdio;

import jade;

import arsd.jsvar;

void main(string[] args) {
	import std.getopt;
	string filename = "views/index.jade";
	bool doCompileTime=false, doBoth=false;
	auto helpInfo = getopt(args,
		"filename|f", "File to parse", &filename
		);
	if (args.length > 1) {
		filename = args[1];
	}
	static if (true) {
		writeln("compileTime");
		enum compileTime = render!"index.jade";
		writeln("templates count: ", compileTime.length);

		enum script = compileTime[0].getOutput(compileTime);
		pragma(msg, script);
		writeln("compileTime render:");

import std.traits;
	string escapeAttributeValue(T)(T arg) {
		import std.conv;
		import std.string : replace;
		return to!string(arg).replace(`\`, `\\`).replace(`"`, `&quote;`);
	}
	string escapeHtmlOutput(T)(T arg) {
		import std.conv;
		import std.string : replace;
		return to!string(arg).replace(`&`, `&amp`).replace(`<`, `&lt;`).replace(`>`, `&gt;`);
	}
	import std.string : format, join;
	string outputStyle(T)(T arg) {
		string[] ret;
		foreach (k,v; arg) {
			ret ~= "%s: %s".format(k, v);
		}
		return ret.join(";");
	}
	string outputCssClassArray(Args...)(Args args) {
		string[] ret;
		foreach (arg; args) {
			ret ~= escapeAttributeValue(arg);
		}
		return ret.join(",");
	}

		mixin(script);
		writeln(buf.data);
	}
	//writeln("runtime:");
	//auto runtime = render(filename);
	//runtime[0].getOutput(runtime).writeln;
}
