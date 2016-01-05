module jade.base;

import std.stdio;
import std.file;
import std.array : replicate;

import jade.pegged;

import std.conv : to;
import std.uni : asCapitalized;

string renderToString(alias filename)() {
	return render!filename.toString;
}
JadeParser.Item[] render(alias filename)() {
	enum templ = import(filename);
	enum tmp = blockWrapJadeFile(templ);
	pragma(msg, "===============================================================================");
	//return tmp;
	enum parse_tree = Jade(tmp);
	//enum tmp2 = jadeToTree(parse_tree);
	//printParseTree(tmp2);
	enum tree = renderParseTree(filename, parse_tree); // Should we use a different readParseTree function here? This is the last place I currently use enum...
	//writeln("find: ", tree[0].find("Jade.Extend"));
	static const extend = tree[0].find("Jade.Extend");
	JadeParser.Item[] ret;
	static if (extend !is null) {
		pragma(msg, "extended");
		mixin(`enum base = render!(extend.matches[0]);`);
		ret ~= base;
		//ret ~= base[0].toString;
	} else {
		pragma(msg, "not extended");
	}
	//ret ~= tree[0].toString;
	ret ~= tree[0];
	return ret;
}

JadeParser.Item[] render(string filename) {
	auto templ = readText("views/"~filename);
	auto tmp = blockWrapJadeFile(templ);
	//writeln("blockWrapJadeFile output:\n", tmp);
	auto parse_tree = Jade(tmp);
	//writeln("tree\n", parse_tree);
	auto tree = renderParseTree(filename, parse_tree);
	auto extend = tree[0].find("Jade.Extend");
	JadeParser.Item[] ret;
	if (extend !is null) {
		writeln("extended");
		auto base = render(extend.matches[0]);
		ret ~= base;
	} else {
		writeln("not extended");
	}
	ret ~= tree[0];
	//////auto result = "%s".format(parse_tree);
	return ret;
}

import pegged.parser;
import std.string : format, splitLines, stripLeft;
auto renderParseTree(string filename, ParseTree p) {
	auto parser = new JadeParser(filename, p);
	return parser.render();
}

