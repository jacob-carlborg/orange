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
		ErrorCallback errorCallback_;		
		IArchive archive;
		
		size_t keyCounter;
		Id idCounter;
		
		RegisterBase[string] serializers;
		RegisterBase[string] deserializers;
		
		Id[void*] serializedReferences;
		void*[Id] deserializedReferences;
		
		Array[Id] serializedArrays;
		void[][Id] deserializedSlices;
		
		bool hasBegunSerializing;
		bool hasBegunDeserializing;
		
		void delegate (ArchiveException exception, string[] data) throwOnErrorCallback;		
		void delegate (ArchiveException exception, string[] data) doNothingOnErrorCallback;
	}
	
	this (IArchive archive)
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
	
	private void serializeInternal (T) (T value, string key = null)
	{
		if (!key)
			key = nextKey;
		
		archive.beginArchiving();
		
		static if ( is(T == typedef) )
			serializeTypedef(value, key);
		
		else static if (isObject!(T))
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
		if (!value)
			return archive.archiveNull(T.stringof, key);
		
		auto reference = getSerializedReference(value);
		
		if (reference != Id.max)
			return archive.archiveReference(key, reference);
		
		auto runtimeType = value.classinfo.name;
		
		Id id = nextId;
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
	
	private void serializeStruct (T) (T value, string key)
	{			
		string type = T.stringof;
		
		triggerEvents(serializing, value, {
			archive.archiveStruct(type, key, nextId, {
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
		auto id = nextId;
		auto array = Array(value.ptr, value.length, ElementTypeOfArray!(T).sizeof);
		
		archive.archive(value, key, id);			
		addSerializedArray(array, id);
	}
	
	private void serializeArray (T) (T value, string key)
	{
		auto array = Array(value.ptr, value.length, ElementTypeOfArray!(T).sizeof);
		auto id = nextId;

		archive.archiveArray(array, arrayToString!(T), key, id, {
			foreach (i, e ; value)
				serializeInternal(e, toData(i));
		});
		
		addSerializedArray(array, id);
	}
	
	private void serializeAssociativeArray (T) (T value, string key)
	{
		string keyType = KeyTypeOfAssociativeArray!(T).stringof;
		string valueType = ValueTypeOfAssociativeArray!(T).stringof;
		
		archive.archiveAssociativeArray(keyType, valueType, value.length, key, nextId, {
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
	
	private void serializePointer (T) (T value, string key)
	{
		if (!value)
			return archive.archiveNull(T.stringof, key);
		
		auto reference = getSerializedReference(value);
		
		if (reference != Id.max)
			return archive.archiveReference(key, reference);
		
		Id id = nextId;

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
	}
	
	private void serializeEnum (T) (T value, string key)
	{
		alias BaseTypeOfEnum!(T) EnumBaseType;
		auto val = cast(EnumBaseType) value;
		string type = T.stringof;
		
		archive.archiveEnum(val, type, key, nextId);
	}
	
	private void serializePrimitive (T) (T value, string key)
	{	
		archive.archive(value, key, nextId);
	}
	
	private void serializeTypedef (T) (T value, string key)
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
		return deserializeInternal!(T)(key);
	}
	
	private T deserializeInternal (T) (string key)
	{
		static if (isTypedef!(T))
			return deserializeTypedef!(T)(key);
		
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
	
	private T deserializeObject (T) (string key)
	{
		auto id = deserializeReference(key);
		
		if (auto reference = getDeserializedReference!(T)(id))
			return *reference;

		T value;
		Object val = value;
		
		archive.unarchiveObject(key, id, val, {
			triggerEvents(deserializing, value, {
				value = cast(T) val;
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
		});
		
		addDeserializedReference(value, id);
		
		return value;
	}
	
	private T deserializeStruct (T) (string key)
	{
		T value;
		
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
		T value;
		
		alias KeyTypeOfAssociativeArray!(T) Key;
		alias ValueTypeOfAssociativeArray!(T) Value;
		
		archive.unarchiveAssociativeArray(key, (size_t length) {
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
		
		return value;
	}
	
	/*			auto id = deserializeReference(key);
		
		if (auto reference = getDeserializedReference!(T)(id))
			return *reference;

		T value;
		Object val = value;
		
		archive.unarchiveObject(key, id, val, {
			triggerEvents(deserializing, value, {
				value = cast(T) val;
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
		});
		
		addDeserializedReference(value, id);
		
		return value;
	 */
	
	private T deserializePointer (T) (string key)
	{
		auto id = deserializeReference(key);
		
		if (auto reference = getDeserializedReference!(T)(id))
			return *reference;
		
		T value = new BaseTypeOfPointer!(T);
		
		id = archive.unarchivePointer(key, {
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
					*value = deserializeInternal!(BaseTypeOfPointer!(T))(nextKey);
			}
		});
		
		addDeserializedReference(value, id);
		
		return value;
	}
	
	private T deserializeEnum (T) (string key)
	{
		alias BaseTypeOfEnum!(T) Enum;

		const functionName = toUpper(Enum.stringof[0]) ~ Enum.stringof[1 .. $];
		mixin("return cast(T) archive.unarchiveEnum" ~ functionName ~ "(key);");
	}
	
	private T deserializePrimitive (T) (string key)
	{		
		const functionName = toUpper(T.stringof[0]) ~ T.stringof[1 .. $];
		mixin("return archive.unarchive" ~ functionName ~ "(key);");
	}
	
	private T deserializeTypedef (T) (string key)
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
				serializeInternal(v, toData(field));
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
				auto fieldValue = deserializeInternal!(Type)(toData(field));
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
	
	private void addSerializedReference (T) (T value, Id id)
	{
		static assert(isReference!(T), format!(`The given type "`, T, `" is not a reference type, i.e. object or pointer.`));
		
		serializedReferences[cast(void*) value] = id;
	}
	
	private void addDeserializedReference (T) (T value, Id id)
	{
		static assert(isReference!(T), format!(`The given type "`, T, `" is not a reference type, i.e. object or pointer.`));
		
		deserializedReferences[id] = cast(void*) value;
	}
	
	private void addDeserializedSlice (T) (T value, Id id)
	{
		static assert(isArray!(T) || isString!(T), format!(`The given type "`, T, `" is not a slice type, i.e. array or string.`));

		deserializedSlices[id] = value;
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
																		// slice it and then return a pointer to the result		}
		return null;		
	}
	
	private T* getDeserializedArray (T) (Id id)
	{
		if (auto array = id in deserializedSlices)
			return cast(T*) array;
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
	
	private void postProcess ()
	{
		postProcessArrays();
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



debug (OrangeUnitTest)
{
	import orange.serialization.archives.XMLArchive;

	enum Foo { a, b, c }
	typedef int Int;
	
	class A {}
	struct B {}
	class C { string str; }
	class D { int[] arr; }
	class E { int[int] aa; }
	class F { int value; int* ptr; }
	class G { Foo foo; }
	
	class H
	{
		bool bool_;
		byte byte_;
		//cdouble cdouble_; // currently not suppported by to!()
		//cent cent_; // currently not implemented but a reserved keyword
		//cfloat cfloat_; // currently not suppported by to!()
		char char_;
		//creal creal_; // currently not suppported by to!()
		dchar dchar_;
		double double_;
		float float_;
		//idouble idouble_; // currently not suppported by to!()
		//ifloat ifloat_; // currently not suppported by to!()
		int int_;
		//ireal ireal_;  // currently not suppported by to!()
		long long_;
		real real_;
		short short_;
		ubyte ubyte_;
		//ucent ucent_; // currently not implemented but a reserved keyword
		uint uint_;
		ulong ulong_;
		ushort ushort_;
		wchar wchar_;
		
		equals_t opEquals (Object other)
		{
			if (auto o =  cast(H) other)
			{
				return bool_ == o.bool_ &&
					   byte_ == o.byte_ &&
					   //cdouble_ == o.cdouble_ && // currently not suppported by to!()
					   //cent_ == o.cent_ && // currently not implemented but a reserved keyword
					   //cfloat_ == o.cfloat_ && // currently not suppported by to!()
					   char_ == o.char_ &&
					   //creal_ == o.creal_ && // currently not suppported by to!()
					   dchar_ == o.dchar_ &&
					   double_ == o.double_ &&
					   float_ == o.float_ &&
					   //idouble_ == o.idouble_ && // currently not suppported by to!()
					   //ifloat_ == o.ifloat_ && // currently not suppported by to!()
					   int_ == o.int_ &&
					   //ireal_ == o.ireal_ &&  // currently not suppported by to!()
					   long_ == o.long_ &&
					   real_ == o.real_ &&
					   short_ == o.short_ &&
					   ubyte_ == o.ubyte_ &&
					   //ucent_ == o.ucent_ && // currently not implemented but a reserved keyword
					   uint_ == o.uint_ &&
					   ulong_ == o.ulong_ &&
					   ushort_ == o.ushort_ &&
					   wchar_ == o.wchar_;
			}
			
			return false;
		}
	}
	
	class I
	{
		Int a;
	}
	
	void main ()
	{
		auto archive = new XMLArchive!(char);
		auto serializer = new Serializer(archive);
		string data;
		
		void serializeObject ()
		{
			serializer.reset;
			data = `<?xml version="1.0" encoding="UTF-8"?>
<archive type="org.dsource.orange.xml" version="1.0.0">
    <data>
        <struct type="B" key="0"/>
    </data>
</archive>`;
				
			serializer.serialize(B());
			assert(archive.data == data);
		}
		
		void serializeStruct ()
		{
			serializer.reset;
			data = `<?xml version="1.0" encoding="UTF-8"?>
<archive type="org.dsource.orange.xml" version="1.0.0">
    <data>
        <struct type="B" key="0"/>
    </data>
</archive>`;
				
			serializer.serialize(B());
			assert(archive.data == data);
		}
		
		// Struct
		

		
		// String
		
		serializer.reset;
		data = `<?xml version="1.0" encoding="UTF-8"?>
<archive type="org.dsource.orange.xml" version="1.0.0">
    <data>
        <object runtimeType="orange.serialization.Serializer.C" type="C" key="0" id="0">
            <string type="char" length="3" key="str" id="1">foo</string>
        </object>
    </data>
</archive>`;
		
		auto c = new C;
		c.str = "foo";
		serializer.serialize(c);
		assert(archive.data == data);
		
		// Deserializing
		
		auto cDeserialized = serializer.deserialize!(C)(data);
		assert(c.str == cDeserialized.str);
			
		// Array
	
		serializer.reset;
		data = `<?xml version="1.0" encoding="UTF-8"?>
<archive type="org.dsource.orange.xml" version="1.0.0">
    <data>
        <object runtimeType="orange.serialization.Serializer.D" type="D" key="0" id="0">
            <array type="int" length="6" key="arr" id="1">
                <int key="0">27</int>
                <int key="1">382</int>
                <int key="2">283</int>
                <int key="3">3820</int>
                <int key="4">32</int>
                <int key="5">832</int>
            </array>
        </object>
    </data>
</archive>`;
		
		auto d = new D;
		d.arr = [27, 382, 283, 3820, 32, 832];
		serializer.serialize(d);
		assert(archive.data == data);	
		
		// Deserializing
		
		auto dDeserialized = serializer.deserialize!(D)(data);
		assert(d.arr == dDeserialized.arr);
		
		// Associative Array
		
		serializer.reset();
		data = `<?xml version="1.0" encoding="UTF-8"?>
<archive type="org.dsource.orange.xml" version="1.0.0">
    <data>
        <object runtimeType="orange.serialization.Serializer.E" type="E" key="0" id="0">
            <associativeArray keyType="int" valueType="int" length="4" key="aa">
                <key key="0">
                    <int key="0">1</int>
                </key>
                <value key="0">
                    <int key="0">2</int>
                </value>
                <key key="1">
                    <int key="1">3</int>
                </key>
                <value key="1">
                    <int key="1">4</int>
                </value>
                <key key="2">
                    <int key="2">6</int>
                </key>
                <value key="2">
                    <int key="2">7</int>
                </value>
                <key key="3">
                    <int key="3">39</int>
                </key>
                <value key="3">
                    <int key="3">472</int>
                </value>
            </associativeArray>
        </object>
    </data>
</archive>`;
		
		auto e = new E;
		e.aa = [3 : 4, 1 : 2, 39 : 472, 6 : 7];
		serializer.serialize(e);
		assert(archive.data == data);
		
		// Deserializing
		
		auto eDeserialized = serializer.deserialize!(E)(data);
		//assert(e.aa == eDeserialized.aa); // cannot compare associative array

		// Pointer
		
		serializer.reset();
		data = `<?xml version="1.0" encoding="UTF-8"?>
<archive type="org.dsource.orange.xml" version="1.0.0">
    <data>
        <object runtimeType="orange.serialization.Serializer.F" type="F" key="0" id="0">
            <pointer key="ptr" id="2">
                <int key="1">9</int>
            </pointer>
            <int key="value">9</int>
        </object>
    </data>
</archive>`;
		
		auto f = new F;
		f.value = 9;
		f.ptr = &f.value;
		serializer.serialize(f);
		//assert(archive.data == data); // this is not a reliable comparison, the order of int and pointer is not reliable
		
		// Deserializing
		
		auto fDeserialized = serializer.deserialize!(F)(data);
		assert(*f.ptr == *fDeserialized.ptr);
		
		// Enum
		
		serializer.reset();
		data = `<?xml version="1.0" encoding="UTF-8"?>
<archive type="org.dsource.orange.xml" version="1.0.0">
    <data>
        <object runtimeType="orange.serialization.Serializer.G" type="G" key="0" id="0">
            <enum type="Foo" baseType="int" key="foo">1</enum>
        </object>
    </data>
</archive>`;
		
		auto g = new G;
		g.foo = Foo.b;
		serializer.serialize(g);
		assert(archive.data == data);
		
		// Deserializing
		
		auto gDeserialized = serializer.deserialize!(G)(data);
		assert(g.foo == gDeserialized.foo);
		
		// Primitives
		
		serializer.reset;
		data = `<?xml version="1.0" encoding="UTF-8"?>
<archive type="org.dsource.orange.xml" version="1.0.0">
    <data>
        <object runtimeType="orange.serialization.Serializer.H" type="H" key="0" id="0">
            <byte key="byte_">1</byte>
            <char key="char_">a</char>
            <dchar key="dchar_">b</dchar>
            <double key="double_">0</double>
            <float key="float_">0</float>
            <int key="int_">1</int>
            <long key="long_">1</long>
            <real key="real_">0</real>
            <short key="short_">1</short>
            <ubyte key="ubyte_">1</ubyte>
            <uint key="uint_">1</uint>
            <ulong key="ulong_">1</ulong>
            <ushort key="ushort_">1</ushort>
            <wchar key="wchar_">c</wchar>
            <bool key="bool_">true</bool>
        </object>
    </data>
</archive>`;
		
		auto h = new H;
		
		h.bool_ = true;
		h.byte_ = 1;
		h.char_ = 'a';
		//h.cdouble_ = 0.0 + 0.0 * 1.0i; // currently not suppported by to!() 
		//h.cfloat_ = 0.0f + 0.0f * 1.0i; // currently not suppported by to!() 
		//h.creal_ = 0.0 + 0.0 * 1.0i; // currently not suppported by to!() 
		h.dchar_ = 'b';
		h.double_ = 0.0;
		h.float_ = 0.0f;
		//h.idouble_ = 0.0 * 1.0i; // currently not suppported by to!() 
		//h.ifloat_ = 0.0f * 1.0i; // currently not suppported by to!()
		h.int_ = 1;
		//h.ireal_ = 0.0 * 1.0i; // currently not suppported by to!()
		h.long_ = 1L;
		h.real_ = 0.0;
		h.short_ = 1;
		h.ubyte_ = 1U;
		h.uint_ = 1U;
		h.ulong_ = 1LU;
		h.ushort_ = 1U;
		h.wchar_ = 'c';
		
		serializer.serialize(h);
		//assert(archive.data == data); // this is not a reliable comparison	
		
		// Deserializing
		
		auto hDeserialized = serializer.deserialize!(H)(data);
		assert(h == hDeserialized);
		
		// Typedef
		
		serializer.reset();
		data = `<?xml version="1.0" encoding="UTF-8"?>
<archive type="org.dsource.orange.xml" version="1.0.0">
    <data>
        <object runtimeType="orange.serialization.Serializer.I" type="I" key="0" id="0">
            <typedef type="Int" key="a">
                <int key="1">1</int>
            </typedef>
        </object>
    </data>
</archive>`;
		
		auto i = new I;
		i.a = 1;
		serializer.serialize(i);
		assert(archive.data == data);
		
		// Deserializing
		
		auto iDeserialized = serializer.deserialize!(I)(data);
		assert(i.a == iDeserialized.a);

		println("unit tests successful");
	}
}