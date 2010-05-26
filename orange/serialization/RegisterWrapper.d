/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 4, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.RegisterWrapper;

import orange.serialization.archives.Archive;
import orange.serialization.Serializer;

class RegisterBase
{
	
}

class SerializeRegisterWrapper (T, ArchiveType : IArchive) : RegisterBase
{
	private alias Serializer!(ArchiveType) SerializerType;
	private alias SerializerType.DataType DataType;
	private void delegate (T, SerializerType, DataType) dg;
	private void function (T, SerializerType, DataType) func;

	this (void delegate (T, SerializerType, DataType) dg)
	{
		this.dg = dg;
	}

	this (void function (T, SerializerType, DataType) func)
	{
		this.func = func;
	}

	void opCall (T value, SerializerType archive, DataType key)
	{
		if (dg)
			dg(value, archive, key);
		
		else if (func)
			func(value, archive, key);
	}
}

class DeserializeRegisterWrapper (T, ArchiveType : IArchive) : RegisterBase
{
	private alias Serializer!(ArchiveType) SerializerType;
	private alias SerializerType.DataType DataType;
	private void delegate (ref T, SerializerType, DataType) dg;
	private void function (ref T, SerializerType, DataType) func;

	this (void delegate (ref T, SerializerType, DataType) dg)
	{
		this.dg = dg;
	}

	this (void function (ref T, SerializerType, DataType) func)
	{
		this.func = func;
	}

	void opCall (ref T value, SerializerType archive, DataType key)
	{
		if (dg)
			dg(value, archive, key);
		
		if (func)
			func(value, archive, key);
	}
}