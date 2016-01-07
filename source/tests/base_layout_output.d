module tests.base_layout_output;
import arsd.jsvar;
import std.stdio;
import std.traits;

unittest {
	string escapeAttributeValue(T)(T arg) {
		import std.conv;
		import std.string : replace;
		return to!string(arg).replace(`\`, `\\`).replace(`"`, `&quote;`);
	}
	string escapeHtmlOutput(T)(T arg) {
		import std.conv;
		import std.string : replace;
		return to!string(arg).replace(`&`, `&amp`).replace(`<`, `&lt;`).replace(`>`, `&gt;`);
	}
	import std.string : format, join;
	string outputStyle(T)(T arg) {
		string[] ret;
		foreach (k,v; arg) {
			ret ~= "%s: %s".format(k, v);
		}
		return ret.join(";");
	}
	string outputCssClassArray(Args...)(Args args) {
		string[] ret;
		foreach (arg; args) {
			ret ~= escapeAttributeValue(arg);
		}
		return ret.join(",");
	}

/** jade template: views/base_layout.jade 100 */
import std.array : appender;
auto buf = appender!string;
buf ~= `<!DOCTYPE html>`;
auto currentUrl = "/";
auto riskyBusiness = "<b>risky</b>";
buf ~= `<!--[if IE 8]>`;
buf ~= `<html lang="`~ escapeAttributeValue(var("en").get!string) ~`" class="`~ escapeAttributeValue(var("lt-ie9").get!string) ~`"></html>`;
buf ~= `<![endif]-->`;
buf ~= `<html lang="`~ escapeAttributeValue(var("en").get!string) ~`">`;
buf ~= `<head>`;
buf ~= `<title>Page Title Here</title>`;
buf ~= `<style>`;
buf ~= import(`style.css`);
buf ~= `</style>`;
buf ~= `</head>`;
buf ~= `<body class="base-css" ng-app="`~ escapeAttributeValue(var("MyApp").get!string) ~`" ng-controller="`~ escapeAttributeValue(var("CtrlII").get!string) ~`">`;
bool some_d_var = true;
string some_other_d_var = "woot";
buf ~= `			<!--  this is the displayed content `;
buf ~= `-->`;
buf ~= `<p id="`~ escapeAttributeValue(var("").get!string) ~`" p-form-hook="`~ escapeAttributeValue(var(some_d_var ? "yes" :"no").get!string) ~`" marked="`~ escapeAttributeValue(var().get!string) ~`">This is a paragraph`;
buf ~= `That continues on`;
buf ~= `multiple lines`;
buf ~= `</p>`;
buf ~= `<ul isit="`~ escapeAttributeValue(var(some_other_d_var == "woot").get!string) ~`">`;
buf ~= `<li class="one-css two-css"></li>`;
buf ~= `</ul>`;
buf ~= `<div class="img-holder">`;
buf ~= `<img class="image" src="`~ escapeAttributeValue(var("logo.gif").get!string) ~`" style="`~ outputStyle(["background": ("red"),"padding": ("0px")]) ~`"></img>`;
buf ~= `</div>`;
buf ~= `</body>`;
buf ~= `<woot id="content1">as2df`;
buf ~= `<woot2 id="woot2" class="`~ outputCssClassArray("c1","c2") ~`">as3dfas3df</woot2>`;
buf ~= `<woot3 class="`~ escapeAttributeValue(var(["active": (currentUrl == "/about")]).get!string) ~`"></woot3>`;
buf ~= `<p>Placeholder footer block</p>`;
buf ~= `</woot>`;
buf ~= `</html>`;
var host = "remotehost";
var user = var.emptyObject;
if ("localhost" == host) {
buf ~= `<div id="foo" data-bar="`~ escapeAttributeValue(var("foo").get!string) ~`" goot-one="`~ escapeAttributeValue(var().get!string) ~`">`;
buf ~= `</div>`;
}
 else {
buf ~= `<merrrt></merrrt>`;
}
if (!(user.isAnonymous)) {
buf ~= `<p>You are logged in</p>`;
}
buf ~= `<ul>`;
import std.conv;
foreach (index, val; [1:"one",2:"two",3:"three"]) {
buf ~= `<li>`~ escapeAttributeValue(var(to!string(index) ~": "~ val).get!string) ~`</li>`;
}
buf ~= `</ul>`;
int n=1;
while ( n < 4) {
buf ~= `<li>`~ escapeAttributeValue(var(n++).get!string) ~`</li>`;
}
var friends = 0;
buf ~= `<!-- 2 Jade.Case depth:0 -->`;
buf ~= `<!-- 2 Jade.Case depth:1 -->`;
buf ~= `<!-- 2 Jade.Case depth:1 -->`;
buf ~= `<p>you have very few friends</p>`;
buf ~= `<!-- 2 Jade.Case depth:1 -->`;
void JadeMixin_list(alias block, Attributes)(Attributes attributes) {
buf ~= `<ul>`;
buf ~= `<li>foo</li>`;
buf ~= `<li>bar</li>`;
buf ~= `<li>baz</li>`;
buf ~= `</ul>`;
}
JadeMixin_list!(null)(var.emptyObject());
JadeMixin_list!(null)(var.emptyObject());
void JadeMixin_pet(alias block, Attributes, Name)(Attributes attributes, Name name) {
buf ~= `<li class="pet">`~ escapeAttributeValue(var(name).get!string) ~`</li>`;
}
buf ~= `<ul>`;
JadeMixin_pet!(null)(var.emptyObject(),"cat");
JadeMixin_pet!(null)(var.emptyObject(),"dog");
JadeMixin_pet!(null)(var.emptyObject(),"pig");
buf ~= `</ul>`;
void JadeMixin_article(alias block, Attributes, Title)(Attributes attributes, Title title) {
buf ~= `<div class="article">`;
buf ~= `<div class="article-wrapper">`;
buf ~= `<h1>`~ escapeAttributeValue(var(title).get!string) ~`</h1>`;
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
void JadeMixin_link(alias block, Attributes, Href, Name)(Attributes attributes, Href href, Name name) {
buf ~= `<a class="`~ var(attributes["class"]).get!string ~`" href="`~ escapeAttributeValue(var(href).get!string) ~`">`~ escapeAttributeValue(var(name).get!string) ~`</a>`;
}
JadeMixin_link!(null)(var("class", "btn"),"/foo", "foo");
void JadeMixin_link2(alias block, Attributes, Href, Name)(Attributes attributes, Href href, Name name) {
buf ~= `<a href="`~ escapeAttributeValue(var(href).get!string) ~`">`~ escapeAttributeValue(var(name).get!string) ~`</a>`;
}
JadeMixin_link2!(null)(var("class", "btn"),"/foo", "foo");
void JadeMixin_list2(alias block, Attributes, Id, Items...)(Attributes attributes, Id id, Items items) {
buf ~= `<ul id="`~ escapeAttributeValue(var(id).get!string) ~`">`;
foreach (item; items) {
buf ~= `<li>`~ escapeAttributeValue(var(item).get!string) ~`</li>`;
}
buf ~= `</ul>`;
}
JadeMixin_list2!(null)(var.emptyObject(),"my-list", 1, 2, 3, 4);
buf ~= `<p>If you take a look at this page's source <a target="`~ escapeAttributeValue(var("_blank").get!string) ~`" href="`~ escapeAttributeValue(var("https://github.com/jadejs/jade/blob/master/docs/views/reference/interpolation.jade").get!string) ~`">on GitHub</a>, youll see several places where the tag interpolation operator is used like so. .quote // this is raw text so the .quote means nothing to jade p Joel: `~ var(riskyBusiness).get!string ~`</p>`;
buf ~= `<p>This is supposed to just be text inside a p tag.</p>`;
import std.uni : toUpper;
string msg = "not my inside voice";
buf ~= `<p>This is `~ escapeHtmlOutput(var(msg.toUpper()).get!string) ~` &lt;- <a href="`~ escapeAttributeValue(var("#").get!string) ~`">upper case</a> characters</p>`;
buf ~= `<!--  Following is as4df, its the last tag `;
buf ~= `-->`;
buf ~= `<as4df></as4df>`;

	
writeln(buf.data);
}