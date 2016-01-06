module tests.interpolation_output;
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

/** jade template: views/interpolation.jade 12 */
import std.array : appender;
auto buf = appender!string;
var title = "On Dogs: Man's Best Friend";
var author = "enlore";
var theGreat = "<span>escape!</span>";
buf ~= `<h1>`~ escapeAttributeValue(var(title).get!string) ~`</h1>`;
buf ~= `<p>Written with love by `~ escapeHtmlOutput(var(author).get!string) ~`</p>`;
buf ~= `<p>This will be safe: `~ escapeHtmlOutput(var(theGreat).get!string) ~`</p>`;
var msg = "not my inside voice";
buf ~= `<p>This is `~ escapeHtmlOutput(var(msg.toUpperCase()).get!string) ~`</p>`;
var riskyBusiness = "<em>Some of the girls are wearing my mother's clothing.</em>";
buf ~= `<div class="quote">`;
buf ~= `<p>Joel: `~ var(riskyBusiness).get!string ~`</p>`;
buf ~= `</div>`;
buf ~= `<p>If you take a look at this page's source #[a(target="_blank", href="https://github.com/jadejs/jade/blob/master/docs/views/reference/interpolation.jade") on GitHub],you'll see several places where the tag interpolation operator isused, like so.</p>`;

	writeln(buf.data);
}