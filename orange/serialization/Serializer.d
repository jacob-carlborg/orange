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

import orange.core._;
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
	
	private char toUpper (char c)
	{
		if (c >= 'a' && c <= 'z')
			return c - 32;

		return c;
	}
}

class Serializer
{
	alias void delegate (ArchiveException exception, string[] data) ErrorCallback;
	alias UntypedData Data;
	alias size_t Id;
	
	private
	{
		struct ValueMeta
		{
			Id id;
			string key;
		}
		
		ErrorCallback errorCallback_;		
		Archive archive;
		
		size_t keyCounter;
		Id idCounter;
		
		RegisterBase[string] serializers;
		RegisterBase[string] deserializers;
		
		Id[void*] serializedReferences;
		void*[Id] deserializedReferences;
		
		Array[Id] serializedArrays;
		void[][Id] deserializedSlices;
		
		void*[Id] serializedPointers;
		void**[Id] deserializedPointers;
		
		ValueMeta[void*] serializedValues;
		void*[Id] deserializedValues;
		
		bool hasBegunSerializing;
		bool hasBegunDeserializing;
		
		void delegate (ArchiveException exception, string[] data) throwOnErrorCallback;		
		void delegate (ArchiveException exception, string[] data) doNothingOnErrorCallback;
	}
	
