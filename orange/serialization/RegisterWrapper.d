/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 4, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.RegisterWrapper;

import orange.serialization.Serializer;

class RegisterBase { }

class SerializeRegisterWrapper (T) : RegisterBase
{
	private void delegate (T, Serializer, Serializer.Data) dg;
	private bool isDelegate;

	this (void delegate (T, Serializer, Serializer.Data) dg)
	{
		isDelegate = true;
		this.dg = dg;
	}

	this (void function (T, Serializer, Serializer.Data) func)
	{
		dg.funcptr = func;
	}

	void opCall (T value, Serializer archive, Serializer.Data key)
	{
		if (dg && isDelegate)
			dg(value, archive, key);
		
		else if (dg)
			dg.funcptr(value, archive, key);
	}
}

class DeserializeRegisterWrapper (T) : RegisterBase
{
	private void delegate (ref T, Serializer, Serializer.Data) dg;
	private bool isDelegate;

	this (void delegate (ref T, Serializer, Serializer.Data) dg)
	{
		isDelegate = true;
		this.dg = dg;
	}

	this (void function (ref T, Serializer, Serializer.Data) func)
	{
		dg.funcptr = func;
	}

	void opCall (ref T value, Serializer archive, Serializer.Data key)
	{
		if (dg && isDelegate)
			dg(value, archive, key);
		
		if (dg)
			dg.funcptr(value, archive, key);
	}
}