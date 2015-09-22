module jade.base;

import std.stdio;
import std.file;

import jade.pegged;

string render(alias filename)() {
	pragma(msg, "compile time:");
	enum templ = import(filename);
	enum parse_tree = Jade(templ);
	//pragma(msg, parse_tree);
	enum result = renderParseTree(parse_tree);
	return result;
}

void render(T)(T output_stream, string filename) {
	auto templ = readText("views/"~filename);
	auto parse_tree = Jade(templ);
	//auto result = renderParseTree(parse_tree);
	auto result = "%s".format(parse_tree);
	output_stream.write(result);
}

import pegged.parser;
import std.string : format;
string renderParseTree(ParseTree p) {
	switch (p.children[0].name) {
		case "Jade.RootTag":
			return renderToken(p.children[0]);
		default:
			throw new Exception("Unknown PEG name:"~p.children[0].name);
	}
	//return "%s: %s %s %s".format(p.name, p.children.length, p.children[0].name, p.matches);
}

string renderToken(ParseTree p, string tagDepth="") {
	string childoutput = "==========\n";
	foreach (child; p.children) {
		//if (child.children.length > 0) {
		//	childoutput ~= "-"~child.name~"-";
		//	childoutput ~= renderParseTree(child);
		//} else {
			if (child.matches.length > 0) {
				childoutput ~= "%schild: name:%s firstmatch:%s numChildren:%s numMatches:%s\n".format(tagDepth, child.name, child.matches[0], child.children.length, child.matches.length);
				childoutput ~= renderToken(child, tagDepth~"\t");
			} else {
				childoutput ~= "%schild: name:%s numChildren:%s numMatches:%s\n".format(tagDepth, child.name, child.children.length, child.matches.length);
			}
		//}
	}
	return "%s\n".format(childoutput);
}