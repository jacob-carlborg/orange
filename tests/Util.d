/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Util;

import std.algorithm;
import std.array;
import std.xml;

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

bool equalToXml(string expected, string actual)
{
    import std.string;

    return new Document(expected.strip).isEqual(new Document(actual.strip));
}

private:

T toType(T)(Object o)
{
    auto t = cast(T)(o);

    if (t is null)
        throw new Exception("Attempt to compare a " ~ T.stringof ~ " with an instance of another type");

    return t;
}

bool isEqual(Document lhs, Object rhs)
{
    auto doc = toType!(Document)(rhs);
    return
        (lhs.prolog != doc.prolog            ) ? false : (
        (!isEqual(cast(Element) lhs, doc)    ) ? false : (
        (lhs.epilog != doc.epilog            ) ? false : (
    true )));
}

bool isEqual(Element lhs, Object rhs)
{
    import std.algorithm;
    import std.range;

    auto element = toType!(Element)(rhs);

    if (lhs.tag != element.tag)
        return false;

    return lhs.items.zip(element.items).all!(e => e[0].isEqual(e[1]));
}

bool isEqual(Item lhs, Object rhs)
{
    if (auto o = cast(Document) lhs) return o.isEqual(rhs);
    if (auto o = cast(Element) lhs) return o.isEqual(rhs);
    else return lhs == rhs;
}
