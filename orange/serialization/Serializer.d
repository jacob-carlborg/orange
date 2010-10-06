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

	enum Mode
	{
		serializing,
		deserializing
	}
	
	alias Mode.serializing serializing;
	alias Mode.deserializing deserializing;
}

class Serializer
{
	alias void delegate (ArchiveException exception, IArchive.IDataType data) ErrorCallback;
	alias IArchive.IDataType DataType;
	
	private
	{
		ErrorCallback errorCallback_;		
		IArchive archive;
		
		size_t keyCounter;
		size_t idCounter;
		
		RegisterBase[string] serializers;
		RegisterBase[string] deserializers;		
		
		bool hasBegunSerializing;
		bool hasBegunDeserializing;
		
		void delegate (ArchiveException exception, DataType data) throwOnErrorCallback;		
		void delegate (ArchiveException exception, DataType data) doNothingOnErrorCallback;
	}
	
	this (IArchive archive)
	{
		this.archive = archive;
		
		throwOnErrorCallback = (ArchiveException exception, IArchive.IDataType data) { throw exception; };
		doNothingOnErrorCallback = (ArchiveException exception, IArchive.IDataType data) { /* do nothing */ };
		
		setThrowOnErrorCallback();
	}
	
	ErrorCallback errorCallback ()
	{
		return errorCallback_;
	}
	
	ErrorCallback errorCallback (ErrorCallback errorCallback)
	{
		return errorCallback_ = errorCallback;
	}
	
	void setThrowOnErrorCallback ()
	{
		errorCallback = throwOnErrorCallback;
	}
	
	void setDoNothingOnErrorCallback ()
	{
		errorCallback = doNothingOnErrorCallback;
	}
	
	DataType serialize (T) (T value, string key = null)
	{
		if (!hasBegunSerializing)
			hasBegunSerializing = true;
		
		serializeInternal(value, key);
		archive.postProcess;

		return archive.data;
	}
	
	private void serializeInternal (T) (T value, string key = null)
	{
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
	}

	private void serializeObject (T) (T value, string key)
	{
		auto runtimeType = value.classinfo.name; 
		
		triggerEvents(serializing, value, {
			archive.archiveObject(runtimeType, T.stringof, key, nextId, {
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
		auto type = T.stringof;
		
		triggerEvents(serializing, value, {
			archive.archive(type, key, nextId, {				
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
	
	private void serializeString (T) (T value, string key)
	{
		archive.archive(value, key, nextId);
	}
	
	private void serializeArray (T) (T value, string key)
	{
		auto array = Array(value.ptr, value.length, BaseTypeOfArray!(T).sizeof);
		
		archive.archiveArray(array, arrayToString!(T), key, nextId, {
			foreach (i, e ; value)
				serializeInternal(e, toDataType(i));
		});
	}
	
	private void serializePrimitive (T) (T value, string key)
	{		
		archive.archive(value, key, nextId);
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
				serializeInternal(v, toDataType(field));
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
			archive.archiveBaseClass(Base.stringof, nextKey, nextId);
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
	
	private SerializeRegisterWrapper!(T, Serializer) toSerializeRegisterWrapper (T) (void delegate (T, Serializer, string) dg)
	{		
		return new SerializeRegisterWrapper!(T, Serializer)(dg);
	}

	private SerializeRegisterWrapper!(T, Serializer) toSerializeRegisterWrapper (T) (void function (T, Serializer, string) func)
	{		
		return new SerializeRegisterWrapper!(T, Serializer)(func);
	}

	private DeserializeRegisterWrapper!(T, Serializer) toDeserializeRegisterWrapper (T) (void delegate (ref T, Serializer, string) dg)
	{		
		return new DeserializeRegisterWrapper!(T, Serializer)(dg);
	}

	private DeserializeRegisterWrapper!(T, Serializer) toDeserializeRegisterWrapper (T) (void function (ref T, Serializer, string) func)
	{		
		return new DeserializeRegisterWrapper!(T, Serializer)(func);
	}
	
	private template arrayToString (T)
	{
		const arrayToString = BaseTypeOfArray!(T).stringof;
	}
	
	private bool isBaseClass (T) (T value)
	{
		auto name = value.classinfo.name;		
		auto index = name.lastIndexOf('.');
		
		return T.stringof != name[index + 1 .. $];
	}
	
	private size_t nextId ()
	{
		return idCounter++;
	}
	
	private string nextKey ()
	{
		return toDataType(keyCounter++);
	}
	
	private void resetCounters ()
	{
		keyCounter = 0;
		idCounter = 0;
	}
	
	private string toDataType (T) (T value)
	{
		return to!(string)(value);
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