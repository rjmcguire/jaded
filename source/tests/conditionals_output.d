module tests.conditionals_output;

import arsd.jsvar;
import std.stdio;
unittest {
	import std.array : appender;
	auto buf = appender!string;
	var user = var([ "name": "foo bar baz" ]);
	var authorised = false;
	buf ~= `<user id="user">`;
	if (user.description) {
		buf ~= `<h2>Description</h2>`;
		buf ~= `<p class="description"></p>`;
	} else if (authorised) {
		buf ~= `<h2>Description</h2>`;
		buf ~= `<p class="description">User has no description,why not add one...</p>`;
	} else {
		buf ~= `<h1>Description</h1>`;
		buf ~= `<p class="description">User has no description</p>`;
	}
	buf ~= `</user>`;

	if (!(user.isAnonymous)) {
		//buf ~= `<p>You're logged in as escape:["user.name"] // EscapedStringInterpolation <a href="/logout">Logout</a></p>`;
		buf ~= `<p>You're logged in as `~user.name.toString~` <a href="/logout">Logout</a></p>`;
	}
	writeln(buf.data);
}