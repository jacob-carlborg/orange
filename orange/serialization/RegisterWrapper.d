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

class SerializeRegisterWrapper (T, SerializerType) : RegisterBase
{
	private alias SerializerType.DataType DataType;
	private void delegate (T, SerializerType, DataType) dg;
	private bool isDelegate;

	this (void delegate (T, SerializerType, DataType) dg)
	{
		isDelegate = true;
		this.dg = dg;
	}

	this (void function (T, SerializerType, DataType) func)
	{
		dg.funcptr = func;
	}

	void opCall (T value, SerializerType archive, DataType key)
	{
		if (dg && isDelegate)
			dg(value, archive, key);
		
		else if (dg)
			dg.funcptr(value, archive, key);
	}
}

class DeserializeRegisterWrapper (T, SerializerType) : RegisterBase
{
	private alias SerializerType.DataType DataType;
	private void delegate (ref T, SerializerType, DataType) dg;
	private bool isDelegate;

	this (void delegate (ref T, SerializerType, DataType) dg)
	{
		isDelegate = true;
		this.dg = dg;
	}

	this (void function (ref T, SerializerType, DataType) func)
	{
		dg.funcptr = func;
	}

	void opCall (ref T value, SerializerType archive, DataType key)
	{
		if (dg && isDelegate)
			dg(value, archive, key);
		
		if (dg)
			dg.funcptr(value, archive, key);
	}
}