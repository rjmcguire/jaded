module jade.base;

import std.stdio;
import std.file;
import std.array : replicate;

import jade.pegged;

import std.conv : to;

string render(alias filename)() {
	pragma(msg, "compile time:");
	enum templ = import(filename);
	enum tmp = blockWrapJadeFile(templ);
	//return tmp;
	enum parse_tree = Jade(tmp);
	//pragma(msg, parse_tree);
	enum result = renderParseTree(filename, parse_tree); // Should we use a different readParseTree function here? This is the last place I currently use enum...
	return result;
}

void render(T)(T output_stream, string filename) {
	auto templ = readText("views/"~filename);
	auto tmp = blockWrapJadeFile(templ);
	auto parse_tree = Jade(tmp);
	auto result = renderParseTree(filename, parse_tree);
	//auto result = "%s".format(parse_tree);
	output_stream.write(result);
}

import pegged.parser;
import std.string : format;
string renderParseTree(string filename, ParseTree p) {
	auto parser = new JadeParser(filename, p);
	return parser.render().data;
}

struct JadeParser {
	import std.array : Appender, appender;
	string filename;
	ParseTree root;
	ParseTree* parent; // the parent of the current children being processed

	int last_indent, indent;
	size_t line_number;
	bool in_block;
	size_t block_indent;
	size_t skip; // the number of lines to skip in main loop
	int currentChild; // the current child index into parent.children;
	string[] parents;
	auto render() {
		auto output = appender!string;
		output ~= "sink(`";
		renderToken(output, root);
		printClosingTags(output);
		output ~= "`, %s);".format(line_number);
		return output;
	}

