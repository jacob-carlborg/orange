/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.Serializable;

import orange.core.string;
import orange.serialization.archives.Archive;
import orange.serialization.Events;
import orange.serialization.Serializer;
import orange.util.CTFE;

interface Serializable
{
	void toData (Serializer serializer, Serializer.Data key);
	void fromData (Serializer serializer, Serializer.Data key);
}

template isSerializable (T)
{
	const isSerializable = is(T : Serializable) || (
		is(typeof(T.toData(Serializer.init, Serializer.Data.init))) &&
		is(typeof(T.fromData(Serializer.init, Serializer.Data.init))));
}

template NonSerialized (alias field)
{
	NonSerializedField!(field.stringof) __nonSerialized;
}

template NonSerialized ()
{
	NonSerializedField!("this") __nonSerialized;
}

struct NonSerializedField (string name)
{
	const field = name;
}

package:

version (Tango)
{
	const nonSerializedField = "__nonSerialized";
	const serializedField = "__serialized";
	const internalFields = [nonSerializedField[], onDeserializedField, onDeserializingField, onSerializedField, onSerializingField];
}

else
{
	mixin(
	`enum nonSerializedField = "__nonSerialized";
	enum serializedField = "__serialized";
	enum internalFields = [nonSerializedField[], onDeserializedField, onDeserializingField, onSerializedField, onSerializingField];`);
}