/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 6, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.archives.Archive;

version (Tango)
	import tango.util.Convert;

else
{
	import std.array;
	import std.conv;
	import std.utf;
	static import std.string;

	alias ConvException ConversionException;
}

import orange.serialization.archives.ArchiveException;
import orange.core.string;
import orange.util.Traits;

private enum ArchiveMode
{
	archiving,
	unarchiving
}

/**
 * 
 */
struct Array
{
	version (Tango)
		void* ptr;
		
	else
		mixin(`const(void)* ptr;`);

	///
	size_t length;
	
	///
	size_t elementSize;
	
	/**
	 * 
	 * Params:
	 *     b = 
	 * Returns:
	 */
	bool isSliceOf (Array b)
	{
		return ptr >= b.ptr && ptr + length * elementSize <= b.ptr + b.length * b.elementSize;
	}
}

/**
 * 
 * Authors: doob
 */
struct Slice
{
	size_t length;
	size_t offset;
	size_t id = size_t.max;
}

/**
 * 
 * Authors: doob
 */
interface Archive
{
	///
	alias size_t Id;
	
	///
	version (Tango) alias void[] UntypedData;
	else mixin ("alias immutable(void)[] UntypedData;");
	
	/**
	 * 
	 *
	 */
	void beginArchiving ();
	
	/**
	 * 
	 * Params:
	 *     data =
	 */
	void beginUnarchiving (UntypedData data);
	
	/**
	 * 
	 * Returns:
	 */
	UntypedData untypedData ();
	
	/**
	 * 
	 *
	 */
	void reset ();
	
