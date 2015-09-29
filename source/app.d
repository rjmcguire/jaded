import std.stdio;

import jade;

void main(string[] args) {
	auto filename = "base_page.jade";
	if (args.length > 1) {
		filename = args[1];
	}
	pragma(msg, render!"base_page.jade");
	writeln("runtime:");
	render(stdout, filename);
}