import std.array;
struct JadeParser {
	string name;
	this(string filename, ParseTree p) {
		import std.string : indexOf;
		this.name = filename[0..filename.indexOf(".")];
		//writeln(this);
		this.ranges ~= LineRange(p.children, 0);
	}
	LineRange[] ranges;
	LineRange range() {
		return ranges[$-1];
	}
	/**
	 * Item is responsible for block substitution and output
	 */
	class Item {
		int depth;
		ParseTree p;
		string[] code_prolog, code_epilog;
		string[] prolog, epilog;
		Item[] items;
		alias p this;
		this(int depth, ParseTree p) {
			this.depth = depth;
			this.p = p;
		}
		//override
		//string toString() {
		//	auto ret = appender!string;
		//	//ret ~= "\nwriteln(`%s<!-- %s:%s -->`);\n".format("\t".replicate(depth), p.name, p.matches.length > 0 ? p.matches[0] : "");
		//	ret ~= "\n%s<!-- %s:%s -->\n".format("\t".replicate(depth), p.name, p.matches.length > 3 ? p.matches[0..3] : p.matches[0..$]);
		//	//return "%s".format(p.name);
		//	ret ~= code_prolog.join("\n");
		//	ret ~= "\nbuf ~= `";
		//	ret ~= prolog.join("`);\nbuf ~= `");
		//	foreach (item; items) {
		//		if (item.name == "Jade.PipedText") {
		//			ret ~= "\nwriteln(`%s`);".format(item.matches[0]);
		//		} else {
		//			ret ~= item.toString();
		//		}
		//	}
		//	ret ~= epilog.join("`);buf ~= `");
		//	ret ~= "`);";
		//	ret ~= code_epilog.join("\n");
		//	return ret.data;
		//}
		string getOutput(Item[] blockTemplates, Item rootItem=null) {
			if (rootItem is null) {
				rootItem = this;
			}
			auto ret = appender!string;
			if (p.name == "Jade.MixinDecl") {
				/// I wonder if it would be interesting to output these mixin declarations as AngularJS templates so they are available in browser using <script id="mixinName">The MixinDecl's items</script>
				//ret ~= "%s CHILDCOUNT:%s".format(p, items.length);
				// TODO: must render else block if there is no items for "if block"
				//auto conditionalBlock = this.findByMatch("Jade.Conditional", 1, "block");
				//if (conditionalBlock !is null) {
				//	if (conditionalBlock.matches[0] == "if") {
				//		if (conditionalBlock.items.length <= 0 || (conditionalBlock.items[0].name=="Jade.Tag" && conditionalBlock.items[0].matches[0]=="block")) {
				//			//conditionalBlock.prolog ~= "";
				//			//conditionalBlock.epilog ~= "";
				//			//conditionalBlock.items = [];
				//		} else {
				//			auto elseBlock = this.findByMatch("Jade.Conditional", 0, "else");
				//			//elseBlock.prolog ~= "";
				//			//elseBlock.epilog ~= "";
				//			//elseBlock.items = [];
				//		}
				//	}
				//}
				return "";
			}
			if (p.name == "Jade.Mixin") {
				auto mixinDecl = rootItem.findByMatch("Jade.MixinDecl", 0, p.matches[0]);
				if (mixinDecl is null) { throw new Exception("Mixin does not exist"); }

				//mixinDecl = mixinDecl.dup;
				auto conditionalBlock = mixinDecl.findByMatch("Jade.Conditional", 1, "block");
				Item blockToReplace;
				if (conditionalBlock !is null) {
					if (conditionalBlock.matches[0] != "if") {
						conditionalBlock = null;
					} else {
						blockToReplace = conditionalBlock;
					}
				}
				if (!blockToReplace) {
					blockToReplace = mixinDecl.findByMatch("Jade.Tag", 0, "block");
				}
				//ret ~= "%s MixinCHILDCOUNT:%s, BlockReplace:%s".format(p, items.length, mixinDecl);
				if (items.length > 0 && !blockToReplace) {
					throw new Exception("warning: block supplied to mixin that has no block");
				}
				if (blockToReplace !is null) {
					ret ~= "|||BTR:%s|||".format(blockToReplace.matches);
					blockToReplace.items = this.items;
					ret ~= mixinDecl.getOutput(blockTemplates);
				}
				return ret.data;
			}
			//ret ~= "\n%s/+ <!-- %s:%s -->+/".format("\t".replicate(depth), p.name, p.matches.length > 3 ? p.matches[0..3] : p.matches[0..$]);
			if (code_prolog) {
				ret ~= "\n";
				ret ~= code_prolog.join("\n");
			}
			if (prolog) {
				ret ~= "\nbuf ~= `";
				ret ~= prolog.join("`);\nbuf ~= `");
				ret ~= "`;";
			}
			if (p.name == "Jade.Block") { // This is how we do template inheritance with extends
				foreach (item; blockTemplates) {
					foreach (b; item.findAll("Jade.Block")) {
						if (b.matches[0] == p.matches[0]) { // Do the block names match?
							return b.getOutput(blockTemplates[1..$], rootItem);
						}
					}
				}
			}
			foreach(item; items) {
				ret ~= item.getOutput(blockTemplates, rootItem);
			}
			if (epilog) {
				ret ~= "\nbuf ~= `";
				ret ~= epilog.join("`;\nbuf ~= `");
				ret ~= "`;";
			}
			ret ~= code_epilog.join("\n");
			return ret.data;
		}

