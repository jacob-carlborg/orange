/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.Serializer;

version (Tango)
	import tango.util.Convert : to, ConversionException;

else
{
	import std.conv;
	alias ConvError ConversionException;
}

import orange.serialization._;
import orange.serialization.archives._;
import orange.util._;

private
{
	alias orange.util.CTFE.contains ctfeContains;
	
	private enum Mode
	{
		serializing,
		deserializing
	}
	
	alias Mode.serializing serializing;
	alias Mode.deserializing deserializing;
}

class Serializer (ArchiveType : IArchive)
{
	static assert(isArchive!(ArchiveType), format!(`The type "`, ArchiveType, `" does not implement the necessary methods to be an archive.`));
	
	alias ArchiveType.ErrorCallback ErrorCallback;
	alias ArchiveType.DataType DataType;
	
	private
	{
		ArchiveType archive;
		
		RegisterBase[string] serializers;
		RegisterBase[string] deserializers;
		
		size_t keyCounter;
		
		bool hasBegunSerializing;
		bool hasBegunDeserializing;
		
		void delegate (ArchiveException exception, DataType[] data) throwOnErrorCallback;		
		void delegate (ArchiveException exception, DataType[] data) doNothingOnErrorCallback;
	}
	
	this ()
	{
		archive = new ArchiveType;
		
		throwOnErrorCallback = (ArchiveException exception, DataType[] data) { throw exception; };
		doNothingOnErrorCallback = (ArchiveException exception, DataType[] data) { /* do nothing */ };
		
		setThrowOnErrorCallback();
	}

	void registerSerializer (T) (string type, void delegate (T, Serializer, DataType) dg)
	{		
		serializers[type] = toSerializeRegisterWrapper(dg);
	}

	void registerSerializer (T) (string type, void function (T, Serializer, DataType) func)
	{		
		serializers[type] = toSerializeRegisterWrapper(func);
	}

	void registerDeserializer (T) (string type, void delegate (ref T, Serializer, DataType) dg)
	{		
		deserializers[type] = toDeserializeRegisterWrapper(dg);
	}

	void registerDeserializer (T) (string type, void function (ref T, Serializer, DataType) func)
	{		
		deserializers[type] = toDeserializeRegisterWrapper(func);
	}
	
	void reset ()
	{
		hasBegunSerializing = false;
		hasBegunDeserializing = false;
		resetCounters();
		
		archive.reset;
	}
	
	ErrorCallback errorCallback ()
	{
		return archive.errorCallback;
	}
	
	ErrorCallback errorCallback (ErrorCallback errorCallback)
	{
		return archive.errorCallback = errorCallback;
	}
	
	void setThrowOnErrorCallback ()
	{
		errorCallback = throwOnErrorCallback;
	}
	
	void setDoNothingOnErrorCallback ()
	{
		errorCallback = doNothingOnErrorCallback;
	}
	
	DataType serialize (T) (T value, DataType key = null)
	{
		if (!hasBegunSerializing)
			hasBegunSerializing = true;
		
		if (!key)
			key = nextKey;
		
		archive.beginArchiving();
		
		static if (isTypeDef!(T))
			serializeTypeDef(value, key);
		
		static if (isObject!(T))
			serializeObject(value, key);

		else static if (isStruct!(T))
			serializeStruct(value, key);

		else static if (isString!(T))
			serializeString(value, key);
		
		else static if (isArray!(T))
			serializeArray(value, key);

		else static if (isAssociativeArray!(T))
			serializeAssociativeArray(value, key);

		else static if (isPrimitive!(T))
			serializePrimitive(value, key);

		else static if (isPointer!(T))
		{
			static if (isFunctionPointer!(T))
				goto error;
				
			else
				serializePointer(value, key);
		}			
		
		else static if (isEnum!(T))
			serializeEnum(value, key);
		
		else
		{
			error:
			throw new SerializationException(format!(`The type "`, T, `" cannot be serialized.`), __FILE__, __LINE__);
		}
		
		return archive.data;
	}
	
