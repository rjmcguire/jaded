module jade.pegged;

import pegged.grammar;

mixin(grammar(`
Jade:
RootTag	<-
	/ ^identifier Line
Line	<- NewLine Indent (Line / Tag)*
Tag 	<- identifier Text+
Text	<~
	/ MultiLineText+
	/ SingleLineText
SingleLineText	<~ (! ('\r\n' / "\n") .)*
MultiLineText	<~ :('\r\n' / "\n") :tab+ :'|' (! NewLine .)*
#Spacing	<- (' ' / tab)+
NewLine <: ('\r\n' / '\n')+ # Used <: to make sure this is not in the ParseTree, also left ^ off the brackets to leave the newline chars out
Indent  <; ^tab+
`));