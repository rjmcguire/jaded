/*
The MIT License (MIT)

Copyright (c) 2015-2016 rjmcguire

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

module jade.pegged;

import pegged.grammar;
import std.stdio;
mixin(grammar(`
# This Jade grammar puts all tags under RootTag as Jade.Line, but the first parseNode under the Line is a Indent with the amount of indents matched in its matches.length attribute
# PipedText is in its own Line because you can't count indents in the line before, NOTE: need to try using Semantic Actions to move nodes to their correct parents
Jade:
#RootTagHolder <- RootTag{processRootTag}
RootTag	<- ((Comment / DocType) endOfLine)* (MixinDecl / Line)+
DocType <~ :'doctype' :Spacing+ (! endOfLine .)*
Line	<-
	/ Indent Line
	/  (Include / Extend / Block / Conditional / UnbufferedCode / BufferedCode / Iteration / MixinDecl / Mixin / Case / Tag / PipedText / Comment / RawHtmlTag / Filter / AnyContentLine) (endOfLine / endOfInput)
	/ endOfLine
AnyContentLine <~ (! endOfLine .)*
BlockInATag <- :'.{' :endOfLine BlockInATagText (StringInterpolation BlockInATagText?)* endOfLine '}'
BlockInATagText <- ~(! StopBlockInATag .)+
StopBlockInATag <- endOfLine '}' endOfLine / '#' / '!'
StringInterpolation <-
	/ ('!{' ~(! '}' .)* :'}')
	/ ('#[' TagInterpolate ']')
	/ ('#{' ~(! '}' .)* :'}')?
TagInterpolate <- Id? (CssId / '.' CssClass)* TagArgs? AndAttributes? SelfCloser? BufferedCode? (:Spacing+ TextStop(']'))?
TextStop(StopElem) <~ (! StopElem .)*
MixinDecl <- :'mixin' :Spacing+ DVariableName MixinDeclArgs? endOfLine
MixinDeclArgs <- '(' DVariableName (',' :Spacing* DVariableName)* MixinVarArg? ')'
MixinVarArg <- (:',' :Spacing* :'...' DVariableName)
Mixin <- :'+' DVariableName MixinArgs? TagArgs?
MixinArgs <- ('(' :Spacing* (TagParamValue (',' :Spacing* TagParamValue)*)? ')')
Case <-
	/ ^'case' :Spacing+ DLineExpression
	/ ^'when' :Spacing+ ~(! (':' / endOfLine / endOfInput) .)* InlineTag?
	/ ^'default' InlineTag?
Iteration <-
	/ ('each' / 'for') :Spacing+ DVariableName (',' :Spacing* DVariableName)? :Spacing+ ^'in' :Spacing+ DLineExpression
	/ 'while' DLineExpression
DVariableName <~ [A-Za-z][A-Za-z0-9]*
UnbufferedCode <- '-' :Spacing* DLineExpression*
BufferedCode <- ^('=' / '!=') :Spacing* DLineExpression* # Surely we don't need the * on the end here?
Conditional <-
	/ IfBlock
	/ ('if' / 'unless') ConditionalExpression
	/ 'else' (:Spacing+ 'if' ConditionalExpression)?
ConditionalExpression <~
	/ :Spacing+ (! endOfLine .)+
	/ :Spacing* :'(' (! ')' .)+ :')'
IfBlock <- 'if' :Spacing+ 'block'
Extend <- :'extends' :Spacing+ FileName
Block <- :'block' :Spacing+ DLineExpression?
Filter <- ':' FilterName
Include <- :'include' (':' FilterName)? :Spacing+ FileName
FileName <~ (! endOfLine .)*
FilterName <; Id
RawHtmlTag <~ ^'<' (! endOfLine .)*
Tag 	<-
	/ Id (CssId / '.' CssClass)* TagArgs? AndAttributes? (BlockInATag / SelfCloser? (InlineTag+ BufferedCode / :Spacing+ InlineText (StringInterpolation+ InlineText)* / BufferedCode)?)
	/ (CssId / '.' CssClass)+ TagArgs? AndAttributes? (BlockInATag / SelfCloser? (InlineTag+ BufferedCode / :Spacing+ InlineText (StringInterpolation+ InlineText)* / BufferedCode)?)
Comment <-
	/ '//-' InlineText?
	/ '//' InlineText?
AndAttributes <- '&' 'attributes' '(' (AttributeJsonObject / ParamDExpression) ')'
SelfCloser <- '/'
InlineTag <- :':' :Spacing* Id (CssId / '.' CssClass)* TagArgs? AndAttributes? (BlockInATag / SelfCloser? (:Spacing+ InlineText (StringInterpolation+ InlineText)*)?)
Id <~ [A-Za-z\-][A-Za-z\-0-9]*
CssClass <~ [A-Za-z\-][A-Za-z\-0-9]*
CssId <~ :'#' Id
TagArgs <- '(' TagArg (',' :Spacing* TagArg)* ')'
TagArg <- TagParamKey (^('=' / '!=') TagParamValue)?
TagParamKey <~ [A-Za-z\-]+
TagParamValue <-
	/ Str
	/ AttributeJsonObject
	/ CssClassArray
	/ ParamDExpression
ParamDExpression <~ (! (',' / ')') .)+
DLineExpression <~ (! endOfLine .)+
AttributeJsonObject <- :'{' (JsonKeyValue (:',' :Spacing* JsonKeyValue)*)? :'}'
JsonKeyValue <- JsonKey :Spacing* ':' :Spacing* JsonObjectDExpression
JsonKey <~
	/ :doublequote [A-Za-z\-][A-Za-z\-0-9]* :doublequote
	/ [A-Za-z][A-Za-z0-9]*
JsonObjectDExpression <~ (! (',' / '}') .)+
InlineText	<~ (! ('\r\n' / "\n" / '#[' / '#{' / '!{') .)*
PipedText	<-
	/ '|' :Spacing* InlineText? (StringInterpolation+ InlineText)*
	#/ '|' (! NewLine .)+
	#/ '|' endOfLine
Spacing	<- (' ' / tab)+
NewLine <: ('\r\n' / '\n')+ # Used <: to make sure this is not in the ParseTree, also left ^ off the brackets to leave the newline chars out
Str	<~ doublequote (Char*) doublequote
CssClassArray <~ :'[' doublequote CssClass doublequote (',' :Spacing* doublequote CssClass doublequote)* :']'
Char <- !doublequote . # Anything but a double quote
Indent  <~ tab+
`));


//ParseTree[] stack;
//ulong last_indent;
//ulong lineNumber;

//PT indent(PT)(PT p) {
//	import std.stdio : writeln;
//	if (p.matches.length > 0 && p.children.length > 0) {
//		auto child = p.children[$-1];
//		writeln("p.child ", child.name);
//		writeln("indent: ", p.matches[0]);
//	}
//	return p;
//}

//// PT fields: name, successful, matches, input, begin, end, children, toString, failMsg, dup
//PT line(PT)(PT p) {
//	import std.stdio : writeln;
//	import std.string : format;
//	lineNumber++;
//	if (p.matches.length > 0 && p.children.length > 0 && p.matches[0][0]=='\t') {
//		foreach (t; p.matches[0]) { assert(t == '\t', "All indents must be tabs at line: %d\n".format(lineNumber, p)); }
//		auto indent = p.matches[0].length; // number of tabs at start of line
//		assert(indent <= last_indent+1, "Excessive indent at line: %d (%d vs %d)\n%s".format(lineNumber, indent, last_indent, p));
//		//writeln("line: ", p.name, p.children[0].name, cast(ubyte[])p.matches[0]);
//		last_indent = indent;
//	} else {
//		last_indent = 0;
//	}
//	return p;
//}


// PT fields: name, successful, matches, input, begin, end, children, toString, failMsg, dup
//PT processRootTag(PT)(PT p) {
//	import std.string : format;
//	int last_indent;
//	auto tmp = findParseTree(p, "oneOrMore!(Jade.Line)");
//	if (!tmp) throw new Exception("need at least one line");
//	auto lines = tmp.children;
//	foreach (line; lines) {
//		if (p.matches.length > 0 && p.children.length > 0 && p.matches[0][0]=='\t') {

//		}
//		assert(line.name == "Jade.Line", "Expected Jade.Line but got %s".format(line.name));
//	}
//	return p;
//}


//ParseTree* findParseTree(ref ParseTree p, string name) {
//	if (p.name == name) {
//		return &p;
//	}
//	foreach (child; p.children) {
//		auto tmp = findParseTree(child, name);
//		if (tmp !is null) {
//			return tmp;
//		}
//	}
//	return null;
//}
