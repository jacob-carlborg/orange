/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 4, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.RegisterWrapper;

//import orange.serialization.archives.Archive;
//import orange.serialization.Serializer;
import orange.core.string;

class RegisterBase
{
	
}

class SerializeRegisterWrapper (T, SerializerType) : RegisterBase
{
	private void delegate (T, SerializerType, string) dg;
	private bool isDelegate;

	this (void delegate (T, SerializerType, string) dg)
	{
		isDelegate = true;
		this.dg = dg;
	}

	this (void function (T, SerializerType, string) func)
	{
		dg.funcptr = func;
	}

	void opCall (T value, SerializerType archive, string key)
	{
		if (dg && isDelegate)
			dg(value, archive, key);
		
		else if (dg)
			dg.funcptr(value, archive, key);
	}
}

class DeserializeRegisterWrapper (T, SerializerType) : RegisterBase
{
	private void delegate (ref T, SerializerType, string) dg;
	private bool isDelegate;

	this (void delegate (ref T, SerializerType, string) dg)
	{
		isDelegate = true;
		this.dg = dg;
	}

	this (void function (ref T, SerializerType, string) func)
	{
		dg.funcptr = func;
	}

	void opCall (ref T value, SerializerType archive, string key)
	{
		if (dg && isDelegate)
			dg(value, archive, key);
		
		if (dg)
			dg.funcptr(value, archive, key);
	}
}