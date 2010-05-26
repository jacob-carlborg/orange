/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.Serializable;

import orange.serialization.archives.Archive;
import orange.serialization.Events;
import orange.util.CTFE;

template Serializable ()
{
	void toData (T) (T archive, T.DataType key)
	{		
		alias typeof(this) ThisType;
		
		foreach (i, dummy ; typeof(T.tupleof))
		{
			alias typeof(ThisType.tupleof[i]) FieldType;
			
			const field = nameOfFieldAt!(ThisType, i);			
			auto value = getValueOfField!(ThisType, FieldType, field)(this);
			
			archive.archive(value, field);
		}
	}
	
	void fromData (T) (T archive, T.DataType key)
	{
		alias typeof(this) ThisType;
		
		foreach (i, dummy ; typeof(ThisType.tupleof))
		{
			alias typeof(ThisType.tupleof[i]) FieldType;
			
			const field = nameOfFieldAt!(ThisType, i);
			auto value = archive.unarchive!(FieldType)(field);
			
			setValueOfField!(FieldType, ThisType, field)(this, value);
		}
	}
}

template NonSerialized (alias field)
{
	NonSerializedField!(field) __nonSerialized;
}

struct NonSerializedField (alias f)
{
	const field = f.stringof;
}

package const nonSerializedField = "__nonSerialized";
package const serializedField = "__serialized";
package const internalFields = [nonSerializedField[], onDeserializedField, onDeserializingField, onSerializedField, onSerializingField];