	private void serializeObject (T) (T value, DataType key)
	{			
		triggerEvents(serializing, value, {
			archive.archive(value, key, {
				auto runtimeType = value.classinfo.name;

				if (runtimeType in serializers)
				{
					auto wrapper = getSerializerWrapper!(T)(runtimeType);
					wrapper(value, this, key);
				}
				
				else static if (isSerializable!(T, Serializer))
					value.toData(this, key);
				
				else
				{				
					if (isBaseClass(value))
						throw new SerializationException(`The object of the static type "` ~ T.stringof ~ `" have a different runtime type (` ~ runtimeType ~ `) and therefore needs to register a serializer for its type "` ~ runtimeType ~ `".`, __FILE__, __LINE__);
				
					objectStructSerializeHelper(value);
				}
			});
		});
	}

	private void serializeStruct (T) (T value, DataType key)
	{		
		triggerEvents(serializing, value, {
			archive.archive(value, key, {
				auto type = toDataType(T.stringof);
				
				if (type in serializers)
				{
					auto wrapper = getSerializerWrapper!(T)(type);
					wrapper(value, this, key);
				}
				
				else
				{
					static if (isSerializable!(T, Serializer))
						value.toData(this, key);
					
					else
						objectStructSerializeHelper(value);
				}
			});
		});
	}
	
	private void serializeString (T) (T value, DataType key)
	{
		archive.archive(value, key);
	}

	private void serializeArray (T) (T value, DataType key)
	{		
		archive.archive(value, key, {
			foreach (i, e ; value)
				serialize(e, toDataType(i));
		});
	}

	private void serializeAssociativeArray (T) (T value, DataType key)
	{
		archive.archive(value, key, {
			foreach(k, v ; value)
				serialize(v, toDataType(k));
		});
	}

	private void serializePointer (T) (T value, DataType key)
	{
		archive.archive(value, key, {
			if (key in serializers)
			{
				auto wrapper = getSerializerWrapper!(T)(key);
				wrapper(value, this, key);
			}
			
			else static if (isSerializable!(T, Serializer))
				value.toData(this, key);
			
			else
			{
				static if (isVoid!(BaseTypeOfPointer!(T)))
					throw new SerializationException(`The value with the key "` ~ to!(string)(key) ~ `"` ~ format!(` of the type "`, T, `" cannot be serialized on its own, either implement orange.serialization.Serializable.isSerializable or register a serializer.`), __FILE__, __LINE__);
				
				else
					serialize(*value, key);
			}				
		});
	}
	
	private void serializeEnum (T) (T value, DataType key)
	{
		archive.archive(value, key);
	}

	private void serializePrimitive (T) (T value, DataType key)
	{		
		archive.archive(value, key);
	}
	
	private void serializeTypeDef (T) (T value, DataType key)
	{
		archive.archive(value, key, {
			serialize!(BaseTypeOfTypeDef!(T))(value, key);
		});
	}
	
	T deserialize (T) (DataType data, DataType key = null)
	{		
		if (hasBegunSerializing && !hasBegunDeserializing)
			resetCounters();
		
		if (!hasBegunDeserializing)
			hasBegunDeserializing = true;
		
		if (!key)
			key = nextKey;
		
		archive.beginUnarchiving(data);
		return deserializeInternal!(T)(key);
	}
	
	private T deserializeInternal (T) (DataType key)
	{
		static if (isTypeDef!(T))
			return deserializeTypeDef!(T)(key);
		
		else static if (isObject!(T))
			return deserializeObject!(T)(key);

		else static if (isStruct!(T))
			return deserializeStruct!(T)(key);

		else static if (isString!(T))
			return deserializeString!(T)(key);
		
		else static if (isArray!(T))
			return deserializeArray!(T)(key);

		else static if (isAssociativeArray!(T))
			return deserializeAssociativeArray!(T)(key);

		else static if (isPrimitive!(T))
			return deserializePrimitive!(T)(key);

		else static if (isPointer!(T))
		{			
			static if (isFunctionPointer!(T))
				goto error;
			
			return deserializePointer!(T)(key);
		}		
		
		else static if (isEnum!(T))
			return deserializeEnum!(T)(key);
		
		else
		{
			error:
			throw new SerializationException(format!(`The type "`, T, `" cannot be deserialized.`), __FILE__, __LINE__);
		}			
	}