		Item find(string name) {
			foreach (item; items) {
				if (item.name == name) {
					return item;
				}
				auto innerItem = item.find(name);
				if (innerItem !is null) {
					return innerItem;
				}
			}
			return null;
		}
		Item findByMatch(string name, int matchIndex, string matchValue) {
			foreach (item; items) {
				if (item.name == name && item.matches.length > matchIndex && item.matches[matchIndex] == matchValue) {
					return item;
				}
				auto innerItem = item.findByMatch(name, matchIndex, matchValue);
				if (innerItem !is null) {
					return innerItem;
				}
			}
			return null;
		}
		Item[] findAll(string name) {
			Item[] ret;
			foreach (item; items) {
				if (item.name == name) {
					ret ~= item;
				}
				ret ~= item.findAll(name);
			}
			return ret;
		}
	}
	class LineRange {
	//struct LineRange {
		//@disable this();
		static LineRange opCall(ParseTree[] lines, int min_depth) {
			return new LineRange(lines, min_depth);
		}

		this(ParseTree[] lines, int min_depth) {
			this.lines = lines;
			this.index = 0;
			this.min_depth = min_depth;
			skip();
		}
		ParseTree[] lines;
		int min_depth;
		size_t index = 0;
		Item front() {
			ulong depth;
			if (lines[index].name == "Jade.Line" && lines[index].children.length > 0 && lines[index].children[0].name == "Jade.Indent" && lines[index].children[1].children.length > 0) {
				depth = lines[index].children[0].matches[0].length;
				return new Item(cast(int)depth, lines[index].children[1].children[0]);
			} else if (lines[index].name == "Jade.Line") {
				return new Item(cast(int)depth, lines[index].children.length > 0 ? lines[index].children[0] : lines[index]);
			} else {
				depth = 0;
				return new Item(cast(int)depth, lines[index]);
			}
			//return Line(cast(int)depth, lines[index]);
		}
		void popFront()
		in {
			assert(index <= lines.length);
		}
		body {
			// move forward, past all indented lines
			index++;
			skip();
		}
		bool empty() {
			return index >= lines.length || front.depth < min_depth;
		}
		private void skip() {
			while (!empty && lines[index].name == "Jade.Line" && lines[index].matches.length == 1 && lines[index].matches[0] == "\n") {
				index++;
			}
		}
	}
	/** Entry point for render*/
	auto render() {
		Item[] ret;
		//ret ~= "\nwriteln(`render:%s%s`);".format("\t".replicate(stop_depth+1), range.lines.length);
		//if (!range.empty)
		//	ret ~= "\nwriteln(`range empty? %s - %s vs %s vs %s - %s || %s -- %s`);".format(range.empty, range.front.depth, range.min_depth ? range.min_depth : stop_depth, range.index, range.index >= range.lines.length, range.front.depth < range.min_depth, range.lines.length > range.index ? range.front.name : "empty for real");
		while (!range.empty) {
			ret ~= renderTag(range.front);
			//auto item = renderTag(range.front);
			//ret ~= "%s".format(item);
		}
		return ret;
	}
	/** Used by renderTag for rendering recursively */
	private Item[] render(int stop_depth) {
		Item[] ret;
		//ret ~= "\nwriteln(`render:%s%s`);".format("\t".replicate(stop_depth+1), range.lines.length);
		//if (!range.empty)
		//	ret ~= "\nwriteln(`range empty? %s - %s vs %s vs %s - %s || %s -- %s`);".format(range.empty, range.front.depth, range.min_depth ? range.min_depth : stop_depth, range.index, range.index >= range.lines.length, range.front.depth < range.min_depth, range.lines.length > range.index ? range.front.name : "empty for real");
		while (!range.empty) {
		//ret ~= "\nwriteln(`\t empty? %s - %s vs %s vs %s - %s || %s -- %s`);".format(range.empty, range.front.depth, range.min_depth ? range.min_depth : stop_depth, range.index, range.index >= range.lines.length, range.front.depth < range.min_depth, range.lines.length > range.index ? range.front.name : "empty for real");
			if (stop_depth >= 0 && range.front.depth <= stop_depth) break;
			//ret ~= "\nwriteln(`range not empty`);";
			ret ~= renderTag(range.front);
		}
		return ret;
	}
	private Item renderTag(Item token) {
		switch (token.name) {
			case "Jade.RootTag":
				token.code_prolog ~= "/** jade template: %s.jade %s */".format(name, token.children.length);
				token.code_prolog ~= "import std.array : appender;\nauto buf = appender!string;";
				ranges ~= LineRange(token.children, token.depth);
				//token.prolog ~= render();
				token.items ~= render();
				ranges.popBack();
				range.popFront();
				break;
			case "Jade.Extend":
				//token.prolog ~= "\nclass %s {".format(name);
				//token.prolog ~= "pragma(msg, render!`%s`); auto %s = render!`%s`; writeln(extendbase_is);".format(token.matches[1], "extendbase_is", token.matches[1]);
				//token.epilog ~= "\n}";
				//token.prolog ~= "pragma(msg, render!`%s`); mixin(render!`%s`);".format(token.matches[1], token.matches[1]);
				range.popFront();
				break;
			case "Jade.Include":
				token.code_prolog ~= "buf ~= import(`%s`);".format(token.matches[0]);
				range.popFront();
				break;
			case "Jade.Block":
				//token.prolog ~= "\nwriteln(`<block>`);";
				//token.prolog ~= "\nwriteln(`<!-- %s %s depth:%s -->` \"\n\" `block`);".format(ranges.length, token.name, token.depth);
				range.popFront();
				token.items = render(token.depth);
				//token.epilog ~= "\nwriteln(`</block>`);";
				break;
			case "Jade.Tag":
				//writeln("tag popfront", range.front);
				range.popFront();
				//writeln("tag 2popfront2", range.front);
				auto hasChildren = !range.empty && range.front.depth > token.depth;
				auto tag = Tag.parse(token, hasChildren);
				tag.appendProlog(token.prolog);
				if (hasChildren) {
					token.items ~= render(token.depth);
				}
				tag.appendEpilog(token.epilog);
				//auto name = token.matches[0];
				//if (name==".") {
				//	name = "div";
				//}
				//if (!hasChildren) {
				//	if (name=="img") {
				//		token.prolog ~= "\nwriteln(`%s<%s />`);".format("\t".replicate(token.depth), name);
				//	} else {
				//		token.prolog ~= "\nwriteln(`%s<%s></%s>`);".format("\t".replicate(token.depth), name, name);
				//	}
				//} else {
				//	assert(name != "img", "<img /> tag cannot have children");
				//	token.prolog ~= "\nwriteln(`%s<%s>`);".format("\t".replicate(token.depth), name);
				//	//token.prolog ~= "\nwriteln(`<!-- %s %s depth:%s -->` `tag:%s`);".format(ranges.length, token.name, token.depth, token.matches[0]);
				//	token.items = render(token.depth);
				//	token.epilog ~= "\nwriteln(`%s</%s>`);".format("\t".replicate(token.depth), name);
				//	token.epilog ~= tag.epilog;
				//}
				break;
			case "Jade.PipedText":
				//token.prolog ~= "\nwriteln(`<!-- %s %s depth:%s -->` `PipedText:%s`);".format(ranges.length, token.name, token.depth, token.matches);
				//token.prolog ~= "\n%s".format(token.matches[0]);
				auto tag = Tag.parse(token, false);
				tag.appendProlog(token.prolog);
				tag.appendEpilog(token.epilog);
				//foreach (child; token.children) {
				//	if (child.name == "Jade.InlineText") {
				//		token.prolog ~= child.matches[0];
				//	} else if (child.name == "Jade.StringInterpolation") {
				//		auto tag = Tag.parse(new Item(token.depth+1, child), false); // Tag Interpolation does not allow tags containing tags.
				//		token.prolog ~= tag.prolog;
				//		token.prolog ~= tag.epilog;
				//	}
				//}
				range.popFront();
				break;
			case "Jade.UnbufferedCode":
				import std.string : endsWith;
				if (!token.matches[1].endsWith(";")) {
					throw new Exception("UnbufferedCode must end with a ';' at: %s".format(token.matches[1]));
				}
				token.code_prolog ~= "%s".format(token.matches[1]);
				range.popFront();
				break;
			case "Jade.RawHtmlTag":
				token.prolog ~= "%s%s".format("\t".replicate(token.depth), token.matches[0]);
				range.popFront();
				break;
			case "Jade.Comment":
				if (token.matches[0] == "//") {
					token.prolog ~= "%s<!-- %s ".format("\t".replicate(token.depth), token.matches.length > 2 ? token.matches[2] : token.matches[1]);
					token.epilog ~= "-->";
				}
				range.popFront();
				break;
			case "Jade.MixinDecl":
				auto mixinDeclArgs = token.findParseTree("Jade.MixinDeclArgs");
				string[] templateArgNames;
				string[] argNames;
				if (mixinDeclArgs !is null) {
					foreach (arg; mixinDeclArgs.children) {
						if (arg.name != "Jade.DVariableName") continue;
						auto name = to!string(arg.matches[0].asCapitalized);
						templateArgNames ~= name;
						name ~= " ";
						name ~= arg.matches[0];
						argNames ~= name;
					}
				}
				auto mixinVarArg = token.findParseTree("Jade.MixinVarArg");
				if (mixinVarArg) {
					auto name = to!string(mixinVarArg.matches[0].asCapitalized);
					templateArgNames ~= name ~ "...";
					name ~= " ";
					name ~= mixinVarArg.matches[0];
					argNames ~= name;
				}

				//token.prolog ~= "\nvoid JadeMixin_%s(Attributes, %s)(Attributes attributes, %s) {\n\t".format(token.matches[0], templateArgNames.join(", "), argNames.join(", "));
				range.popFront();
				token.items ~= render(token.depth);
				token.epilog ~= "\n}";
				break;
			case "Jade.Mixin":
				auto mixinArgs = token.findParseTree("Jade.MixinArgs");
				string[] args;
				if (mixinArgs !is null) {
					foreach (arg; mixinArgs.children) {
						args ~= arg.matches[0];
					}
				}
				auto attributestoken = token.findParseTree("Jade.TagArgs");
				string attributesString;
				if (attributestoken !is null) {
					auto tagargs = TagArgs.parse(*attributestoken);
					attributesString ~= tagargs.toJson;
				} else {
					attributesString ~= "{}";
				}
				range.popFront();
				token.items = render(token.depth);
				//token.prolog ~= "string block;";
				//foreach (item; token.items) {
				//	token.prolog ~= "\nblock ~= `%s`;".format(item.getOutput([]));
				//}
				//token.items = []; // remove all children, we've processed them.
				//token.prolog ~= "%s\nJadeMixin_%s(%s, %s, block);".format(token.p, token.matches[0], attributesString, args.join(", "));
				break;
			case "Jade.Conditional":
				switch (token.matches[0]) {
					case "if":
						token.code_prolog ~= "if ("~ token.matches[1] ~") {";
						token.code_epilog ~= "\n}";
						break;
					case "else":
						if (token.matches.length > 1 && token.matches[1] == "if") {
							token.code_prolog ~= " else if ("~ token.matches[2] ~") {";
							token.code_epilog ~= "\n}";
						} else {
							token.code_prolog ~= " else {";
							token.code_epilog ~= "\n}";
						}
						break;
					case "unless":
						token.code_prolog ~= "if (!("~ token.matches[1] ~")) {";
						token.code_epilog ~= "\n}";
						break;
					default:
						assert(0, "Unknown conditional");
				}
				range.popFront();
				token.items = render(token.depth);
				break;
			case "Jade.Line":
			default:
				token.prolog ~= "writeln(`<!-- %s %s depth:%s -->`);".format(ranges.length, token.name, token.depth);
				range.popFront();
		}
		return token;
	}
	struct AndAttribute {
		ParseTree key;
		ParseTree value;
		static AndAttribute parse(ParseTree p) {
			AndAttribute ret;

			return ret;
		}
	}
	struct AndAttributes {
		AndAttribute[] attributes;
		static AndAttributes parse(ParseTree p) {
			AndAttributes ret;

			return ret;
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
						//return `""`;
						return ``;
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
		string toJson() {
			return toHtml();
		}
	}

