/**
 * Copyright: Copyright (c) 2009-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Oct 5, 2009
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.util.Reflection;

import orange.util.CTFE;

/**
 * Evaluates to true if T has a field with the given name
 *
 * Params:
 * 		T = the type of the class/struct
 * 		field = the name of the field
 */
template hasField (T, string field)
{
	enum hasField = hasFieldImpl!(T, field, 0);
}

private template hasFieldImpl (T, string field, size_t i)
{
	static if (T.tupleof.length == i)
		enum hasFieldImpl = false;

	else static if (T.tupleof[i].stringof[1 + T.stringof.length + 2 .. $] == field)
		enum hasFieldImpl = true;

	else
		enum hasFieldImpl = hasFieldImpl!(T, field, i + 1);
}

/**
 * Evaluates to an array of strings containing the names of the fields in the given type
 */
template fieldsOf (T)
{
	enum fieldsOf = fieldsOfImpl!(T, 0);
}

/**
 * Implementation for fieldsOf
 *
 * Returns: an array of strings containing the names of the fields in the given type
 */
template fieldsOfImpl (T, size_t i)
{
	static if (T.tupleof.length == 0)
		enum fieldsOfImpl = [""];

	else static if (T.tupleof.length - 1 == i)
		enum fieldsOfImpl = [T.tupleof[i].stringof[1 + T.stringof.length + 2 .. $]];

	else
		enum fieldsOfImpl = T.tupleof[i].stringof[1 + T.stringof.length + 2 .. $] ~ fieldsOfImpl!(T, i + 1);
}

/**
 * Evaluates to the type of the field with the given name
 *
 * Params:
 * 		T = the type of the class/struct
 * 		field = the name of the field
 */
template TypeOfField (T, string field)
{
	static assert(hasField!(T, field), "The given field \"" ~ field ~ "\" doesn't exist in the type \"" ~ T.stringof ~ "\"");

	alias TypeOfFieldImpl!(T, field, 0) TypeOfField;
}

private template TypeOfFieldImpl (T, string field, size_t i)
{
	static if (T.tupleof[i].stringof[1 + T.stringof.length + 2 .. $] == field)
		alias typeof(T.tupleof[i]) TypeOfFieldImpl;

	else
		alias TypeOfFieldImpl!(T, field, i + 1) TypeOfFieldImpl;
}

/**
 * Evaluates to a string containing the name of the field at given position in the given type.
 *
 * Params:
 * 		T = the type of the class/struct
 * 		position = the position of the field in the tupleof array
 */
template nameOfFieldAt (T, size_t position)
{
    static assert (position < T.tupleof.length, format!(`The given position "`, position, `" is greater than the number of fields (`, T.tupleof.length, `) in the type "`, T, `"`));

	static if (T.tupleof[position].stringof.length > T.stringof.length + 3)
		enum nameOfFieldAt = T.tupleof[position].stringof[1 + T.stringof.length + 2 .. $];

	else
		enum nameOfFieldAt = "";
}

/**
 * Sets the given value to the filed with the given name
 *
 * Params:
 *     t = an instance of the type that has the field
 *     value = the value to set
 */
void setValueOfField (T, U, string field) (ref T t, U value)
in
{
	static assert(hasField!(T, field), "The given field \"" ~ field ~ "\" doesn't exist in the type \"" ~ T.stringof ~ "\"");
}
body
{
	enum len = T.stringof.length;

	foreach (i, dummy ; typeof(T.tupleof))
	{
		enum f = T.tupleof[i].stringof[1 + len + 2 .. $];

		static if (f == field)
		{
			t.tupleof[i] = value;
			break;
		}
	}
}

/**
 * Gets the value of the field with the given name
 *
 * Params:
 *     t = an instance of the type that has the field
 *
 * Returns: the value of the field
 */
U getValueOfField (T, U, string field) (T t)
in
{
	static assert(hasField!(T, field), "The given field \"" ~ field ~ "\" doesn't exist in the type \"" ~ T.stringof ~ "\"");
}
body
{
	enum len = T.stringof.length;

	foreach (i, dummy ; typeof(T.tupleof))
	{
		enum f = T.tupleof[i].stringof[1 + len + 2 .. $];

		static if (f == field)
			return t.tupleof[i];
	}

	assert(0);
}

private
{
	version (LDC)
		extern (C) Object _d_allocclass(in ClassInfo);

	else
		extern (C) Object _d_newclass(in ClassInfo);
}

/**
 * Returns a new instnace of the class associated with the given class info.
 *
 * Params:
 *     classInfo = the class info associated with the class
 *
 * Returns: a new instnace of the class associated with the given class info.
 */
Object newInstance (in ClassInfo classInfo)
{
	version (LDC)
	{
		Object object = _d_allocclass(classInfo);
        (cast(byte*) object)[0 .. classInfo.init.length] = classInfo.init[];

        return object;
	}

	else
		return _d_newclass(classInfo);
}

/**
 * Return a new instance of the class with the given name.
 *
 * Params:
 *     name = the fully qualified name of the class
 *
 * Returns: a new instance or null if the class name could not be found
 */
Object newInstance (string name)
{
	auto classInfo = ClassInfo.find(name);

	if (!classInfo)
		return null;

	return newInstance(classInfo);
}