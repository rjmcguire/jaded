module jade.pegged;

import pegged.grammar;

mixin(grammar(`
# This Jade grammar puts all tags under RootTag as Jade.Line, but the first parseNode under the Line is a Indent with the amount of indents matched in its matches.length attribute
Jade:
RootTag	<-
	/ ^Id ('.' CssClass)* Line+
Line	<- NewLine Indent Tag
Tag 	<- Id ('.' CssClass)* TagArgs? (InlineTag / :Spacing+ Text+)? # TODO: inline Block Expansion for nested tags using ':'
InlineTag <- ':' :Spacing* Id ('.' CssClass)* TagArgs? (:Spacing+ Text+)?
Id <~ [A-Za-z\-]+
CssClass <~ [A-Za-z\-]+
TagParamKey <~ [A-Za-z\-]+
TagArgs <- '(' TagArg (',' :Spacing* TagArg)* ')'
TagArg <- TagParamKey ('=' TagParamValue)?
TagParamValue <-
	/ Str
	/ ^identifier # The value here has to be a valid d symbol
Text	<~
	/ MultiLineText+
	/ SingleLineText
SingleLineText	<~ (! ('\r\n' / "\n") .)*
MultiLineText	<~ :('\r\n' / "\n") :tab+ :'|' (! NewLine .)*
Spacing	<- (' ' / tab)+
NewLine <: ('\r\n' / '\n')+ # Used <: to make sure this is not in the ParseTree, also left ^ off the brackets to leave the newline chars out
Str	<- :doublequote ~(Char*) :doublequote
Char <- !doublequote . # Anything but a double quote
Indent  <; ^tab+
`));