	struct TagArgs {
		string str;
		TagArg[] args;
		static TagArgs parse(ref ParseTree token) {
			TagArgs ret;
			with (ret) {
			str ~= "%s".format(token);
				foreach (argtree; token.children) {
					ret.args ~= TagArg.parse(argtree);
				}
			}
			return ret;
		}
		string toHtml() {
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
		string toJson() {
			string[] ret;
			if (args.length > 0) {
				foreach (arg; args) {
					ret ~= arg.toJson;
				}
			}
			return "{"~ ret.join(",") ~"}";
		}
	}

	struct Tag {
		string str;
		void appendProlog(ref string[] prolog) {
			if (name == "|") {
				if (str) str ~= "|";

				prolog ~= "%s%s".format(str, inlineText);
				return;
			}
			string classString;
			if (cssClasses.length > 0) {
				classString ~= ` class="`;
				classString ~= cssClasses.join(" ");
				classString ~= `"`;
			}
			string attribs;
			if (cssId.matches) {
				attribs ~= " id=\"%s\"".format(cssId.matches[0]);
			}
			attribs ~= tagArgs.toHtml;

			if (hasRawBlock) {
				auto tmp = appender!string;
				auto keepLines = this.name == "pre" || this.name == "script" || this.name == "style";
				if (keepLines) tmp ~= "\n";
				auto keep = keepLines ? KeepTerminator.yes : KeepTerminator.no;
				foreach (line; blockInATag.matches[0].splitLines(keep)) { // should replace tabs first to be same as jade because jade seems to do that
					tmp ~= keep ? line : line.stripLeft;
				}
				if (keepLines) tmp ~= "\n";
				inlineText = tmp.data;

			}

			if (str.length>0) str = "|"~ str ~"|";
			if (!hasChildren) {
				prolog ~= "<%s%s%s>%s%s</%s>".format(name, classString, attribs, str, inlineText, name);
				return;
			}
			prolog ~= "<%s%s%s>%s%s".format(name, classString, attribs, str, inlineText);
		}
		void appendEpilog(ref string[] epilog) {
			if (hasChildren && name != "|") {
				epilog ~= "</%s>".format(name);
			}
		}
		string name;
		bool hasChildren;