	this (Archive archive)
	{
		this.archive = archive;
		
		throwOnErrorCallback = (ArchiveException exception, string[] data) { throw exception; };
		doNothingOnErrorCallback = (ArchiveException exception, string[] data) { /* do nothing */ };
		
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
	
	void reset ()
	{
		resetCounters();
		
		serializers = null;
		deserializers = null;
		
		serializedReferences = null;
		deserializedReferences = null;
		
		serializedArrays = null;
		deserializedSlices = null;
		
		serializedValues = null;
		serializedPointers = null;
		
		hasBegunSerializing = false;
		hasBegunDeserializing = false;
		
		archive.reset;
	}
	
	Data serialize (T) (T value, string key = null)
	{
		if (!hasBegunSerializing)
			hasBegunSerializing = true;
		
		serializeInternal(value, key);
		postProcess;

		return archive.untypedData;
	}
	
	private void serializeInternal (T) (T value, string key = null, Id id = Id.max)
	{
		if (!key)
			key = nextKey;

		if (id == Id.max)
			id = nextId;

		archive.beginArchiving();

		static if ( is(T == typedef) )
			serializeTypedef(value, key, id);
		
		else static if (isObject!(T))
			serializeObject(value, key, id);

		else static if (isStruct!(T))
			serializeStruct(value, key, id);

		else static if (isString!(T))
			serializeString(value, key, id);
		
		else static if (isArray!(T))
			serializeArray(value, key, id);

		else static if (isAssociativeArray!(T))
			serializeAssociativeArray(value, key, id);

		else static if (isPrimitive!(T))
			serializePrimitive(value, key, id);

		else static if (isPointer!(T))
		{
			static if (isFunctionPointer!(T))
				goto error;
				
			else
				serializePointer(value, key, id);
		}
		
		else static if (isEnum!(T))
			serializeEnum(value, key, id);
		
		else
		{
			error:
			throw new SerializationException(format!(`The type "`, T, `" cannot be serialized.`), __FILE__, __LINE__);
		}
	}

	private void serializeObject (T) (T value, string key, Id id)
	{
		if (!value)
			return archive.archiveNull(T.stringof, key);
		
		auto reference = getSerializedReference(value);
		
		if (reference != Id.max)
			return archive.archiveReference(key, reference);
		
		auto runtimeType = value.classinfo.name;
		
		addSerializedReference(value, id);

		triggerEvents(serializing, value, {			
			archive.archiveObject(runtimeType, T.stringof, key, id, {
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
	
	private void serializeStruct (T) (T value, string key, Id id)
	{			
		string type = T.stringof;
		
		triggerEvents(serializing, value, {
			archive.archiveStruct(type, key, id, {
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
	
	private void serializeString (T) (T value, string key, Id id)
	{
		auto array = Array(value.ptr, value.length, ElementTypeOfArray!(T).sizeof);
		
		archive.archive(value, key, id);			
		addSerializedArray(array, id);
	}
	
	private void serializeArray (T) (T value, string key, Id id)
	{
		auto array = Array(value.ptr, value.length, ElementTypeOfArray!(T).sizeof);

		archive.archiveArray(array, arrayToString!(T), key, id, {
			foreach (i, e ; value)
				serializeInternal(e, toData(i));
		});
		
		addSerializedArray(array, id);
	}
	
	private void serializeAssociativeArray (T) (T value, string key, Id id)
	{
		auto reference = getSerializedReference(value);
		
		if (reference != Id.max)
			return archive.archiveReference(key, reference);

		addSerializedReference(value, id);
		
		string keyType = KeyTypeOfAssociativeArray!(T).stringof;
		string valueType = ValueTypeOfAssociativeArray!(T).stringof;
		
		archive.archiveAssociativeArray(keyType, valueType, value.length, key, id, {
			size_t i;
			
			foreach(k, v ; value)
			{
				archive.archiveAssociativeArrayKey(toData(i), {
					serializeInternal(k, toData(i));
				});
				
				archive.archiveAssociativeArrayValue(toData(i), {
					serializeInternal(v, toData(i));
				});
				
				i++;
			}
		});
	}
	
	private void serializePointer (T) (T value, string key, Id id)
	{
		if (!value)
			return archive.archiveNull(T.stringof, key);
		
		auto reference = getSerializedReference(value);
		
		if (reference != Id.max)
			return archive.archiveReference(key, reference);

		addSerializedReference(value, id);

		archive.archivePointer(key, id, {
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
					serializeInternal(*value, nextKey);
			}
		});
		
		addSerializedPointer(value, id);
	}
	
	private void serializeEnum (T) (T value, string key, Id id)
	{
		alias BaseTypeOfEnum!(T) EnumBaseType;
		auto val = cast(EnumBaseType) value;
		string type = T.stringof;
		
		archive.archiveEnum(val, type, key, id);
	}
	
	private void serializePrimitive (T) (T value, string key, Id id)
	{
		archive.archive(value, key, id);
	}
	
	private void serializeTypedef (T) (T value, string key, Id id)
	{
		archive.archiveTypedef(T.stringof, key, nextId, {
			serializeInternal!(BaseTypeOfTypedef!(T))(value, nextKey);
		});
	}
	
	T deserialize (T) (Data data, string key = null)
	{		
		if (hasBegunSerializing && !hasBegunDeserializing)
			resetCounters();
		
		if (!hasBegunDeserializing)
			hasBegunDeserializing = true;
		
		if (!key)
			key = nextKey;

		archive.beginUnarchiving(data);
		auto value = deserializeInternal!(T)(key);
		deserializingPostProcess;
		
		return value;
	}
	
	private T deserializeInternal (T, U) (U keyOrId)
	{		
		static if (isTypedef!(T))
			return deserializeTypedef!(T)(keyOrId);

		else static if (isObject!(T))
			return deserializeObject!(T)(keyOrId);

		else static if (isStruct!(T))
			return deserializeStruct!(T)(keyOrId);

		else static if (isString!(T))
			return deserializeString!(T)(keyOrId);

		else static if (isArray!(T))
			return deserializeArray!(T)(keyOrId);

		else static if (isAssociativeArray!(T))
			return deserializeAssociativeArray!(T)(keyOrId);

		else static if (isPrimitive!(T))
			return deserializePrimitive!(T)(keyOrId);

		else static if (isPointer!(T))
		{			
			static if (isFunctionPointer!(T))
				goto error;
			Id id;
			return deserializePointer!(T)(keyOrId, id);
		}		

		else static if (isEnum!(T))
			return deserializeEnum!(T)(keyOrId);

		else
		{
			error:
			throw new SerializationException(format!(`The type "`, T, `" cannot be deserialized.`), __FILE__, __LINE__);
		}			
	}
	
	private T deserializeObject (T, U) (U keyOrId)
	{
		auto id = deserializeReference(keyOrId);

		if (auto reference = getDeserializedReference!(T)(id))
			return *reference;

		T value;
		Object val = value;
		nextId;
		
		archive.unarchiveObject(keyOrId, id, val, {
			triggerEvents(deserializing, value, {
				value = cast(T) val;
				auto runtimeType = value.classinfo.name;
				
				if (runtimeType in deserializers)
				{
					auto wrapper = getDeserializerWrapper!(T)(runtimeType);
					wrapper(value, this, keyOrId);
				}
				
				else static if (isSerializable!(T, Serializer))
					value.fromData(this, keyOrId);
				
				else
				{
					if (isBaseClass(value))
						throw new SerializationException(`The object of the static type "` ~ T.stringof ~ `" have a different runtime type (` ~ runtimeType ~ `) and therefore needs to register a deserializer for its type "` ~ runtimeType ~ `".`, __FILE__, __LINE__);

					objectStructDeserializeHelper(value);					
				}
			});
		});
		
		addDeserializedReference(value, id);
		
		return value;
	}
	
	private T deserializeStruct (T) (string key)
	{
		T value;
		nextId;
		
		archive.unarchiveStruct(key, {			
			triggerEvents(deserializing, value, {
				auto type = toData(T.stringof);
				
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
		});
		
		return value;
	}
	
	private T deserializeString (T) (string key)
	{
		auto slice = deserializeSlice(key);

		if (auto tmp = getDeserializedSlice!(T)(slice))
			return *tmp;
		
		T value;
		
		if (slice.id != size_t.max)
		{
			static if (is(T == string))
				value = archive.unarchiveString(slice.id).toSlice(slice);
			
			else static if (is(T == wstring))
				value = archive.unarchiveWstring(slice.id).toSlice(slice);
			
			else static if (is(T == dstring))
				value = archive.unarchiveDstring(slice.id).toSlice(slice);
		}
		
		else
		{
			static if (is(T == string))
				value = archive.unarchiveString(key, slice.id);
			
			else static if (is(T == wstring))
				value = archive.unarchiveWstring(key, slice.id);
			
			else static if (is(T == dstring))
				value = archive.unarchiveDstring(key, slice.id);
		}		

		addDeserializedSlice(value, slice.id);
		
		return value;
	}
	
	private T deserializeArray (T) (string key)
	{
		auto slice = deserializeSlice(key);
		
		if (auto tmp = getDeserializedSlice!(T)(slice))
			return *tmp;
		
		T value;
		
		auto dg = (size_t length) {
			value.length = length;
			
			foreach (i, ref e ; value)
				e = deserializeInternal!(typeof(e))(toData(i));
		};
		
		if (slice.id != size_t.max)
		{
			archive.unarchiveArray(slice.id, dg);
			addDeserializedSlice(value, slice.id);
			
			return value.toSlice(slice);
		}			
		
		else
		{
			slice.id = archive.unarchiveArray(key, dg);
			
			if (auto a = slice.id in deserializedSlices)
				return cast(T) *a;
			
			addDeserializedSlice(value, slice.id);
			
			return value;
		}
	}
	
	private T deserializeAssociativeArray (T) (string key)
	{
		auto id = deserializeReference(key);
		
		if (auto reference = getDeserializedReference!(T)(id))
			return *reference;
		
		T value;
		
		alias KeyTypeOfAssociativeArray!(T) Key;
		alias ValueTypeOfAssociativeArray!(T) Value;
		
		id = archive.unarchiveAssociativeArray(key, (size_t length) {
			for (size_t i = 0; i < length; i++)
			{
				Key aaKey;
				Value aaValue;
				auto k = toData(i);
				
				archive.unarchiveAssociativeArrayKey(k, {
					aaKey = deserializeInternal!(Key)(k);
				});
				
				archive.unarchiveAssociativeArrayValue(k, {
					aaValue = deserializeInternal!(Value)(k);
				});
				
				value[aaKey] = aaValue;
			}
		});
		
		addDeserializedReference(value, id);
		
		return value;
	}
	
	private T deserializePointer (T) (string key, out Id id)
	{
		id = deserializeReference(key);

		if (auto reference = getDeserializedReference!(T)(id))
			return *reference;
		
		T value = new BaseTypeOfPointer!(T);
		
		auto pointerId = archive.unarchivePointer(key, {
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
				{
					auto k = nextKey;
					id = deserializeReference(k);

					if (id != Id.max)
						return;

					*value = deserializeInternal!(BaseTypeOfPointer!(T))(k);
				}
			}
		});

		addDeserializedReference(value, pointerId);

		return value;
	}
	
	private T deserializeEnum (T) (string key)
	{
		alias BaseTypeOfEnum!(T) Enum;

		const functionName = toUpper(Enum.stringof[0]) ~ Enum.stringof[1 .. $];
		mixin("return cast(T) archive.unarchiveEnum" ~ functionName ~ "(key);");
	}
	
	private T deserializePrimitive (T, U) (U keyOrId)
	{
		const functionName = toUpper(T.stringof[0]) ~ T.stringof[1 .. $];
		mixin("return archive.unarchive" ~ functionName ~ "(keyOrId);");
	}
	
	private T deserializeTypedef (T, U) (U keyOrId)
	{
		T value;
		
		archive.unarchiveTypedef!(T)(key, {
			value = cast(T) deserializeInternal!(BaseTypeOfTypedef!(T))(nextKey);
		});
		
		return value;
	}
	
	private Id deserializeReference (string key)
	{
		return archive.unarchiveReference(key);
	}
	
	private Slice deserializeSlice (string key)
	{
		return archive.unarchiveSlice(key);
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
				auto id = nextId;

				addSerializedValue(value.tupleof[i], id, toData(keyCounter));
				serializeInternal(v, toData(field), id);
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
				
				static if (isPointer!(Type))
				{
					Id id;
					value.tupleof[i] = deserializePointer!(Type)(toData(field), id);
					addDeserializedPointer(value.tupleof[i], id);
				}
				
				else
				{
					auto fieldValue = deserializeInternal!(Type)(toData(field));
					value.tupleof[i] = fieldValue;
				}

				addDeserializedValue(value.tupleof[i], nextId);
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
	
	private void addSerializedReference (T) (T value, Id id)
	{
		static assert(isReference!(T) || isAssociativeArray!(T), format!(`The given type "`, T, `" is not a reference type, i.e. object, pointer or associative array.`));
		
		serializedReferences[cast(void*) value] = id;
	}
	
	private void addDeserializedReference (T) (T value, Id id)
	{
		static assert(isReference!(T) || isAssociativeArray!(T), format!(`The given type "`, T, `" is not a reference type, i.e. object, pointer or associative array.`));
		
		deserializedReferences[id] = cast(void*) value;
	}
	
	private void addDeserializedSlice (T) (T value, Id id)
	{
		static assert(isArray!(T) || isString!(T), format!(`The given type "`, T, `" is not a slice type, i.e. array or string.`));

		deserializedSlices[id] = value;
	}
	
	private void addSerializedValue (T) (ref T value, Id id, string key)
	{
		serializedValues[&value] = ValueMeta(id, key);
	}
	
	private void addDeserializedValue (T) (ref T value, Id id)
	{
		deserializedValues[id] = &value;
	}
	
	private void addSerializedPointer (T) (T value, Id id)
	{
		serializedPointers[id] = value;
	}
	
	private void addDeserializedPointer (T) (ref T value, Id id)
	{
		deserializedPointers[id] = cast(void**) &value;
	}
	
	private Id getSerializedReference (T) (T value)
	{
		if (auto tmp = cast(void*) value in serializedReferences)
			return *tmp;
		
		return Id.max;
	}
	
	private T* getDeserializedReference (T) (Id id)
	{
		if (auto reference = id in deserializedReferences)
			return cast(T*) reference;
		
		return null;
	}
	
	private T* getDeserializedSlice (T) (Slice slice)
	{
		if (auto array = slice.id in deserializedSlices)
			return &(cast(T) *array)[slice.offset .. slice.offset + slice.length]; // dereference the array, cast it to the right type, 
																				   // slice it and then return a pointer to the result
		return null;		
	}
	
	private T* getDeserializedArray (T) (Id id)
	{
		if (auto array = id in deserializedSlices)
			return cast(T*) array;
	}
	
	private T* getDeserializedValue (T) (Id id)
	{
		if (auto value = id in deserializedValues)
			return cast(T*) value;
		
		return null;
	}
	
	private T[] toSlice (T) (T[] array, Slice slice)
	{
		return array[slice.offset .. slice.offset + slice.length];
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
	
	private void addSerializedArray (Array array, Id id)
	{
		serializedArrays[id] = array;
	}
	
	private void postProcess ()
	{
		postProcessArrays();
		postProcessPointers();
	}
	
	private void postProcessArrays ()
	{
		bool foundSlice = true;
		
		foreach (sliceKey, slice ; serializedArrays)
		{
			foreach (arrayKey, array ; serializedArrays)
			{
				if (slice.isSliceOf(array) && slice != array)
				{
					auto s = Slice(slice.length, (slice.ptr - array.ptr) / slice.elementSize);
					archive.archiveSlice(s, sliceKey, arrayKey);
					foundSlice = true;
					break;
				}
				
				else
					foundSlice = false;
			}
			
			if (!foundSlice)
				archive.postProcessArray(sliceKey);
		}
	}
	
	private void postProcessPointers ()
	{
		foreach (pointerId, value ; serializedPointers)
		{
			if (auto valueMeta = value in serializedValues)
				archive.archivePointer(valueMeta.id, valueMeta.key, pointerId);
			
			else
				archive.postProcessPointer(pointerId);
		}
	}
	
	private void deserializingPostProcess ()
	{
		deserializingPostProcessPointers;
	}
	
	private void deserializingPostProcessPointers ()
	{
		foreach (pointeeId, pointee ; deserializedValues)
		{
			if (auto pointer = pointeeId in deserializedPointers)
				**pointer = pointee;
		}
	}
	
	private template arrayToString (T)
	{
		const arrayToString = ElementTypeOfArray!(T).stringof;
	}
	
	private bool isBaseClass (T) (T value)
	{
		auto name = value.classinfo.name;		
		auto index = name.lastIndexOf('.');
		
		return T.stringof != name[index + 1 .. $];
	}
	
	private Id nextId ()
	{
		return idCounter++;
	}
	
	private string nextKey ()
	{
		return toData(keyCounter++);
	}
	
	private string prevKey ()
	{
		return toData(--keyCounter);
	}
	
	private void resetCounters ()
	{
		keyCounter = 0;
		idCounter = 0;
	}
	
	private string toData (T) (T value)
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