module jade.pegged;

import pegged.grammar;

mixin(grammar(`
# This Jade grammar puts all tags under RootTag as Jade.Line, but the first parseNode under the Line is a Indent with the amount of indents matched in its matches.length attribute
# PipedText is in its own Line because you can't count indents in the line before, NOTE: need to try using Semantic Actions to move nodes to their correct parents
Jade:
RootTag	<-
	/ ^Id ('.' CssClass)* Line+
Line	<- NewLine Indent (Tag / PipedText)
Tag 	<-
	/ Id ('.' CssClass)* TagArgs? SelfCloser? (InlineTag / :Spacing+ InlineText+)?
	/ ('.' CssClass)+ TagArgs? SelfCloser? (InlineTag / :Spacing+ InlineText+)?
SelfCloser <- '/'
InlineTag <- ':' :Spacing* Id ('.' CssClass)* TagArgs? (:Spacing+ InlineText+)?
Id <~ [A-Za-z\-]+
CssClass <~ [A-Za-z\-]+
TagParamKey <~ [A-Za-z\-]+
TagArgs <- '(' TagArg (',' :Spacing* TagArg)* ')'
TagArg <- TagParamKey (^('=' / '!=') TagParamValue)?
TagParamValue <-
	/ Str
	/ StyleJsonObject
	/ DExpression
DExpression <~ (! (',' / ')') .)+
StyleJsonObject <- :'{' (StyleJsonKeyValue (:',' :Spacing* StyleJsonKeyValue)*)? :'}'
StyleJsonKeyValue <~ CssClass :Spacing* ':' :Spacing* doublequote ~(Char*) doublequote
InlineText	<~ (! ('\r\n' / "\n") .)*
PipedText	<~ :'|' (! NewLine .)*
Spacing	<- (' ' / tab)+
NewLine <: ('\r\n' / '\n')+ # Used <: to make sure this is not in the ParseTree, also left ^ off the brackets to leave the newline chars out
Str	<- :doublequote ~(Char*) :doublequote
Char <- !doublequote . # Anything but a double quote
Indent  <; ^tab+
`));