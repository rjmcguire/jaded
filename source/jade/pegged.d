module jade.pegged;

import pegged.grammar;

mixin(grammar(`
# This Jade grammar puts all tags under RootTag as Jade.Line, but the first parseNode under the Line is a Indent with the amount of indents matched in its matches.length attribute
# PipedText is in its own Line because you can't count indents in the line before, NOTE: need to try using Semantic Actions to move nodes to their correct parents
Jade:
RootTag	<-
	/ DocType endOfLine Line+
	/ Line+
DocType <~ :'doctype ' (! endOfLine .)*
Line	<-
	/ Indent* (Include / Extend / Block / Conditional / UnbufferedCode / BufferedCode / Iteration / MixinDecl / Mixin / Case / Tag / PipedText / Comment / RawHtmlTag / Filter / AnyContentLine) (endOfLine / endOfInput)
	/ endOfLine
AnyContentLine <~ (! endOfLine .)*
BlockInATag <- '.'																			# Without making indent and dedent handling block in a tag can't have "valid" or even partially valid tags in the raw text
StringInterpolation <-
	/ ~('!{' (! '}' .)* '}') InlineText
	/ ('#[' TagInterpolate ']') InlineText
	/ ~('#{' (! '}' .)* '}')? InlineText
TagInterpolate <- Id? (CssId / '.' CssClass)* TagArgs? AndAttributes? SelfCloser? (:Spacing+ TextStop(']'))?
TextStop(StopElem) <~ (! StopElem .)*
MixinDecl <- 'mixin' :Spacing+ DVariableName MixinDeclArgs?
MixinDeclArgs <- '(' DVariableName (',' :Spacing* DVariableName)* MixinVarArg? ')'
MixinVarArg <- (',' :Spacing* '...' DVariableName)
Mixin <- '+' DVariableName ('(' :Spacing* (TagParamValue (',' :Spacing* TagParamValue)*)? ')')? TagArgs?
Case <-
	/ ^'case' Spacing+ DLineExpression
	/ ^'when' ~(! (':' / endOfLine / endOfInput) .)* InlineTag?
	/ ^'default' InlineTag?
Iteration <-
	/ ('each' / 'for') :Spacing+ DVariableName (',' :Spacing* DVariableName)? :Spacing+ ^'in' :Spacing+ DLineExpression
	/ 'while' DLineExpression
DVariableName <~ [A-Za-z][A-Za-z0-9]*
UnbufferedCode <- '-' DLineExpression*
BufferedCode <- ^('=' / '!=') DLineExpression*
Conditional <-
	/ IfBlock
	/ ('if' / 'unless') DLineExpression
	/ 'else'
IfBlock <- 'if' :Spacing+ 'block'
Extend <- 'extends' FileName
Block <- 'block' DLineExpression?
Filter <- ':' FilterName
Include <- :'include' (':' FilterName)? :Spacing+ FileName
FileName <~ (! endOfLine .)*
FilterName <; Id
RawHtmlTag <~ ^'<' (! endOfLine .)*
Tag 	<-
	/ Id (CssId / '.' CssClass)* TagArgs? AndAttributes? (BlockInATag / SelfCloser? (InlineTag+ BufferedCode / :Spacing+ InlineText StringInterpolation+ / BufferedCode)?)
	/ (CssId / '.' CssClass)+ TagArgs? AndAttributes? (BlockInATag / SelfCloser? (InlineTag+ BufferedCode / :Spacing+ InlineText StringInterpolation+ / BufferedCode)?)
Comment <- '//' (^'-')? InlineText?
AndAttributes <- '&' 'attributes' '(' (AttributeJsonObject / ParamDExpression) ')'
SelfCloser <- '/'
InlineTag <- ':' :Spacing* Id (CssId / '.' CssClass)* TagArgs? AndAttributes? (BlockInATag / SelfCloser? (:Spacing+ InlineText StringInterpolation+)?)
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
PipedText	<~ :'|' (! NewLine .)*
Spacing	<- (' ' / tab)+
NewLine <: ('\r\n' / '\n')+ # Used <: to make sure this is not in the ParseTree, also left ^ off the brackets to leave the newline chars out
Str	<- :doublequote ~(Char*) :doublequote
CssClassArray <- '[' doublequote CssClass doublequote (',' :Spacing* doublequote CssClass doublequote)* ']'
Char <- !doublequote . # Anything but a double quote
Indent  <~ tab+
`));