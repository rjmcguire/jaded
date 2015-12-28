import std.stdio;

import jade;

void main(string[] args) {
	auto filename = "base_layout.jade";
	if (args.length > 1) {
		filename = args[1];
	}
	enum compileTime = render!"base_layout.jade";
	pragma(msg, compileTime);
	auto setBlock(string name, string value, int line_number=0, int indent=0) {
		writeln("Block name set ", name, " to ", value);
	}
	auto sink(string s, int line_number=0, int indent=0) {
		import std.array : replicate;
		import std.string : splitLines;
		if (s == "") return;
		if (indent > 0) {
			foreach (line; s.splitLines) {
				writeln(line_number, "| \t".replicate(indent), line);
			}
		} else {
			writeln(line_number, "| ", s);
		}
	}
	mixin(compileTime);
	writeln("runtime:");
	render(stdout, filename);
}
