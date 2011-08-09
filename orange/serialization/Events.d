/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.Events;

import orange.util._;

template OnDeserialized (alias method)
{
	orange.serialization.Events.Event!(method) __onDeserialized;
}

template OnDeserializing (alias method)
{
	orange.serialization.Events.Event!(method) __onDeserializing;
}

template OnSerialized (alias method)
{
	orange.serialization.Events.Event!(method) __onSerialized;
}

template OnSerializing (alias method)
{
	orange.serialization.Events.Event!(method) __onSerializing;
}

struct Event (alias m)
{
	version (Tango)
		private const method = &m;
		
	else
		mixin("private enum method = &m;");
	
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