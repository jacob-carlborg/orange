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

struct Slice
{
	size_t length;
	void* ptr;
	
	static Slice opCall (T) (T[] value)
	{
		Slice slice;
		slice.length = value.length;
		slice.ptr = value.ptr;
		
		return slice;
	}
}

interface IArchive
{
	void beginArchiving ();
	void reset ();
}

abstract class Archive (U) : IArchive
{
	version (Tango) alias U[] DataType;
	else mixin ("alias immutable(U)[] DataType;");
	
	alias void delegate (ArchiveException exception, DataType[] data) ErrorCallback;
	
	ErrorCallback errorCallback;
	
	abstract void beginArchiving ();
	abstract void beginUnarchiving (DataType data);
	abstract DataType data ();
	abstract void reset ();
	
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