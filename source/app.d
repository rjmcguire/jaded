import std.stdio;

import jade;

void main() {
	pragma(msg, render!"base_page");
	writeln("runtime:");
	render(stdout, "base_page");
}
