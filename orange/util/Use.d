/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 29, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.util.Use;

import std.typetuple;
import std.typecons;
import std.traits;

alias ReturnType ReturnTypeOf;

/**
 * This struct can be used to implement, what looks similar to, new statements. This
 * struct overloads the "in" operator which a delegate can be passed to. The delegate
 * passed to the "in" operator will then be called at an appropriate time decided by the
 * implementation of the function returning the Use struct.
 *
 * Examples:
 * ---
 * Use!(void delegate (), bool) unless (bool condition)
 * {
 * 	Use!(void delegate (), bool) use;
 * 	use.args[1] = condition;
 *
 * 	use.args[0] = (void delegate () dg, bool condition) {
 * 		if (!condition)
 * 			dg();
 * 	};
 *
 * 	return use;
 * }
 *
 * int a = 3;
 * int b = 4;
 *
 * unless(a == b) in {
 * 	println("a != b");
 * };
 * ---
 */
struct Use (ARGS...)
{
	static assert (ARGS.length > 0);

	private
	{
		alias ReturnTypeOf!(ARGS[0]) ReturnType;

		static if (ARGS.length >= 2)
			alias Tuple!(ReturnType delegate (ARGS), ARGS[1 .. $]) NEW_ARGS;

		else
			alias Tuple!(ReturnType delegate (ARGS)) NEW_ARGS;
	}

	/**
	 * The first argument will be the delegate that performs some arbitrary operation. The
	 * rest of the arguments will be pass as arguments to the delegate in "args[0]".
	 */
	NEW_ARGS args;

	/**
	 * Overloads the "in" operator. The given delegate is supplied by the user and will be
	 * called at a time the implementaion has decided.
	 *
	 * Params:
	 *     dg = the user supplied delegate that will be called
	 *
	 * Returns: what ever the delegate stored in "args[0]" returns
	 */
	ReturnType opIn (ARGS[0] dg)
	{
		assert(args[0]);

		static if (NEW_ARGS.length == 1)
			return args[0](dg);

		else
			return args[0](dg, args.expand[1 .. $]);
	}
}

/**
 * This is a helper struct used by the "restore" function. It overloads the "in" operator
 * to allow to taking a delegate.
 */
struct RestoreStruct (U, T)
{
	/// The delegate that performs the operation.
	U delegate(U delegate (), ref T) dg;

	/// A pointer to the value to pass to the delegate.
	T* value;

	/**
	 * Overloads the "in" operator. It will simply call the delegate stored in the struct
	 * passing in the given delegate and the value stored in the struct.
	 *
	 * Params:
	 *     deleg = the delegate to pass the delegate stored in the struct
	 *
	 * Returns: whatever the delegate stored in the struct returns
	 *
	 * See_Also: restore
	 */
	U opIn (U delegate () deleg)
	{
		return dg(deleg, *value);
	}
}

/**
 * Restores the given variable to the value it was when it was passed to the function
 * after the delegate has finished.
 *
 * Examples:
 * ---
 * int a = 3;
 *
 * restore(a) in {
 * 	a = 4;
 * }
 *
 * assert(a == 3);
 * ---
 *
 * Params:
 *     val = variable that will be restored
 *
 * Returns: a RestoreStruct
 *
 * See_Also: RestoreStruct
 */
RestoreStruct!(U, T) restore (U = void, T) (ref T val)
{
	RestoreStruct!(U, T) restoreStruct;

	restoreStruct.dg = (U delegate () dg, ref T value){
		T t = value;

		static if (is(U == void))
		{
			dg();
			value = t;
		}

		else
		{
			auto result = dg();
			value = t;

			return result;
		}
	};

	restoreStruct.value = &val;

	return restoreStruct;
}