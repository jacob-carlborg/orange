/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.Events;

import orange.core.Attribute;
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
 * Methods with this attribute attached will be called after the struct/class has been
 * deserialized.
 */
@attribute struct onDeserialized { }

/**
 * This event is triggered after the struct/class, this template has been mixed into,
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
 * Methods with this attribute attached will be called before the struct/class has been
 * deserialized.
 */
@attribute struct onDeserializing { }

/**
 * This event is triggered after the struct/class, this template has been mixed into,
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
 * Methods with this attribute attached will be called after the struct/class has been
 * serialized.
 */
@attribute struct onSerialized { }

/**
 * This event is triggered after the struct/class, this template has been mixed into,
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
 * Methods with this attribute attached will be called before the struct/class has been
 * serialized.
 */
@attribute struct onSerializing { }

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

enum onDeserializedField = "__onDeserialized";
enum onDeserializingField = "__onDeserializing";
enum onSerializedField = "__onSerialized";
enum onSerializingField = "__onSerializing";