module jade.base;

import std.stdio;
import std.file;
import std.array : replicate;

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
	auto parser = new JadeParser(p);

	return parser.render();
}

struct JadeParser {
	ParseTree root;

	ulong last_indent;
	size_t line_number;
	bool in_block;
	size_t block_indent;
	string render() {
		return renderToken(root);
	}
	string renderToken(ref ParseTree p) {
		switch(p.name) {
			case "Jade.Line":
				return renderLine(p);
			default:
				string childoutput = "==========\n";
				foreach (child; p.children) {
					//if (child.children.length > 0) {
					//	childoutput ~= "-"~child.name~"-";
					//	childoutput ~= renderParseTree(child);
					//} else {
						if (child.matches.length > 0) {
							//childoutput ~= "child: name:%s firstmatch:%s numChildren:%s numMatches:%s\n".format(child.name, child.matches[0], child.children.length, child.matches.length);
							childoutput ~= renderToken(child);
						} else {
							childoutput ~= "child: name:%s numChildren:%s numMatches:%s\n".format(child.name, child.children.length, child.matches.length);
						}
					//}
				}
				return "%s\n".format(childoutput);
		}
	}


	string renderLine(ref ParseTree p) {
		line_number++;

		ulong indent = 0;
		bool indent_changed, decreased_indent;
		if (p.matches.length > 0 && p.children.length > 0 && p.matches[0][0]=='\t') {
			foreach (t; p.matches[0]) { assert(t == '\t', "All indents must be tabs at line: %d\n".format(line_number, p)); }
			indent = p.matches[0].length;
			assert(indent <= last_indent+1, "Excessive indent at line: %d (%d vs %d)\n%s".format(line_number, indent, last_indent, p));
			last_indent = indent;
		}
		if (in_block && indent < block_indent) {
			in_block = false;
			block_indent = 0;
		}
		if (p.isIndentedLine) {
			// move to the actual content of the line;
			p = p.children[1];
		}
		if (!p.children) return "%s: %s// empty line%s".format(line_number, "\t".replicate(last_indent), p.matches[0]);

		switch(p.children[0].name) {
			case "Jade.Include":
				return "%d: %s\n".format(line_number, renderInclude(p, indent));
			case "Jade.Comment":
				return "%d: %s\n".format(line_number, renderComment(p, indent));
			case "Jade.Tag":
				return "%d: %s\n".format(line_number, renderTag(p, indent));
			default:
				if (indent) {
					return "%d: %s%s:%s\n".format(line_number, "\t".replicate(indent), p.children[0].name, p.matches[0]);
				} else {
					return "%d: %s\n".format(line_number, p.matches[0]);
				}
		}
	}

	string renderInclude(ParseTree p, ulong indent) {
		return "%sinclude %s// include file %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderComment(ParseTree p, ulong indent) {
		return "%scomment %s".format("\t".replicate(indent), p.matches[0]);
	}
	string renderTag(ref ParseTree line, ulong indent) {
		import std.conv;
		if (findParseTree(line, "Jade.BlockInATag")) {
			in_block = true;
			block_indent = indent+1;
		}
		return "%s:%s %s".format(in_block?"in_block":"", indent, line);
	}
}

bool isIndentedLine(ParseTree p) {
	if (p.children.length < 1 || p.name != "Jade.Line" || p.children[0].name != "Jade.Indent" || p.children[1].name != "Jade.Line") {
		return false;
	}
	if (p.matches.length > 0 && p.children.length > 0 && p.matches[0][0]=='\t') {
		return true;
	}
	return false;
}

ParseTree* findParseTree(ref ParseTree p, string name) {
	if (p.name == name) {
		return &p;
	}
	foreach (child; p.children) {
		auto tmp = findParseTree(child, name);
		if (tmp !is null) {
			return tmp;
		}
	}
	return null;
}