	/**
	 * 
	 * Params:
	 *     array = 
	 *     type = 
	 *     key = 
	 *     id = 
	 *     dg =
	 */
	void archiveArray (Array array, string type, string key, Id id, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     keyType = 
	 *     valueType = 
	 *     length = 
	 *     key = 
	 *     id = 
	 *     dg =
	 */
	void archiveAssociativeArray (string keyType, string valueType, size_t length, string key, Id id, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg =
	 */
	void archiveAssociativeArrayKey (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg =
	 */
	void archiveAssociativeArrayValue (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     value = 
	 *     baseType = 
	 *     key = 
	 *     id =
	 */
	void archiveEnum (bool value, string baseType, string key, Id id);
	
	///
	void archiveEnum (bool value, string baseType, string key, Id id);
	
	///
	void archiveEnum (byte value, string baseType, string key, Id id);
	
	///
	void archiveEnum (char value, string baseType, string key, Id id);
	
	///
	void archiveEnum (dchar value, string baseType, string key, Id id);
	
	///
	void archiveEnum (int value, string baseType, string key, Id id);
	
	///
	void archiveEnum (long value, string baseType, string key, Id id);
	
	///
	void archiveEnum (short value, string baseType, string key, Id id);
	
	///
	void archiveEnum (ubyte value, string baseType, string key, Id id);
	
	///
	void archiveEnum (uint value, string baseType, string key, Id id);
	
	///
	void archiveEnum (ulong value, string baseType, string key, Id id);
	
	///
	void archiveEnum (ushort value, string baseType, string key, Id id);
	
	///
	void archiveEnum (wchar value, string baseType, string key, Id id);
	
	/**
	 * 
	 * Params:
	 *     type = 
	 *     key = 
	 *     id =
	 */
	void archiveBaseClass (string type, string key, Id id);
	
	/**
	 * 
	 * Params:
	 *     type = 
	 *     key =
	 */
	void archiveNull (string type, string key);
	
	/**
	 * 
	 * Params:
	 *     runtimeType = 
	 *     type = 
	 *     key = 
	 *     id = 
	 *     dg =
	 */
	void archiveObject (string runtimeType, string type, string key, Id id, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     id = 
	 *     dg =
	 */
	void archivePointer (string key, Id id, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     pointeeId = 
	 *     key = 
	 *     id =
	 */
	void archivePointer (Id pointeeId, string key, Id id);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     id =
	 */
	void archiveReference (string key, Id id);
	
	/**
	 * 
	 * Params:
	 *     slice = 
	 *     sliceId = 
	 *     arrayId =
	 */
	void archiveSlice (Slice slice, Id sliceId, Id arrayId);
	
	/**
	 * 
	 * Params:
	 *     type = 
	 *     key = 
	 *     id = 
	 *     dg =
	 */
	void archiveStruct (string type, string key, Id id, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     type = 
	 *     key = 
	 *     id = 
	 *     dg =
	 */
	void archiveTypedef (string type, string key, Id id, void delegate () dg);

	/**
	 * 
	 * Params:
	 *     value = 
	 *     key = 
	 *     id =
	 */
	void archive (string value, string key, Id id);
	
	///
	void archive (wstring value, string key, Id id);
	
	///
	void archive (dstring value, string key, Id id);
	
	///	
	void archive (bool value, string key, Id id);
	
	///
	void archive (byte value, string key, Id id);
	
	
	//void archive (cdouble value, string key, Id id); // currently not supported by to!()
	
	
	//void archive (cent value, string key, Id id);
	
	//void archive (cfloat value, string key, Id id); // currently not supported by to!()
	
	///
	void archive (char value, string key, Id id); // currently not implemented but a reserved keyword
	
	//void archive (creal value, string key, Id id); // currently not supported by to!()
	
	///
	void archive (dchar value, string key, Id id);
	
	///
	void archive (double value, string key, Id id);
	
	///
	void archive (float value, string key, Id id);
	
	
	//void archive (idouble value, string key, Id id); // currently not supported by to!()
	
	//void archive (ifloat value, string key, Id id); // currently not supported by to!()
	
	///
	void archive (int value, string key, Id id);
	

	//void archive (ireal value, string key, Id id); // currently not supported by to!()
	
	///
	void archive (long value, string key, Id id);
	
	///
	void archive (real value, string key, Id id);
	
	///
	void archive (short value, string key, Id id);
	
	///
	void archive (ubyte value, string key, Id id);
	
	//void archive (ucent value, string key, Id id); // currently not implemented but a reserved keyword
	
	///
	void archive (uint value, string key, Id id);
	
	///
	void archive (ulong value, string key, Id id);
	
	///
	void archive (ushort value, string key, Id id);
	
	///
	void archive (wchar value, string key, Id id);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg = 
	 * Returns:
	 */
	Id unarchiveArray (string key, void delegate (size_t length) dg);
	
	/**
	 * 
	 * Params:
	 *     id = 
	 *     dg =
	 */
	void unarchiveArray (Id id, void delegate (size_t length) dg);
	
	/**
	 * 
	 * Params:
	 *     type = 
	 *     dg = 
	 * Returns:
	 */
	Id unarchiveAssociativeArray (string type, void delegate (size_t length) dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg =
	 */
	void unarchiveAssociativeArrayKey (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg =
	 */
	void unarchiveAssociativeArrayValue (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 * Returns:
	 */
	bool unarchiveEnumBool (string key);
	
	///
	byte unarchiveEnumByte (string key);
	
	///
	char unarchiveEnumChar (string key);
	
	///
	dchar unarchiveEnumDchar (string key);
	
	///
	int unarchiveEnumInt (string key);
	
	///
	long unarchiveEnumLong (string key);
	
	///
	short unarchiveEnumShort (string key);
	
	///
	ubyte unarchiveEnumUbyte (string key);
	
	///
	uint unarchiveEnumUint (string key);
	
	///
	ulong unarchiveEnumUlong (string key);
	
	///
	ushort unarchiveEnumUshort (string key);
	
	///
	wchar unarchiveEnumWchar (string key);
	
	/**
	 * 
	 * Params:
	 *     key =
	 */
	void unarchiveBaseClass (string key);
	
	/**
	 * 
	 * Params:
	 *     key =
	 */
	//void unarchiveNull (string key);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     id = 
	 *     result = 
	 *     dg =
	 */
	void unarchiveObject (string key, out Id id, out Object result, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg = 
	 * Returns:
	 */
	Id unarchivePointer (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 * Returns:
	 */
	Id unarchiveReference (string key);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 * Returns:
	 */
	Slice unarchiveSlice (string key);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg =
	 */
	void unarchiveStruct (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg =
	 */
	void unarchiveTypedef (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     id = 
	 * Returns:
	 */
	string unarchiveString (Id id);
	
	///
	wstring unarchiveWstring (Id id);
	
	///
	dstring unarchiveDstring (Id id);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     id = 
	 * Returns:
	 */
	string unarchiveString (string key, out Id id);
	
	///
	wstring unarchiveWstring (string key, out Id id);
	
	///
	dstring unarchiveDstring (string key, out Id id);
	
	///
    bool unarchiveBool (string key);
	
	///
    byte unarchiveByte (string key);
    
    //cdouble unarchiveCdouble (string key); // currently not supported by to!()
    //cent unarchiveCent (string key); // currently not implemented but a reserved keyword
    //cfloat unarchiveCfloat (string key); // currently not supported by to!()
	
	///
    char unarchiveChar (string key); // currently not implemented but a reserved keyword
    //creal unarchiveCreal (string key); // currently not supported by to!()
    
    dchar unarchiveDchar (string key);
	
	///
    double unarchiveDouble (string key);
	
	///
    float unarchiveFloat (string key);
    //idouble unarchiveIdouble (string key); // currently not supported by to!()
    //ifloat unarchiveIfloat (string key); // currently not supported by to!()*/
	
	///
    int unarchiveInt (string key);
    
	//int unarchiveInt (Id id);
    //ireal unarchiveIreal (string key); // currently not supported by to!()
	
	///
    long unarchiveLong (string key);
	
	///
    real unarchiveReal (string key);
	
	///
    short unarchiveShort (string key);
	
	///
    ubyte unarchiveUbyte (string key);
	
	///
    //ucent unarchiveCcent (string key); // currently not implemented but a reserved keyword
    uint unarchiveUint (string key);
	
	///
    ulong unarchiveUlong (string key);
	
	///
    ushort unarchiveUshort (string key);
	
	///
    wchar unarchiveWchar (string key);
	
	/**
	 * 
	 * Params:
	 *     id =
	 */
	void postProcessArray (Id id);
	
	/**
	 * 
	 * Params:
	 *     id =
	 */
	void postProcessPointer (Id id);
}

/**
 * 
 * Authors: doob
 */
abstract class Base (U) : Archive
{
	///
	version (Tango) alias U[] Data;
	else mixin ("alias immutable(U)[] Data;");
	
	///
	alias void delegate (ArchiveException exception, string[] data) ErrorCallback;
	
	///
	protected ErrorCallback errorCallback;
	
	/**
	 * 
	 * Params:
	 *     errorCallback =
	 */
	protected this (ErrorCallback errorCallback)
	{
		this.errorCallback = errorCallback;
	}
	
	/**
	 * 
	 * Params:
	 *     value = 
	 * Returns:
	 */
	protected Data toData (T) (T value)
	{
		try
		{
			static if (isFloatingPoint!(T))
				return floatingPointToData(value);

			else
				return to!(Data)(value);
		}
		
		catch (ConversionException e)
			throw new ArchiveException(e);
	}
	
	/**
	 * 
	 * Params:
	 *     value = 
	 * Returns:
	 */
	protected T fromData (T) (Data value)
	{
		try
		{
			static if (is(T == wchar))
				return toWchar(value);

			else
				return to!(T)(value);
		}

		catch (ConversionException e)
			throw new ArchiveException(e);
	}
	
	/**
	 * 
	 * Params:
	 *     value = 
	 * Returns:
	 */
	protected Data floatingPointToData (T) (T value)
	{
		static assert(isFloatingPoint!(T), format!(`The given value of the type "`, T,
			`" is not a valid type, the only valid types for this method are floating point types.`));
		
		version (Tango)
			return to!(Data)(value);
			
		else
			return to!(Data)(std.string.format("%a", value));
	}
	
	/**
	 * 
	 * Params:
	 *     value = 
	 * Returns:
	 */
	protected Id toId (Data value)
	{
		return fromData!(Id)(value);
	}
	
	/**
	 * 
	 * Params:
	 *     a = 
	 *     b = 
	 * Returns:
	 */
	protected bool isSliceOf (T, U = T) (T[] a, U[] b)
	{
		void* aPtr = a.ptr;
		void* bPtr = b.ptr;
		
		return aPtr >= bPtr && aPtr + a.length * T.sizeof <= bPtr + b.length * U.sizeof;
	}
	
	private wchar toWchar (Data value)
	{
		version (Tango)
			return to!(wchar)(value);
		
		else
		{
			auto c = value.front;

			if (codeLength!(wchar)(c) > 2)
				throw new ConversionException("Could not convert `" ~
					to!(string)(value) ~ "` of type " ~
					Data.stringof ~ " to type wchar.");

			return cast(wchar) c;
		}
	}
}