/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Util;

import std.algorithm;
import std.array;

/**
 * Returns $(D_KEYWORD true) if the array contains the given pattern.
 *
 * Params:
 *     arr = the array to check if it contains the element
 *     pattern = the pattern whose presence in the array is to be tested
 *
 * Returns: $(D_KEYWORD true) if the array contains the given pattern
 */
bool contains (T) (T[] arr, T[] pattern)
{
	return !arr.find(pattern).empty;
}

bool containsDefaultXmlContent (string source)
{
	return source.containsXmlHeader() &&
		   source.containsArchive() &&
		   source.containsXmlTag("data");
}

bool containsXmlHeader (string source)
{
	return source.contains(`<?xml version="1.0" encoding="UTF-8"?>`);
}

bool containsArchive (string source)
{
	return source.containsArchiveHeader() && source.contains("</archive>");
}

bool containsArchiveHeader (string source)
{
	return source.contains(`<archive type="org.dsource.orange.xml" version="1.0.0">`) ||
		source.contains(`<archive version="1.0.0" type="org.dsource.orange.xml">`);
}

bool containsXmlTag (string source, string tag, bool simple = false)
{
	return source.containsXmlTag(tag, null, null, simple);
}

bool containsXmlTag (string source, string tag, string attributes, bool simple = false)
{
	return source.containsXmlTag(tag, attributes, null, simple);
}

bool containsXmlTag (string source, string tag, string attributes, string content, bool simple = false)
{
	string pattern = '<' ~ tag;

	if (attributes.length > 0)
		pattern ~= ' ' ~ attributes;

	if (simple)
		return source.contains(pattern ~ "/>");

	if (content.length > 0)
		return source.contains(pattern ~ '>' ~ content ~ "</" ~ tag ~ '>');

	return source.contains(pattern ~ '>') && source.contains("</" ~ tag ~ '>');
}