	auto printClosingTags(ref Appender!string html, int diff=-1, string file=__FILE__, int line=__LINE__) {
		if (parents.length <=0) return html;

		if (diff<0) {
			diff = cast(int)(last_indent - indent); // an equal indent is a un-indent of 1
		}
		if (diff == 0) {
			diff = 1;
		}
		assert(diff <= parents.length, "Too many indents: %s vs %s @%s:%d processing %s:%d\n%s".format(diff, parents.length, file, line, filename, line_number, parents));
		for (auto i=diff; i > 0; i--) {
			html ~= "`); sink(`</%s>`,%d, %d); sink(`".format(parents[$-1], line_number, indent-1);
			parents = parents[0..$-1];
		}
		return html;
	}
	void renderToken(ref Appender!string output, ref ParseTree p) {
		switch(p.name) {
			case "Jade.DocType":
				line_number++;
				output ~= "<!DOCTYPE %s>".format(p.matches[0]);
				break;
			case "Jade.Comment":
				line_number++;
				break;
			case "Jade.Line":
				renderLine(output, p);
				break;
			default:
				output ~= "==========\n";
				parent = &p;
				currentChild = -1;
				foreach (child; p.children) {
					currentChild++;
					if (skip) {
						skip--;
						continue;
					}
					//if (child.children.length > 0) {
					//	output ~= "-"~child.name~"-";
					//	output ~= renderParseTree(child);
					//} else {
						if (child.matches.length > 0) {


								indent = 0;
										bool decreased_indent, mustRecordIndent;
										//writefln("indents: %s and %s\t%s", p.matches.length > 0, p.matches[0][0]=='\t', p);
										if (child.matches.length > 0 && child.matches[0][0]=='\t') {
											foreach (t; child.matches[0]) { assert(t == '\t', "All indents must be tabs at line: %d\n".format(line_number, child)); }
											indent = to!int(child.matches[0].length);
											assert(indent <= last_indent+1, "Excessive indent at line: %d (%d vs %d)\n%s".format(line_number, indent, last_indent, child));
											decreased_indent = last_indent >= indent;
											//last_indent = indent;
											mustRecordIndent = true;
										} else {
											mustRecordIndent = false;
										}
										scope(exit) {
											if (mustRecordIndent) {
												last_indent = indent;
											}
											output ~= "\n";
											//writefln("Indents now: %s prev:%s", indent, last_indent);
										}

										if (decreased_indent) {
											//printClosingTags(output, cast(int)(indent - last_indent));
										}




							//output ~= "child: name:%s firstmatch:%s numChildren:%s numMatches:%s\n".format(child.name, child.matches[0], child.children.length, child.matches.length);
							renderToken(output, child);
						} else {
							output ~= "child: name:%s numChildren:%s numMatches:%s\n".format(child.name, child.children.length, child.matches.length);
						}
					//}
				}
				output ~= "\n";
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


	void renderLine(ref Appender!string output, ref ParseTree p) {
		import std.array : appender;
		line_number++;

		if (in_block && indent < block_indent) {
			in_block = false;
			block_indent = 0;
		}
		if (p.isIndentedLine) {
			// move to the actual content of the line;
			p = p.children[1];
		}
		if (!p.children.length) {
			output ~= "%s: %s// empty line%s".format(line_number, "\t".replicate(last_indent), p.matches[0]);
		} else {
			switch(p.children[0].name) {
				case "Jade.Include":
					output ~= "%d: %s".format(line_number, renderInclude(p, line_number, indent));
					break;
				case "Jade.Extend":
					output ~= "%d: %s".format(line_number, renderExtend(p, indent));
					break;
				case "Jade.Block":
					output ~= "%d: %s".format(line_number, renderBlock(p, indent));
					break;
				case "Jade.Conditional":
					output ~= "%d: %s".format(line_number, renderConditional(p, indent));
					break;
				case "Jade.UnbufferedCode":
					output ~= "%d: %s".format(line_number, renderUnbufferedCode(p, indent));
					break;
				case "Jade.BufferedCode":
					output ~= "%d: %s".format(line_number, renderBufferedCode(p, indent));
					break;
				case "Jade.Iteration":
					output ~= "%d: %s".format(line_number, renderIteration(p, indent));
					break;
				case "Jade.MixinDecl":
					output ~= "%d: %s".format(line_number, renderMixinDecl(p, indent));
					break;
				case "Jade.Mixin":
					output ~= "%d: %s".format(line_number, renderMixin(p, indent));
					break;
				case "Jade.Case":
					output ~= "%d: %s".format(line_number, renderCase(p, indent));
					break;
				case "Jade.Tag":
					auto tag = renderTag(p, indent);
					if (tag.id == "doctype") {
						assert(0, "doctype must be in first non-comment line of template");
					} else {
						output ~= "%d: %s%s%s".format(line_number, "\t".replicate(indent), tag.toHtml, tag.inlineText);
						parents ~= tag.id;
					}
					//output ~= "</%s>".format(tag.id);
					break;
				case "Jade.PipedText":
					output ~= "%d: %s".format(line_number, renderPipedText(p, indent));
					break;
				case "Jade.Comment":
					if (p.matches[1] == "-") {
						output ~= "%d: // code comment".format(line_number);
					} else {
						output ~= "%d: %s".format(line_number, renderComment(p, indent));
					}
					break;
				case "Jade.RawHtmlTag":
					output ~= "%d: %s".format(line_number, renderRawHtmlTag(p, indent));
					break;
				case "Jade.Filter":
					output ~= "%d: %s".format(line_number, renderFilter(p, indent));
					break;
				case "Jade.AnyContentLine":
					output ~= "%d: %s".format(line_number, renderAnyContentLine(p, indent));
					break;
				default:
					if (indent) {
						output ~= "%d: %s%s:%s".format(line_number, "\t".replicate(indent), p.children[0].name, p.matches[0]);
					} else {
						output ~= "%d: %s".format(line_number, p.matches[0]);
					}
			}
		}
	}

	string renderInclude(ParseTree p, ulong line_number, ulong indent) {
		//return "%sinclude %s// include file %s".format("\t".replicate(indent), p.matches[0], p.matches);
		auto s = q{`, %d, %d); sink(import("%s"), %d, %d); sink(`}.format(0, indent, p.matches[0], line_number, indent);
		//return import(p.matches[0]);
		//mixin(s);
		return s;
	}
	string renderExtend(ParseTree p, ulong indent) {
		//return "%s %s // Extend %s".format("\t".replicate(indent), p.matches[0], p.matches);
		return q{`, %d, %d); mixin(render!"%s"); sink(`}.format(0, indent, p.matches[1]);
	}
	string renderBlock(ParseTree p, ulong indent) {
		//return "%s %s // Block %s".format("\t".replicate(indent), p.matches[0], p.matches);
		return q{`); setBlock("%s", `}.format(p.matches[1]);
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
		string[] cssClasses;
		AndAttributes andAttributes;
		string inlineText;
		string toHtml() {
			import std.string : join;
			string[] attribs = [""];
			if (cssId.matches.length > 0) {
				attribs ~= `id="%s"`.format(cssId.matches[0]);
			}
			foreach (tagarg; tagArgs) {
				if (tagarg.key.matches[0] == "class") {
					return "CLASS %s".format(tagarg.value.matches);
				}
			}

			return "<%s%s>".format(id(), attribs.length <=1 ? "" : attribs.join(" "));
		}
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
					tag.cssClasses ~= item.matches[0];
					//s ~= "cssClass:"~ tag.cssClasses[$-1].matches[0];
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
					tag.inlineText = item.matches[0];
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
		alias args this;
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