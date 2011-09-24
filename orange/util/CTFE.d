/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.util.CTFE;

import orange.core.string;
import orange.util.Traits;

/// Compile time string converter. Converts the given arguments to a string.
template format (ARGS...)
{
	static if (ARGS.length == 0)
		const format = "";
	
	else
	{
		static if (is(typeof(ARGS[0]) : string))
			const format = ARGS[0] ~ format!(ARGS[1 .. $]);
		
		else
			const format = toString_!(ARGS[0]) ~ format!(ARGS[1 .. $]);
	}
}

private
{
	template toString_ (T)
	{
		const toString_ = T.stringof;
	}

	template toString_ (int i)
	{
		const toString_ = itoa!(i);
	}

	template toString_ (long l)
	{
		const toString_ = itoa!(l);
	}

	template toString_ (bool b)
	{
		const toString_ = b ? "true" : "false";
	}

	template toString_ (float f)
	{
		const toString_ = "";
	}
	
	template toString_ (alias a)
	{
		const toString_ = a.stringof;
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

/**
 * CTFE, splits the given string on the given pattern
 * 
 * Params:
 *     str = the string to split 
 *     splitChar = the character to split on
 *     
 * Returns: an array of strings containing the splited string
 */
T[][] split (T) (T[] str, T splitChar = ',')
{
	T[][] arr;
	size_t x;
	
	foreach (i, c ; str)
	{
		if (splitChar == c)
		{
			if (str[x] == splitChar)
				x++;
			
			arr ~= str[x .. i];
			x = i;
		}
	}
	
	if (str[x] == splitChar)
		x++;
	
	arr ~= str[x .. $];
	
	return arr;
}

private:
	
template decimalDigit (int n)	// [3]
{
	const decimalDigit = "0123456789"[n .. n + 1];
} 

template itoa (long n)
{   
	static if (n < 0)
		const itoa = "-" ~ itoa!(-n); 
  
	else static if (n < 10)
		const itoa = decimalDigit!(n); 
  
	else
		const itoa = itoa!(n / 10L) ~ decimalDigit!(n % 10L); 
}