		ParseTree cssId;
		ParseTree blockInATag;
		bool hasRawBlock;
		string[] cssClasses;
		TagArgs tagArgs;
		string inlineText;
		int indent;
		AndAttributes andAttributes;

		static Tag parse(Item token, bool has_children) {
			Tag tag;
			with (tag) {
				name = token.matches[0] == "." ? name = "div" : token.matches[0];

				indent = token.depth;
				tag.hasChildren = has_children;



				tag.hasRawBlock = findParseTree(token, "Jade.BlockInATag") !is null;
				string[] s;
				//str ~= "%s".format(token.p);
				auto childHolder = token;
				//auto childHolder = token.children[0];
				//if (token.name == "Jade.InlineTag" || token.name == "Jade.TagInterpolate") {
				//		childHolder = token;
				//}
				foreach (item; childHolder.children) {
					//tag.str ~= item.name;
						switch (item.name) {
								case "Jade.Id":
										assert(item.matches[0] == name);
										//tag.id = item.matches[0];
										//s ~= "id:"~ tag.id;
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
										//s ~= "bufferedCode:%s".format(renderBufferedCode(item, indent));
										break;
								case `Jade.TextStop!(literal!("]"))`:
									goto case;
								case "Jade.InlineText":
										tag.inlineText ~= item.matches[0];
										//s ~= "inlineText:%s".format(item.matches[0]);
										assert(item.matches.length == 1, "Surely inlineText should only have one match?");
										break;
								case "Jade.InlineTag":
										//s ~= "inlineTag:%s".format(renderTag(item, indent));
										break;
								case "Jade.SelfCloser":
										s ~= "selfcloser:true"; // we could put the automatica selfcloser for img, br, etc... by the Jade.Id detection above
										break;
								case "Jade.AndAttributes":
										tag.andAttributes = AndAttributes.parse(item);
										s ~= "andAttributes:%s".format(tag.andAttributes);
										break;
								case "Jade.StringInterpolation":
										tag.inlineText ~= renderStringInterpolation(item, indent).join("");
										break;
								default:
										//id = &item;
										s ~= "default:"~item.name;
						}
				}




			}
			return tag;
		}
		string[] renderStringInterpolation(ParseTree p, int indent) {
			string[] ret;
			switch (p.matches[0]) {
				case "#{":
					ret ~= "escape:%s // EscapedStringInterpolation".format(p.matches[1..$]);
					return ret;
				case "#[":
					auto tag = Tag.parse(new Item(indent, p.children[0]), false);
					tag.appendProlog(ret);
					return ret;
				case "!{":
					ret ~= "<unescaped-interpolation>%s</unescaped-interpolation>".format(p.matches[1]);
					return ret;
				default:
						assert(0, "Unrecognized StringInterpolation");
			}
		}
	}
}

//bool isIndentedLine(ParseTree p) {
//	if (p.children.length < 1 || p.name != "Jade.Line" || p.children[0].name != "Jade.Indent" || p.children[1].name != "Jade.Line") {
//		return false;
//	}
//	if (p.matches.length > 0 && p.children.length > 0 && p.matches[0][0]=='\t') {
//		return true;
//	}
//	return false;
//}

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
		indent = indent < 0 ? 0 : indent;
		auto strippedLine = line.strip;
		if (strippedLine == "") continue;

