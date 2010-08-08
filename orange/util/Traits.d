/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.util.Traits;

import orange.serialization.Serializable;
import orange.serialization.archives.Archive;
import orange.util._;

version (Tango)
{
	import Tango = tango.core.Traits;
	alias Tango.BaseTypeTupleOf BaseTypeTupleOf;
	alias Tango.ParameterTupleOf ParameterTupleOf;
	alias Tango.ReturnTypeOf ReturnTypeOf;
}

else
{
	import Phobos = std.traits;
	alias Phobos.BaseTypeTuple BaseTypeTupleOf;
	alias Phobos.ParameterTypeTuple ParameterTupleOf;
	alias Phobos.ReturnType ReturnTypeOf;
	
	version = Phobos;
}

template isPrimitive (T)
{
	const bool isPrimitive = is(T == bool) ||
						is(T == byte) ||
						is(T == cdouble) ||
						//is(T == cent) ||
						is(T == cfloat) ||
						is(T == char) ||
						is(T == creal) ||
						is(T == dchar) ||
						is(T == double) ||
						is(T == float) ||
						is(T == idouble) ||
						is(T == ifloat) ||
						is(T == int) ||
						is(T == ireal) ||
						is(T == long) ||
						is(T == real) ||
						is(T == short) ||
						is(T == ubyte) ||
						//is(T == ucent) ||
						is(T == uint) ||
						is(T == ulong) ||
						is(T == ushort) ||
						is(T == wchar);
}

template isChar (T)
{
	const bool isChar = is(T == char) || is(T == wchar) || is(T == dchar);
}

template isClass (T)
{
	const bool isClass = is(T == class);
}

template isInterface (T)
{
	const bool isInterface = is(T == interface);
}

template isObject (T)
{
	const bool isObject = isClass!(T) || isInterface!(T);
}

template isStruct (T)
{
	const bool isStruct = is(T == struct);
}

template isArray (T)
{
	static if (is(T U : U[]))
		const bool isArray = true;
	
	else
		const bool isArray = false;
}

template isString (T)
{
	const bool isString = is(T : char[]) || is(T : wchar[]) || is(T : dchar[]);
}

template isAssociativeArray (T)
{
	const bool isAssociativeArray = is(typeof(T.init.values[0])[typeof(T.init.keys[0])] == T);
}

template isPointer (T)
{
	static if (is(T U : U*))
		const bool isPointer = true;
	
	else
		const bool isPointer = false;
}

template isFunctionPointer (T)
{
	const bool isFunctionPointer = is(typeof(*T) == function);
}

template isEnum (T)
{
	const bool isEnum = is(T == enum);
}

template isReference (T)
{
	const bool isReference = isObject!(T) || isPointer!(T);
}

template isTypeDef (T)
{
	const bool isTypeDef = is(T == typedef);
}

template isVoid (T)
{
	const bool isVoid = is(T == void);
}

template BaseTypeOfArray (T)
{
	static if (is(T U : U[]))
		alias BaseTypeOfArray!(U) BaseTypeOfArray;
	
	else
		alias T BaseTypeOfArray;
}

template BaseTypeOfPointer (T)
{
	static if (is(T U : U*))
		alias BaseTypeOfPointer!(U) BaseTypeOfPointer;
	
	else
		alias T BaseTypeOfPointer;
}

template BaseTypeOfTypeDef (T)
{
	static if (is(T U == typedef))
		alias BaseTypeOfTypeDef!(U) BaseTypeOfTypeDef;
	
	else
		alias T BaseTypeOfTypeDef;
}

template KeyTypeOfAssociativeArray (T)
{
	static assert(isAssociativeArray!(T), "The type needs to be an associative array");
	alias typeof(T.init.keys[0]) KeyTypeOfAssociativeArray;
}

template ValueTypeOfAssociativeArray (T)
{
	static assert(isAssociativeArray!(T), "The type needs to be an associative array");
	alias typeof(T.init.values[0]) ValueTypeOfAssociativeArray;
}

template isArchive (T)
{
	const isArchive = is(typeof({
		alias T.DataType Foo;
	})) &&

	is(typeof(T.archive(0, TypeOfDataType!(T).init, {}))) &&
	is(typeof(T.unarchive!(int))) && 
	is(typeof(T.beginArchiving)) &&
	is(typeof(T.beginUnarchiving(TypeOfDataType!(T).init))) &&
	is(typeof(T.archiveBaseClass!(Object))) &&
	is(typeof(T.unarchiveBaseClass!(Object))) &&
	is(typeof(T.reset)) &&
	is(typeof({TypeOfDataType!(T) a = T.data;})) &&
	is(typeof(T.unarchiveAssociativeArrayVisitor!(int[string])));
	
}

template isSerializable (T, SerializerType)
{
	const isSerializable = is(typeof(T.toData(SerializerType.init, SerializerType.DataType.init))) && is(typeof(T.fromData(SerializerType.init, SerializerType.DataType.init)));
}

template isISerializable (T)
{
	const isISerializable = is(T : ISerializable);
}

template TypeOfDataType (T)
{
	alias T.DataType TypeOfDataType;
}