/**
 * Copyright: Copyright (c) 2008-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: 2008
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 *
 */
module orange.util.collection.Array;

inout(T)[] assumeUnique (T) (ref T[] source, ref inout(T)[] destination)
{
	destination = cast(inout(T)[]) source;
	source = null;

	return destination;
}