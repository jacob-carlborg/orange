/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.Events;

import orange.util._;

/**
 * This event is triggered after the struct/class, this template has been mixed into,
 * has been completely deserialized, including all the fields.
 *
 * Params:
 *     method = the method to be invoked when the event is triggered
 */
template OnDeserialized (alias method)
{
	static orange.serialization.Events.Event!(method) __onDeserialized;
}

/**
 * This event is triggered after the struct/class (that this template has been mixed into)
 * has been deserialized, but before any fields have been deserialized.
 *
 * Params:
 *     method = the method to be invoked when the event is triggered
 */
template OnDeserializing (alias method)
{
	static orange.serialization.Events.Event!(method) __onDeserializing;
}

/**
 * This event is triggered after the struct/class (that this template has been mixed into)
 * has been completely serialized, including all the fields.
 *
 * Params:
 *     method = the method to be invoked when the event is triggered
 */
template OnSerialized (alias method)
{
	static orange.serialization.Events.Event!(method) __onSerialized;
}

/**
 * This event is triggered after the struct/class (that this template has been mixed into)
 * has been serialized, but before any fields have been serialized.
 *
 * Params:
 *     method = the method to be invoked when the event is triggered
 */
template OnSerializing (alias method)
{
	static orange.serialization.Events.Event!(method) __onSerializing;
}

/**
 * This struct represents an event.
 *
 * Params:
 *     m = the method to be invoked when the event is triggered
 */
struct Event (alias m)
{
	private enum method = &m;

	/**
	 * Triggers the event on the given value.
	 *
	 * Params:
	 *     value = the object to trigger the event on
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