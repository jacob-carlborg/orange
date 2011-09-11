/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 4, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.RegisterWrapper;

import orange.serialization.Serializer;

/**
 * This class is the base of all register wrappers. A register wrapper wraps a function
 * that is registered with the serializer. The serializer calls this function to perform
 * custom (de)serialization when needed.
 */
class RegisterBase { }

/**
 * This class wraps registered functions for serialization.
 * 
 * Params:
 *     T = the type of the class or struct which is serialized
 */
class SerializeRegisterWrapper (T) : RegisterBase
{
	private void delegate (T, Serializer, Serializer.Data) dg;
	private bool isDelegate;

	/**
	 * Creates a new instance of this class with the given delegate that performs the
	 * custom serialization.
	 * 
	 * 
	 * Params:
	 *     dg = the delegate to call when performing custom serialization
	 */
	this (void delegate (T, Serializer, Serializer.Data) dg)
	{
		isDelegate = true;
		this.dg = dg;
	}

	/**
	 * Creates a new instance of this class with the given function that performs the
	 * custom serialization.
	 * 
	 * 
	 * Params:
	 *     dg = the delegate to call when performing custom serialization
	 */
	this (void function (T, Serializer, Serializer.Data) func)
	{
		dg.funcptr = func;
	}

	/**
	 * Calls the function to perform the custom serialization.
	 * 
	 * Params:
	 *     value = the instance that is to be serialized
	 *     serializer = the serializer that performs the serialization
	 *     key = the key of the given value
	 */
	void opCall (T value, Serializer serializer, Serializer.Data key)
	{
		if (dg && isDelegate)
			dg(value, serializer, key);
		
		else if (dg)
			dg.funcptr(value, serializer, key);
	}
}

/**
 * This class wraps registered functions for deserialization.
 * 
 * Params:
 *     T = the type of the class or struct which is deserialized
 */
class DeserializeRegisterWrapper (T) : RegisterBase
{
	private void delegate (ref T, Serializer, Serializer.Data) dg;
	private bool isDelegate;

	/**
	 * Creates a new instance of this class with the given delegate that performs the
	 * custom deserialization.
	 * 
	 * 
	 * Params:
	 *     dg = the delegate to call when performing custom serialization
	 */
	this (void delegate (ref T, Serializer, Serializer.Data) dg)
	{
		isDelegate = true;
		this.dg = dg;
	}

	/**
	 * Creates a new instance of this class with the given function that performs the
	 * custom serialization.
	 * 
	 * 
	 * Params:
	 *     dg = the delegate to call when performing custom serialization
	 */
	this (void function (ref T, Serializer, Serializer.Data) func)
	{
		dg.funcptr = func;
	}

	/**
	 * Calls the function to perform the custom deserialization.
	 * 
	 * Params:
	 *     value = the instance that is to be deserialized
	 *     serializer = the serializer that performs the deserialization
	 *     key = the key of the given value
	 */
	void opCall (ref T value, Serializer serializer, Serializer.Data key)
	{
		if (dg && isDelegate)
			dg(value, serializer, key);
		
		if (dg)
			dg.funcptr(value, serializer, key);
	}
}