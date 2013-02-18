/**
 * Copyright: Copyright (c) 2008-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: 2008
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 *
 */
module orange.util.collection.Array;

import std.c.string : memmove;
import algorithm = std.algorithm;

import orange.util.Traits;

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
	static if (isChar!(T))
		return stdString.indexOf(arr, element) != -1;

	else
	    return !algorithm.find(arr, pattern).empty;
}

/**
 * Returns $(D_KEYWORD true) if this array contains no elements.
 *
 * Params:
 *     arr = the array to check if it's empty
 *
 * Returns: $(D_KEYWORD true) if this array contains no elements
 */
bool isEmpty (T) (T[] arr)
{
	return arr.length == 0;
}

/**
 * Returns $(D_KEYWORD true) if this array contains no elements.
 *
 * Params:
 *     arr = the array to check if it's empty
 *
 * Returns: $(D_KEYWORD true) if this array contains no elements
 */
alias isEmpty empty;

version (D_Version2)
	mixin(`inout(T)[] assumeUnique (T) (ref T[] source, ref inout(T)[] destination)
	{
		destination = cast(inout(T)[]) source;
		source = null;

		return destination;
	}`);

else
	T[] assumeUnique (T) (ref T[] source, ref T[] destination)
	{
		destination = source;
		source = null;

		return destination;
	}