	private T deserializeObject (T) (DataType key)
	{		
		T value = archive.unarchive!(T)(key, (T value) {			
			triggerEvents(deserializing, value, {
				auto runtimeType = value.classinfo.name;
				
				if (runtimeType in deserializers)
				{
					auto wrapper = getDeserializerWrapper!(T)(runtimeType);
					wrapper(value, this, key);
				}
				
				else static if (isSerializable!(T, Serializer))
					value.fromData(this, key);
				
				else
				{
					if (isBaseClass(value))
						throw new SerializationException(`The object of the static type "` ~ T.stringof ~ `" have a different runtime type (` ~ runtimeType ~ `) and therefore needs to register a deserializer for its type "` ~ runtimeType ~ `".`, __FILE__, __LINE__);
					
					objectStructDeserializeHelper(value);					
				}
			});
			
			return value;
		});
		
		return value;
	}

	private T deserializeStruct (T) (DataType key)
	{		
		return archive.unarchive!(T)(key, (T value) {			
			triggerEvents(deserializing, value, {
				auto type = toDataType(T.stringof);
				
				if (type in deserializers)
				{
					auto wrapper = getDeserializerWrapper!(T)(type);
					wrapper(value, this, key);
				}
				
				else
				{
					static if (isSerializable!(T, Serializer))
						value.fromData(this, key);
					
					else
						objectStructDeserializeHelper(value);
				}	
			});
			
			return value;
		});
	}
	
	private T deserializeString (T) (DataType key)
	{
		return archive.unarchive!(T)(key);
	}

	private T deserializeArray (T) (DataType key)
	{
		return archive.unarchive!(T)(key, (T value) {
			foreach (i, ref e ; value)
				e = deserializeInternal!(typeof(e))(toDataType(i));
			
			return value;
		});	
	}

	private T deserializeAssociativeArray (T) (DataType key)
	{		
		return archive.unarchive!(T)(key, (T value) {			
			foreach (k, v ; archive.unarchiveAssociativeArrayVisitor!(T))
				value[k] = v;
			
			return value;
		});	
	}

	private T deserializePointer (T) (DataType key)
	{
		return archive.unarchive!(T)(key, (T value) {
			if (key in deserializers)
			{
				auto wrapper = getDeserializerWrapper!(T)(key);
				wrapper(value, this, key);
			}
			
			else static if (isSerializable!(T, Serializer))
				value.fromData(this, key);
			
			else
			{
				static if (isVoid!(BaseTypeOfPointer!(T)))
					throw new SerializationException(`The value with the key "` ~ to!(string)(key) ~ `"` ~ format!(` of the type "`, T, `" cannot be deserialized on its own, either implement orange.serialization.Serializable.isSerializable or register a deserializer.`), __FILE__, __LINE__);
				
				else
					*value = deserializeInternal!(BaseTypeOfPointer!(T))(key);
			}
			
			return value;
		});
	}
	
	private T deserializeEnum (T) (DataType key)
	{
		return archive.unarchive!(T)(key);
	}

	private T deserializePrimitive (T) (DataType key)
	{		
		return archive.unarchive!(T)(key);
	}
	
	private T deserializeTypeDef (T) (DataType key)
	{
		return archive.unarchive!(T)(key, (T value) {
			return deserializeInternal!(BaseTypeOfTypeDef!(T))(key);
		});
	}
	
	private void objectStructSerializeHelper (T) (ref T value)
	{
		static assert(isStruct!(T) || isObject!(T), format!(`The given value of the type "`, T, `" is not a valid type, the only valid types for this method are objects and structs.`));
		const nonSerializedFields = collectAnnotations!(nonSerializedField, T);
		
		foreach (i, dummy ; typeof(T.tupleof))
		{
			const field = nameOfFieldAt!(T, i);
			
			static if (!internalFields.ctfeContains(field) && !nonSerializedFields.ctfeContains(field))
			{
				alias typeof(T.tupleof[i]) Type;				
				Type v = value.tupleof[i];
				serialize(v, toDataType(field));
			}				
		}
		
		static if (isObject!(T) && !is(T == Object))
			serializeBaseTypes(value);
	}
	
	private void objectStructDeserializeHelper (T) (ref T value)
	{		
		static assert(isStruct!(T) || isObject!(T), format!(`The given value of the type "`, T, `" is not a valid type, the only valid types for this method are objects and structs.`));
		const nonSerializedFields = collectAnnotations!(nonSerializedField, T);
		
		foreach (i, dummy ; typeof(T.tupleof))
		{
			const field = nameOfFieldAt!(T, i);
						
			static if (!internalFields.ctfeContains(field) && !nonSerializedFields.ctfeContains(field))
			{
				alias TypeOfField!(T, field) Type;
				auto fieldValue = deserializeInternal!(Type)(toDataType(field));
				value.tupleof[i] = fieldValue;
			}			
		}
		
		static if (isObject!(T) && !is(T == Object))
			deserializeBaseTypes(value);
	}
	
