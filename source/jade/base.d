module jade.base;

import std.stdio;
import std.file;
import std.array : replicate;

import jade.pegged;


string render(alias filename)() {
	pragma(msg, "compile time:");
	enum templ = import(filename);
	enum tmp = blockWrapJadeFile(templ);
	//return tmp;
	enum parse_tree = Jade(tmp);
	//pragma(msg, parse_tree);
	enum result = renderParseTree(parse_tree);
	return result;
}

void render(T)(T output_stream, string filename) {
	auto templ = readText("views/"~filename);
	auto tmp = blockWrapJadeFile(templ);
	auto parse_tree = Jade(tmp);
	auto result = renderParseTree(parse_tree);
	//auto result = "%s".format(parse_tree);
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
	ParseTree* parent; // the parent of the current children being processed

	ulong last_indent;
	size_t line_number;
	bool in_block;
	size_t block_indent;
	size_t skip; // the number of lines to skip in main loop
	int currentChild; // the current child index into parent.children;
	string render() {
		return renderToken(root);
	}

	string renderToken(ref ParseTree p) {
		switch(p.name) {
			case "Jade.Line":
				return renderLine(p);
			default:
				string childoutput = "==========\n";
				parent = &p;
				currentChild = -1;
				foreach (child; p.children) {
					currentChild++;
					if (skip) {
						skip--;
						continue;
					}
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
	ParseTree* nextLine() {
		currentChild++;
		skip++;
		if (currentChild >= parent.children.length) {
			return null;
		}
		return &parent.children[currentChild];
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
		if (!p.children.length) return "%s: %s// empty line%s".format(line_number, "\t".replicate(last_indent), p.matches[0]);

		switch(p.children[0].name) {
			case "Jade.Include":
				return "%d: %s\n".format(line_number, renderInclude(p, indent));
			case "Jade.Extend":
				return "%d: %s\n".format(line_number, renderEntend(p, indent));
			case "Jade.Block":
				return "%d: %s\n".format(line_number, renderBlock(p, indent));
			case "Jade.Conditional":
				return "%d: %s\n".format(line_number, renderConditional(p, indent));
			case "Jade.UnbufferedCode":
				return "%d: %s\n".format(line_number, renderUnbufferedCode(p, indent));
			case "Jade.BufferedCode":
				return "%d: %s\n".format(line_number, renderBufferedCode(p, indent));
			case "Jade.Iteration":
				return "%d: %s\n".format(line_number, renderIteration(p, indent));
			case "Jade.MixinDecl":
				return "%d: %s\n".format(line_number, renderMixinDecl(p, indent));
			case "Jade.Mixin":
				return "%d: %s\n".format(line_number, renderMixin(p, indent));
			case "Jade.Case":
				return "%d: %s\n".format(line_number, renderCase(p, indent));
			case "Jade.Tag":
				import std.array : appender;
				auto tag = renderTag(p, indent);
				auto html = appender!string;
				html ~= "<%s%s>".format(tag.id, tag.tagArgs.toHtml);
				html ~= "</%s>".format(tag.id);
				return "%d: %s\n".format(line_number, html.data);
			case "Jade.PipedText":
				return "%d: %s\n".format(line_number, renderPipedText(p, indent));
			case "Jade.Comment":
				return "%d: %s\n".format(line_number, renderComment(p, indent));
			case "Jade.RawHtmlTag":
				return "%d: %s\n".format(line_number, renderRawHtmlTag(p, indent));
			case "Jade.Filter":
				return "%d: %s\n".format(line_number, renderFilter(p, indent));
			case "Jade.AnyContentLine":
				return "%d: %s\n".format(line_number, renderAnyContentLine(p, indent));
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
	string renderEntend(ParseTree p, ulong indent) {
		return "%s %s // Entend %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderBlock(ParseTree p, ulong indent) {
		return "%s %s // Block %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderConditional(ParseTree p, ulong indent) {
		return "%s %s // Conditional %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderUnbufferedCode(ParseTree p, ulong indent) {
		return "%s %s // UnbufferedCode %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderBufferedCode(ParseTree p, ulong indent) {
		return "%s%s".format(p.matches[0], p.matches[1]);
	}
	string renderIteration(ParseTree p, ulong indent) {
		return "%s %s // Iteration %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderMixinDecl(ParseTree p, ulong indent) {
		return "%s %s // MixinDecl %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderMixin(ParseTree p, ulong indent) {
		return "%s %s // Mixin %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderCase(ParseTree p, ulong indent) {
		return "%s %s // Case %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderTag(ParseTree p, ulong indent) {
		return "%s %s // Tag %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderPipedText(ParseTree p, ulong indent) {
		return "%s %s // PipedText %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderComment(ParseTree p, ulong indent) {
		return "%s %s // Comment %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderRawHtmlTag(ParseTree p, ulong indent) {
		return "%s %s // RawHtmlTag %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderFilter(ParseTree p, ulong indent) {
		return "%s %s // Filter %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderAnyContentLine(ParseTree p, ulong indent) {
		return "%s %s // AnyContentLine %s".format("\t".replicate(indent), p.matches[0], p.matches);
	}
	string renderStringInterpolation(ParseTree p, ulong indent) {
		switch (p.matches[0]) {
			case "#{":
				return "escape:%s // EscapedStringInterpolation".format(p.matches[1..$]);
			case "#[":
				return "tag:%s // TagInterpolation".format(renderTag(p.children[0], indent));
			case "!{":
				return "no-escape:%s // UnescapedStringInterpolation".format(p.matches[1..$]);
			default:
				assert(0, "Unrecognized StringInterpolation");
		}
	}
	struct Tag {
		ulong indent;
		bool hasBlock;
		string _id;// = findParseTree(line, "Jade.Id", 2);
		void id(string id) { _id = id; }
		string id() { if (_id) return _id; return "div"; }
		ParseTree blockInATag;
		TagArgs tagArgs;
		ParseTree cssId;
		ParseTree[] cssClasses;
		AndAttributes andAttributes;
	}
	Tag renderTag(ref ParseTree line, ulong indent) {
		Tag tag;
		tag.indent = indent;
		tag.hasBlock = findParseTree(line, "Jade.BlockInATag") !is null;
		string[] s;
		auto childHolder = line.children[0];
		if (line.name == "Jade.InlineTag" || line.name == "Jade.TagInterpolate") {
			childHolder = line;
		}
		foreach (item; childHolder.children) {
			switch (item.name) {
				case "Jade.Id":
					tag.id = item.matches[0];
					s ~= "id:"~ tag.id;
					break;
				case "Jade.BlockInATag":
					tag.blockInATag = item;
					s ~= "block:"~ tag.blockInATag.name;
					break;
				case "Jade.CssClass":
					tag.cssClasses ~= item;
					s ~= "cssClass:"~ tag.cssClasses[$-1].matches[0];
					break;
				case "Jade.CssId":
					tag.cssId = item;
					s ~= "cssId:"~ tag.cssId.matches[0];
					break;
				case "Jade.TagArgs":
					tag.tagArgs = TagArgs.parse(item);
					s ~= "tagArgs:%s".format(tag.tagArgs);
					break;
				case "Jade.BufferedCode":
					s ~= "bufferedCode:%s".format(renderBufferedCode(item, indent));
					break;
				case "Jade.InlineText":
					s ~= "inlineText:%s".format(item.matches[0]);
					assert(item.matches.length == 1, "Surely inlineText should only have one match?");
					break;
				case "Jade.InlineTag":
					s ~= "inlineTag:%s".format(renderTag(item, indent));
					break;
				case "Jade.SelfCloser":
					s ~= "selfcloser:true"; // we could put the automatica selfcloser for img, br, etc... by the Jade.Id detection above
					break;
				case "Jade.AndAttributes":
					tag.andAttributes = AndAttributes.parse(item);
					s ~= "andAttributes:%s".format(tag.andAttributes);
					break;
				case "Jade.StringInterpolation":
					s ~= "stringInterpolation:%s".format(renderStringInterpolation(item, indent));
					break;
				default:
					//id = &item;
					s ~= "default:"~item.name;
			}
		}
		//return "%s:%s %s %s".format(hasBlock?"hasBlock":"", indent, id is null ? "(null)" : "id:[%s]".format(*id), line.matches.length);
		return tag;
	}
	struct AndAttributes {
		string dexpression;
		AndAttribute[] attribs;
		static AndAttributes parse(ref ParseTree p) {
			AndAttributes ret;
			if (p.children[0].name == "Jade.ParamDExpression") {
				ret.dexpression = p.children[0].matches[0];
			} else {
				assert(p.children[0].name == "Jade.AttributeJsonObject", "Expected Jade.AttributeJsonObject got:%s".format(p.children[0].name));
				foreach (argtree; p.children[0].children) {
					ret.attribs ~= AndAttribute.parse(argtree);
				}
			}
			return ret;
		}
		string toString() {
			import std.array : appender;
			auto ret = appender!string;
			if (attribs.length > 0) {
				ret.reserve = 4096;
				ret ~= attribs[0].toString;
				foreach (attrib; attribs[1..$]) {
					ret ~= ", ";
					ret ~= attrib.toString;
				}
			} else {
				return dexpression;
			}

			return ret.data;
		}
	}
	struct AndAttribute {
		ParseTree* key;
		ParseTree* value;
		static AndAttribute parse(ref ParseTree p) {
			AndAttribute ret;
			ret.key = &p.children[0];
			ret.value = &p.children[1];
			return ret;
		}
		string toString() {
			return "%s:%s".format(key.matches[0], value.matches[0]);
		}
	}
	struct TagArgs {
		TagArg[] args;
		static TagArgs parse(ref ParseTree p) {
			TagArgs ret;
			foreach (argtree; p.children) {
				ret.args ~= TagArg.parse(argtree);
			}
			return ret;
		}
		string toString() {
			import std.array : appender;
			auto ret = appender!string;
			if (args.length > 0) {
				ret.reserve = 4096;
				ret ~= args[0].toString;
				foreach (arg; args[1..$]) {
					ret ~= ", ";
					ret ~= arg.toString;
				}
			}
			return ret.data;
		}
		string toHtml() {
			import std.array : appender;
			auto ret = appender!string;
			if (args.length > 0) {
				ret.reserve = 1024;
				foreach (arg; args) {
					ret ~= " ";
					ret ~= arg.toHtml;
				}
			}
			return ret.data;
		}
	}
	struct TagArg {
		ParseTree* key;
		string assignType;
		ParseTree* value;
		static TagArg parse(ref ParseTree p) {
			TagArg ret;
			ret.key = &p.children[0];
			if (p.children.length > 1) {
				ret.assignType = p.children[1].matches[0];
			}
			if (p.children.length > 2) {
				ret.value = &p.children[2];
			}
			return ret;
		}
		string getValue() {
			import std.array : appender;
			auto ret = appender!string;
			auto type = value is null ? "<null>" : value.children[0].name;
			ret.reserve = 1024;
			switch (type) {
			case "Jade.Str":
				ret ~= '"';
				ret ~= value.matches[0];
				ret ~= '"';
				return ret.data;
			case "Jade.ParamDExpression":
				return value.matches[0];
			case "Jade.AttributeJsonObject":
				assert(key.matches[0] == "style" || key.matches[0] == "class", "AttributeJsonObject as parameter only supported for style tag parameter, not: "~ key.matches[0]);
				if (value.children[0].children.length > 0) {
					ret ~= value.children[0].children[0].children[0].matches[0];
					ret ~= '=';
					ret ~= value.children[0].children[0].children[0].matches[0];
					foreach (keyvalue; value.children[0].children[1..$]) {
						ret ~= ",";
						ret ~= keyvalue.children[0].matches[0];
						ret ~= '=';
						ret ~= keyvalue.children[0].matches[0];
					}
				}
				return ret.data;
			case "Jade.CssClassArray":
				if (value.children[0].children.length > 0) {
					ret ~= value.children[0].children[0].matches[0];
					foreach (clazz; value.children[0].children[1..$]) {
						ret ~= ",";
						ret ~= clazz.matches[0];
					}
				}
				return ret.data;
			case "<null>":
				return `""`;
			default:
				assert(0, "Unsupported value type: "~ type ~" for TagArg key:"~ key.matches[0]);
			}
		}

		string toString() {
			return "%s%s%s".format(key.matches[0], assignType, value is null ? null : value.matches[0]);
		}
		string toHtml() {
			return "%s%s%s".format(key.matches[0], assignType, getValue());
		}
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

ParseTree* findParseTree(ref ParseTree p, string name, int maxDepth=int.min) {
	if (maxDepth != int.min && maxDepth < 0) return null;
	if (p.name == name) {
		return &p;
	}
	foreach (child; p.children) {
		auto tmp = findParseTree(child, name, maxDepth-1);
		if (tmp !is null) {
			return tmp;
		}
	}
	return null;
}





/**
 * Pre-process jade file, making pegged parser capable of understanding indented BlockInATag blocks
 */
string blockWrapJadeFile(string templ) {
	import std.conv;
	import std.algorithm : countUntil;
	import std.array;
	import std.string : split, strip, lineSplitter;
	auto buf = appender!string;
	buf.reserve(templ.length*2);

	long last_indent;
	long raw_indent;
	bool isRawBlock;
	foreach (line; templ.lineSplitter) {
		if (line == "}") throw new Exception("Unexpected } on line by itself"); // protect against accidental use of our special marker
		auto indent = line.countUntil!"a != 0x09";
		auto strippedLine = line.strip;
		indent = indent < 0 ? 0 : indent;

		//buf ~= to!string(indent);
		if (line.length>0 && strippedLine[$-1]=='.' && indent <= raw_indent) {
			if (isRawBlock) buf ~= "}\n"; // if a raw block tag follows a raw block tag

			buf ~= line;
			buf ~= '{';
			isRawBlock = true;
			raw_indent = indent;
		} else if (isRawBlock && indent <= raw_indent) {
			buf ~= "}\n";
			isRawBlock = false;
			buf ~= line;
		} else {
			buf ~= line;
		}
		buf ~= '\n';
		last_indent = indent;
	}

	return buf.data;
}