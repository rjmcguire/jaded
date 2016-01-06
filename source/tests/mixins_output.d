module tests.mixins_output;
import arsd.jsvar;
import std.stdio;
import std.traits;

unittest {
	string escapeAttributeValue(T)(T arg) {
		import std.conv;
		import std.string : replace;
		return to!string(arg).replace(`\`, `\\`).replace(`"`, `&quote;`);
	}

/** jade template: views/mixins.jade 36 */
import std.array : appender;
auto buf = appender!string;
void JadeMixin_list(alias block, Attributes)(Attributes attributes) {
buf ~= `<ul1>`;
buf ~= `<li>foo</li>`;
buf ~= `<li>bar</li>`;
buf ~= `<li>baz</li>`;
buf ~= `</ul1>`;
}
JadeMixin_list!(null)(var.emptyObject());
JadeMixin_list!(null)(var.emptyObject());
void JadeMixin_pet(alias block, Attributes, Name)(Attributes attributes, Name name) {
buf ~= `<li class="pet"></li>`;
}
buf ~= `<ul2>`;
JadeMixin_pet!(null)(var.emptyObject(),"cat");
JadeMixin_pet!(null)(var.emptyObject(),"dog");
JadeMixin_pet!(null)(var.emptyObject(),"pig");
buf ~= `</ul2>`;
void JadeMixin_list2(alias block, Attributes, Id, Items...)(Attributes attributes, Id id, Items items) {
buf ~= `<ul3 id="`~ escapeAttributeValue(var(id).get!string) ~`">`;
foreach (item; items) {
buf ~= `<li></li>`;
}
buf ~= `</ul3>`;
}
JadeMixin_list2!(null)(var.emptyObject(),"my-list", 1, 2, 3, 4);
void JadeMixin_link(alias block, Attributes, Href, Name)(Attributes attributes, Href href, Name name) {
buf ~= `<a class="`~ var(attributes["class"]).get!string ~`" href="`~ escapeAttributeValue(var(href).get!string) ~`"></a>`;
}
JadeMixin_link!(null)(var("class", "btn"),"/foo", "foo");
void JadeMixin_article(alias block, Attributes, Title)(Attributes attributes, Title title) {
buf ~= `<div class="article">`;
buf ~= `<div class="article-wrapper">`;
buf ~= `<h1></h1>`;
static if (isCallable!block) {
buf ~= block();
}
 else {
buf ~= `<p>No content provided</p>`;
}
buf ~= `</div>`;
buf ~= `</div>`;
}
JadeMixin_article!(null)(var.emptyObject(),"Hello world");
JadeMixin_article!(() { auto buf = appender!string;
buf ~= `<p>This is my</p>`;

buf ~= `<p>Amazing article</p>`;
return buf.data; })(var.emptyObject(),"Hello world");
	writeln(buf.data);
}