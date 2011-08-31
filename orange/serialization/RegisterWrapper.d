/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 4, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.RegisterWrapper;

import orange.serialization.Serializer;

/**
 * 
 * Authors: doob
 */
class RegisterBase { }

/**
 * 
 * Authors: doob
 */
class SerializeRegisterWrapper (T) : RegisterBase
{
	private void delegate (T, Serializer, Serializer.Data) dg;
	private bool isDelegate;

	/**
	 * 
	 * Params:
	 *     dg =
	 */
	this (void delegate (T, Serializer, Serializer.Data) dg)
	{
		isDelegate = true;
		this.dg = dg;
	}

	/**
	 * 
	 * Params:
	 *     func =
	 */
	this (void function (T, Serializer, Serializer.Data) func)
	{
		dg.funcptr = func;
	}

	/**
	 * 
	 * Params:
	 *     value = 
	 *     archive = 
	 *     key =
	 */
	void opCall (T value, Serializer archive, Serializer.Data key)
	{
		if (dg && isDelegate)
			dg(value, archive, key);
		
		else if (dg)
			dg.funcptr(value, archive, key);
	}
}

/**
 * 
 * Authors: doob
 */
class DeserializeRegisterWrapper (T) : RegisterBase
{
	private void delegate (ref T, Serializer, Serializer.Data) dg;
	private bool isDelegate;

	/**
	 * 
	 * Params:
	 *     dg =
	 */
	this (void delegate (ref T, Serializer, Serializer.Data) dg)
	{
		isDelegate = true;
		this.dg = dg;
	}

	/**
	 * 
	 * Params:
	 *     func =
	 */
	this (void function (ref T, Serializer, Serializer.Data) func)
	{
		dg.funcptr = func;
	}

	/**
	 * 
	 * Params:
	 *     value = 
	 *     archive = 
	 *     key =
	 */
	void opCall (ref T value, Serializer archive, Serializer.Data key)
	{
		if (dg && isDelegate)
			dg(value, archive, key);
		
		if (dg)
			dg.funcptr(value, archive, key);
	}
}