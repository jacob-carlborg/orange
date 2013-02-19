/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.util.CTFE;

import orange.util.Traits;

/// Compile time string converter. Converts the given arguments to a string.
template format (ARGS...)
{
	static if (ARGS.length == 0)
		enum format = "";

	else
	{
		static if (is(typeof(ARGS[0]) : string))
			enum format = ARGS[0] ~ format!(ARGS[1 .. $]);

		else
			enum format = toString_!(ARGS[0]) ~ format!(ARGS[1 .. $]);
	}
}

private
{
	template toString_ (T)
	{
		enum toString_ = T.stringof;
	}

	template toString_ (int i)
	{
		enum toString_ = itoa!(i);
	}

	template toString_ (long l)
	{
		enum toString_ = itoa!(l);
	}

	template toString_ (bool b)
	{
		enum toString_ = b ? "true" : "false";
	}

	template toString_ (float f)
	{
		enum toString_ = "";
	}

	template toString_ (alias a)
	{
		enum toString_ = a.stringof;
	}
}

/**
 * Compile-time function to get the index of the give element.
 *
 * Performs a linear scan, returning the index of the first occurrence
 * of the specified element in the array, or U.max if the array does
 * not contain the element.
 *
 * Params:
 *     arr = the array to get the index of the element from
 *     element = the element to find
 *
 * Returns: the index of the element or size_t.max if the element was not found.
 */
size_t indexOf (T) (T[] arr, T element)
{
	static if (is(T == char) || is(T == wchar) || is(T == dchar))
	{
		foreach (i, e ; arr)
			if (e == element)
				return i;
	}

	else
	{
		foreach (i, e ; arr)
			if (e == element)
				return i;
	}

	return size_t.max;
}

/**
 * Returns true if the given array contains the given element,
 * otherwise false.
 *
 * Params:
 *     arr = the array to search in for the element
 *     element = the element to search for
 *
 * Returns: true if the array contains the element, otherwise false
 */
bool contains (T) (T[] arr, T element)
{
	return indexOf(arr, element) != size_t.max;
}

private:

template decimalDigit (int n)	// [3]
{
	enum decimalDigit = "0123456789"[n .. n + 1];
}

template itoa (long n)
{
	static if (n < 0)
		enum itoa = "-" ~ itoa!(-n);

	else static if (n < 10)
		enum itoa = decimalDigit!(n);

	else
		enum itoa = itoa!(n / 10L) ~ decimalDigit!(n % 10L);
}