/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.Events;

import orange.util._;

/**
 * 
 * Authors: doob
 */
template OnDeserialized (alias method)
{
	static orange.serialization.Events.Event!(method) __onDeserialized;
}

/**
 * 
 * Authors: doob
 */
template OnDeserializing (alias method)
{
	static orange.serialization.Events.Event!(method) __onDeserializing;
}

/**
 * 
 * Authors: doob
 */
template OnSerialized (alias method)
{
	static orange.serialization.Events.Event!(method) __onSerialized;
}

/**
 * 
 * Authors: doob
 */
template OnSerializing (alias method)
{
	static orange.serialization.Events.Event!(method) __onSerializing;
}

/**
 * 
 * Authors: doob
 */
struct Event (alias m)
{
	version (Tango)
		private const method = &m;
		
	else
		mixin("private enum method = &m;");
	
	/**
	 * 
	 * Params:
	 *     value =
	 */
	void opCall (T) (T value)
	{
		void delegate () dg;
		dg.ptr = cast(void*) value;
		dg.funcptr = method;
		dg();
	}
}

package:

const onDeserializedField = "__onDeserialized";
const onDeserializingField = "__onDeserializing";
const onSerializedField = "__onSerialized";
const onSerializingField = "__onSerializing";