	private void serializeBaseTypes (T : Object) (T value)
	{
		alias BaseTypeTupleOf!(T)[0] Base;
		
		static if (!is(Base == Object))
		{
			archive.archiveBaseClass!(Base)(nextKey);
			Base base = value;
			objectStructSerializeHelper(base);
		}
	}
	
	private void deserializeBaseTypes (T : Object) (T value)
	{
		alias BaseTypeTupleOf!(T)[0] Base;
		
		static if (!is(Base == Object))
		{
			archive.unarchiveBaseClass!(Base)(nextKey);
			Base base = value;
			objectStructDeserializeHelper(base);
		}
	}
	
	private SerializeRegisterWrapper!(T, Serializer) getSerializerWrapper (T) (string type)
	{
		auto wrapper = cast(SerializeRegisterWrapper!(T, Serializer)) serializers[type];
		
		if (wrapper)
			return wrapper;
		
		assert(false, "throw exception here");
	}

	private DeserializeRegisterWrapper!(T, Serializer) getDeserializerWrapper (T) (string type)
	{
		auto wrapper = cast(DeserializeRegisterWrapper!(T, Serializer)) deserializers[type];
		
		if (wrapper)
			return wrapper;
		
		assert(false, "throw exception here");
	}
	
	private SerializeRegisterWrapper!(T, Serializer) toSerializeRegisterWrapper (T) (void delegate (T, Serializer, DataType) dg)
	{		
		return new SerializeRegisterWrapper!(T, Serializer)(dg);
	}

	private SerializeRegisterWrapper!(T, Serializer) toSerializeRegisterWrapper (T) (void function (T, Serializer, DataType) func)
	{		
		return new SerializeRegisterWrapper!(T, Serializer)(func);
	}

	private DeserializeRegisterWrapper!(T, Serializer) toDeserializeRegisterWrapper (T) (void delegate (ref T, Serializer, DataType) dg)
	{		
		return new DeserializeRegisterWrapper!(T, Serializer)(dg);
	}

	private DeserializeRegisterWrapper!(T, Serializer) toDeserializeRegisterWrapper (T) (void function (ref T, Serializer, DataType) func)
	{		
		return new DeserializeRegisterWrapper!(T, Serializer)(func);
	}
	
	private DataType toDataType (T) (T value)
	{
		try
			return to!(DataType)(value);
		
		catch (ConversionException e)
			throw new SerializationException(e);
	}
	
	private bool isBaseClass (T) (T value)
	{
		auto name = value.classinfo.name;		
		auto index = name.lastIndexOf('.');
		
		return T.stringof != name[index + 1 .. $];
	}
	
	private DataType nextKey ()
	{
		return toDataType(keyCounter++);
	}
	
	private void resetCounters ()
	{
		keyCounter = 0;
	}
	
	private void triggerEvent (string name, T) (T value)
	{
		static assert (isObject!(T) || isStruct!(T), format!(`The given value of the type "`, T, `" is not a valid type, the only valid types for this method are objects and structs.`));
		
		foreach (i, dummy ; typeof(T.tupleof))
		{
			const field = nameOfFieldAt!(T, i);
			
			static if (field == name)
			{
				alias TypeOfField!(T, field) Type;
				auto event = getValueOfField!(T, Type, field)(value);
				event(value);
			}
		}
	}
	
	private void triggerEvents (T) (Mode mode, T value, void delegate () dg)
	{
		if (mode == serializing)
			triggerEvent!(onSerializingField)(value);
		
		else
			triggerEvent!(onDeserializingField)(value);
		
		dg();
		
		if (mode == serializing)
			triggerEvent!(onSerializedField)(value);
		
		else
			triggerEvent!(onDeserializedField)(value);
	}
	
	private static string[] collectAnnotations (string name, T) ()
	{
		static assert (isObject!(T) || isStruct!(T), format!(`The given value of the type "`, T, `" is not a valid type, the only valid types for this method are objects and structs.`));
		
		string[] annotations;
		
		foreach (i, type ; typeof(T.tupleof))
		{
			const field = nameOfFieldAt!(T, i);
			
			static if (field == name)
				annotations ~= type.field;
		}
		
		return annotations;
	}
}