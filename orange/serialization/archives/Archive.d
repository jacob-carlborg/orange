/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 6, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.archives.Archive;

version (Tango)
	import tango.util.Convert;

else
{
	import std.conv;
	alias ConvError ConversionException;
}

import orange.serialization.archives.ArchiveException;
import orange.util.string;

struct Array
{
	void* ptr;
	size_t length;
	size_t elementSize;
	
	static Array opCall (T) (T[] value)
	{
		Array array;
		array.ptr = value.ptr;
		array.length = value.length;
		array.elementSize = T.sizeof;
		
		return array;
	}
	
	bool isSliceOf (Array b)
	{
		return ptr >= b.ptr && ptr + length * elementSize <= b.ptr + b.length * b.elementSize;
	}
}

struct Slice
{
	size_t length;
	size_t offset;
	size_t id;
}

interface IArchive
{
	version (Tango) alias void[] IDataType;
	else mixin ("alias immutable(void)[] IDataType;");
	
	void beginArchiving ();
	void beginUnarchiving (IDataType data);
	
	IDataType data ();
	void postProcess ();
	void reset ();
	
	void archiveArray (string type, size_t length, size_t elementSize, string key, size_t id);
	void archiveAssociativeArray (string keyType, string valueType, size_t length, string key, size_t id);
	
	void archiveEnum (bool value, string key, size_t id);
	void archiveEnum (byte value, string key, size_t id);
	void archiveEnum (char value, string key, size_t id);
	void archiveEnum (dchar value, string key, size_t id);
	void archiveEnum (int value, string key, size_t id);
	void archiveEnum (long value, string key, size_t id);
	void archiveEnum (short value, string key, size_t id);
	void archiveEnum (ubyte value, string key, size_t id);
	void archiveEnum (uint value, string key, size_t id);
	void archiveEnum (ulong value, string key, size_t id);
	void archiveEnum (ushort value, string key, size_t id);
	void archiveEnum (wchar value, string key, size_t id);
	
	void archiveNull (string type, string key);
	void archiveObject (string runtimeType, string type, string key, size_t id);
	void archivePointer (string key, size_t id);
	void archiveReference (string key, size_t id);
	//void archiveSlice (size_t length, size_t offset, string key, size_t id);
	void archiveStruct (string type, string key, size_t id);
	void archiveTypedef (string type, string key, size_t id);

	void archive (string value, string key, size_t id);
	void archive (wstring value, string key, size_t id);
	void archive (dstring value, string key, size_t id);	
	void archive (bool value, string key, size_t id);
	void archive (byte value, string key, size_t id);
	void archive (cdouble value, string key, size_t id);
	//void archive (cent value, string key, size_t id);
	void archive (cfloat value, string key, size_t id);
	void archive (char value, string key, size_t id);
	void archive (creal value, string key, size_t id);
	void archive (dchar value, string key, size_t id);
	void archive (double value, string key, size_t id);
	void archive (float value, string key, size_t id);
	void archive (idouble value, string key, size_t id);
	void archive (ifloat value, string key, size_t id);
	void archive (int value, string key, size_t id);
	void archive (ireal value, string key, size_t id);
	void archive (long value, string key, size_t id);
	void archive (real value, string key, size_t id);
	void archive (short value, string key, size_t id);
	void archive (ubyte value, string key, size_t id);
	//void archive (ucent value, string key, size_t id);
	void archive (uint value, string key, size_t id);
	void archive (ulong value, string key, size_t id);
	void archive (ushort value, string key, size_t id);
	void archive (wchar value, string key, size_t id);
}

abstract class Archive (U) //: IArchive
{
	version (Tango) alias U[] DataType;
	else mixin ("alias immutable(U)[] DataType;");
	
	alias void delegate (ArchiveException exception, DataType[] data) ErrorCallback;
	
	ErrorCallback errorCallback;
	
	protected DataType toDataType (T) (T value)
	{
		try
			return to!(DataType)(value);
		
		catch (ConversionException e)
			throw new ArchiveException(e);
	}
	
	protected T fromDataType (T) (DataType value)
	{
		try
			return to!(T)(value);
		
		catch (ConversionException e)
			throw new ArchiveException(e);
	}
	
	protected bool isSliceOf (T, U = T) (T[] a, U[] b)
	{
		void* aPtr = a.ptr;
		void* bPtr = b.ptr;
		
		return aPtr >= bPtr && aPtr + a.length * T.sizeof <= bPtr + b.length * U.sizeof;
	}
}