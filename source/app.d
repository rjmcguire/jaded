import std.stdio;

import jade;

void main() {
	pragma(msg, render!"base_page.jade");
	writeln("runtime:");
	render(stdout, "base_page.jade");
}