		//buf ~= to!string(indent);
		//writeln(line, "\n", line.length>0 , strippedLine.length >0 ? strippedLine[$-1]=='.' : false );
		if (!isRawBlock && line.length>0 && strippedLine[$-1]=='.') {
			if (isRawBlock) buf ~= "}\n"; // if a raw block tag follows a raw block tag

			buf ~= line;
			buf ~= '{';
			isRawBlock = true;
			raw_indent = indent;
		} else if (isRawBlock && indent <= raw_indent) {
			buf ~= "}\n";
			isRawBlock = false;
			buf ~= line;
			if (strippedLine[$-1] == '.') {
				buf ~= "{";
				isRawBlock = true;
			}
		} else {
			buf ~= line;
		}
		buf ~= '\n';
		last_indent = indent;
	}
	if (isRawBlock) {
		buf ~= "}\n";
	}
	return buf.data.replace("{\n}", "");
}
//Node jadeToTree(ref ParseTree p) {
//	size_t index;
//	auto ret = Node(p.children[0].name);
//	jadeToTreeWorker(ret, p.children[0].children, index);
//	writeln("ret: ", ret);
//	return ret;
//}
//struct Node {
//	string name;
//	string[] matches;
//	Node[] children;
//}
//void jadeToTreeWorker(ref Node parent, ParseTree[] lines, ref size_t index, int parent_depth = -1) {
//	writeln(">>>>");
//	while (index < lines.length-1) {
//		auto current = lines[index];
//		auto depth = cast(int)(current.matches.length > 0 && current.matches[0].length > 0 && current.matches[0][0] == '\t' ? current.matches[0].length : 0);
//		if (depth <= parent_depth) {
//			return;
//		}
//		parent.children ~= Node(current.name, current.matches[0.. $ > 2 ? 2 : $]);
//		jadeToTreeWorker(parent.children[$-1], lines[index+1..$], index, depth);
//		index++;
//	}
//	//writeln("p::", ret);
//}
