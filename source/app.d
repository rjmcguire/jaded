import std.stdio;

import jade;

void main(string[] args) {
	auto filename = "index.jade";
	if (args.length > 1) {
		filename = args[1];
	}
	enum compileTime = render!"index.jade";
	//pragma(msg, compileTime);
	//auto writelnSink(string s, int line_number=0, int indent=0) {
	//	import std.array : replicate;
	//	import std.string : splitLines;
	//	if (s == "") return;
	//	if (indent > 0) {
	//		foreach (line; s.splitLines) {
	//			writeln(line_number, "| \t".replicate(indent), line);
	//		}
	//	} else {
	//		writeln(line_number, "| ", s);
	//	}
	//}
	//mixin(compileTime);
	//writeln("compileTime: %s", compileTime);
	writeln("find: ", compileTime[0].find("Jade.Extend"));
	static const extend = compileTime[0].find("Jade.Extend");
	static if (extend !is null) {
		mixin(`enum base = render!(extend.matches[0]);`);
		writeln("base: ", base[0].toString);
	}
	writeln(compileTime[0].toString);
	//foreach (item; compileTime) {
	//	writeln(item.toString);
	//}
	//writeln("runtime:");
	//render(stdout, filename);
}
