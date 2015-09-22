module jade.pegged;

import pegged.grammar;

mixin(grammar(`
# This Jade grammar puts all tags under RootTag as Jade.Line, but the first parseNode under the Line is a Indent with the amount of indents matched in its matches.length attribute
Jade:
RootTag	<-
	/ ^TagName Line+
Line	<- NewLine Indent Tag
Tag 	<- TagName TagArgs? (:Spacing+ Text+)?
TagName <- Id ('.' CssClass)*
Id <~ [A-Za-z\-]+
CssClass <~ [A-Za-z\-]+
TagArgs <- '(' TagArg (',' TagArg)+ ')'
TagArg <- Id # ('=' Str)?
Text	<~
	/ MultiLineText+
	/ SingleLineText
SingleLineText	<~ (! ('\r\n' / "\n") .)*
MultiLineText	<~ :('\r\n' / "\n") :tab+ :'|' (! NewLine .)*
Spacing	<- (' ' / tab)+
NewLine <: ('\r\n' / '\n')+ # Used <: to make sure this is not in the ParseTree, also left ^ off the brackets to leave the newline chars out
Str	<- doublequote ~(Char*) doublequote
Char <- !doublequote . # Anything but a double quote
Indent  <; ^tab+
`));