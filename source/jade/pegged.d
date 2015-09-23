module jade.pegged;

import pegged.grammar;

mixin(grammar(`
# This Jade grammar puts all tags under RootTag as Jade.Line, but the first parseNode under the Line is a Indent with the amount of indents matched in its matches.length attribute
# PipedText is in its own Line because you can't count indents in the line before, NOTE: need to try using Semantic Actions to move nodes to their correct parents
Jade:
RootTag	<-
	/ Line+
Line	<- Indent* (Tag / PipedText) (endOfLine / endOfInput)
Tag 	<-
	/ Id (CssId / '.' CssClass)* TagArgs? AndAttributes? SelfCloser? (InlineTag / :Spacing+ InlineText+)?
	/ (CssId / '.' CssClass)+ TagArgs? AndAttributes? SelfCloser? (InlineTag / :Spacing+ InlineText+)?
AndAttributes <- '&' 'attributes' '(' AttributeJsonObject ')'
SelfCloser <- '/'
InlineTag <- ':' :Spacing* Id (CssId / '.' CssClass)* TagArgs? AndAttributes? SelfCloser? (:Spacing+ InlineText+)?
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
AttributeJsonObject <- :'{' (JsonKeyValue (:',' :Spacing* JsonKeyValue)*)? :'}'
JsonKeyValue <- JsonKey :Spacing* ':' :Spacing* JsonObjectDExpression
JsonKey <~
	/ :doublequote [A-Za-z\-][A-Za-z\-0-9]* :doublequote
	/ [A-Za-z][A-Za-z0-9]*
JsonObjectDExpression <~ (! (',' / '}') .)+
InlineText	<~ (! ('\r\n' / "\n") .)*
PipedText	<~ :'|' (! NewLine .)*
Spacing	<- (' ' / tab)+
NewLine <: ('\r\n' / '\n')+ # Used <: to make sure this is not in the ParseTree, also left ^ off the brackets to leave the newline chars out
Str	<- :doublequote ~(Char*) :doublequote
CssClassArray <- '[' doublequote CssClass doublequote (',' :Spacing* doublequote CssClass doublequote)* ']'
Char <- !doublequote . # Anything but a double quote
Indent  <~ tab+
`));