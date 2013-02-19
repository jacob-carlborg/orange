/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Oct 17, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 *
 * This is a simple unit test framework inspired by rspec. This framework is used for
 * collecting unit test failures (assert exceptions) and presents them to the user in a
 * nice format.
 *
 * The following are features of how a test report is printed:
 *
 * $(UL
 * 	$(LI print the filename and line number of the failing test)
 * 	$(LI print the description of a failing or pending test)
 * 	$(LI print a snippet of the file around a failing test)
 * 	$(LI print the stack trace of a failing test)
 * 	$(LI print the number of failing, pending and passed test.
 * 		As well as the total number of tests)
 * 	$(LI minimal output then all tests pass)
 * )
 *
 * If an assertion fails in a "it" block, that block will end. No other block is affected
 * by the failed assertion.
 *
 * Examples:
 * ---
 * import orange.test.UnitTester;
 *
 * int sum (int x, int y)
 * {
 * 	return x * y;
 * }
 *
 * unittest ()
 * {
 * 	describe("sum") in {
 * 		it("should return the sum of the two given arguments") in {
 * 			assert(sum(1, 2) == 3);
 * 		}
 * 	}
 * }
 *
 * void main ()
 * {
 * 	run;
 * }
 * ---
 * When the code above is run, it would print, since the test is failing, something similar:
 * ---
 * sum
 *   - should return the sum of the given arguments
 *
 * Failures:
 *     1) sum should return the sum of the given arguments
 *        # main.d:44
 *        Stack trace:
 *        tango.core.Exception.AssertException@main(44): Assertion failure
 *
 *
 * describe("sum") in {
 * 	it("should return the sum of the given arguments") in {
 * 		assert(sum(1, 2) == 3);
 * 	};
 * };
 *
 * 1 test, 1 failure
 * ---
 */
module orange.test.UnitTester;

import core.exception;
import std.conv;
import std.stdio;

private alias AssertError AssertException;

import orange.util._;

/**
 * Describes a test or a set of tests.
 *
 * Examples:
 * ---
 * unittest ()
 * {
 * 	describe("the description of the tests") in {
 *
 * 	};
 * }
 * ---
 *
 * Params:
 *     message = the message to describe the test
 *
 * Returns: a context in which the tests will be run
 */
Use!(void delegate (), string) describe (string message)
{
	return UnitTester.instance.describe(message);
}

/**
 * Describes what a test should do.
 *
 * Examples:
 * ---
 * unittest ()
 * {
 * 	describe("the description of the tests") in {
 * 		it("should do something") in {
 * 			// put your assert here
 * 		};
 *
 * 		it("should do something else") in {
 * 			// put another assert here
 * 		}
 * 	};
 * }
 * ---
 *
 * Params:
 *     message = what the test should do
 *
 * Returns: a context in which the test will be run
 */
Use!(void delegate (), string) it (string message)
{
	return UnitTester.instance.test(message);
}

/// A delegate that will be called before each test.
void delegate () before ()
{
	return UnitTester.instance.before;
}

/// A delegate that will be called before each test.
void delegate () before (void delegate () before)
{
	return UnitTester.instance.before = before;
}

/// A delegate that will be called after each test.
void delegate () after ()
{
	return UnitTester.instance.after;
}

/// A delegate that will be called after each test.
void delegate () after (void delegate () after)
{
	return UnitTester.instance.after = after;
}

/// Runs all tests.
void run ()
{
	UnitTester.instance.run;
}

private:

class UnitTester
{
	private:

	struct DescriptionManager
	{
		Description[] descriptions;
		size_t lastIndex = size_t.max;

		void opCatAssign (Description description)
		{
			descriptions ~= description;
			lastIndex++;
		}

		void opCatAssign (Test test)
		{
			last.tests ~= test;
		}

		Description opIndex (size_t i)
		{
			return descriptions[i];
		}

		Description last ()
		{
			return descriptions[$ - 1];
		}

		Description first ()
		{
			return descriptions[0];
		}

		int opApply (int delegate(ref Description) dg)
		{
			int result = 0;

			foreach (desc ; descriptions)
			{
				result = dg(desc);

				if (result)
					return result;
			}

			return result;
		}

		size_t length ()
		{
			return descriptions.length;
		}
	}

	class Description
	{
		private
		{
			DescriptionManager descriptions;
			Test[] tests;
			Test[] failures;
			Test[] pending;
			size_t lastIndex = size_t.max;
			string message;
			void delegate () description;
		}

		this (string message)
		{
			this.message = message;
		}

		void run ()
		{
			if (shouldRun)
				description();
		}

		bool shouldRun ()
		{
			return description !is null;
		}
	}

	struct Test
	{
		void delegate () test;
		string message;
		AssertException exception;

		bool failed ()
		{
			return !succeeded;
		}

		bool succeeded ()
		{
			if (exception is null)
				return true;

			return false;
		}

		void run ()
		{
			if (!isPending)
				test();
		}

		bool isPending ()
		{
			return test is null;
		}
	}

	static UnitTester instance_;

	DescriptionManager descriptions;
	Description currentDescription;

	void delegate () before_;
	void delegate () after_;

	size_t numberOfFailures;
	size_t numberOfPending;
	size_t numberOfTests;
	size_t failureId;

	string defaultIndentation = "    ";
	string indentation;

	static UnitTester instance ()
	{
		if (instance_)
			return instance_;

		return instance_ = new UnitTester;
	}

	Use!(void delegate (), string) describe (string message)
	{
		addDescription(message);
		Use!(void delegate (), string) use;

		use.args[0] = &internalDescribe;
		use.args[1] = message;

		return use;
	}

	Use!(void delegate (), string) test (string message)
	{
		addTest(message);
		Use!(void delegate (), string) use;

		use.args[0] = &internalTest;
		use.args[1] = message;

		return use;
	}

	void run ()
	{
		foreach (description ; descriptions)
			runDescription(description);

		printResult;
	}

	void runDescription (Description description)
	{
		restore(currentDescription) in {
			currentDescription = description;
			description.run;

			foreach (desc ; description.descriptions)
				runDescription(desc);

			foreach (test ; description.tests)
			{
				if (test.isPending)
					addPendingTest(description, test);

				try
				{
					execute in {
						test.run();
					};
				}

				catch (AssertException e)
					handleFailure(description, test, e);
			}
		};
	}

	void delegate () before ()
	{
		return before_;
	}

	void delegate () before (void delegate () before)
	{
		return before_ = before;
	}

	void delegate () after ()
	{
		return after_;
	}

	void delegate () after (void delegate () after)
	{
		return after_ = after;
	}

	void addTest (string message)
	{
		numberOfTests++;
		currentDescription.tests ~= Test(null, message);
	}

	void addDescription (string message)
	{
		if (currentDescription)
			currentDescription.descriptions ~= new Description(message);

		else
			descriptions ~= new Description(message);
	}

	void addPendingTest (Description description, ref Test test)
	{
		numberOfPending++;
		description.pending ~= test;
	}

	void handleFailure (Description description, ref Test test, AssertException exception)
	{
		numberOfFailures++;
		test.exception = exception;
		description.failures ~= test;
	}

	void internalDescribe (void delegate () dg, string message)
	{
		if (currentDescription)
			currentDescription.descriptions.last.description = dg;

		else
			descriptions.last.description = dg;
	}

	void internalTest (void delegate () dg, string message)
	{
		currentDescription.tests[$ - 1] = Test(dg, message);
	}

	void printResult ()
	{
		if (isAllTestsSuccessful)
			return printSuccess();

		foreach (description ; descriptions)
		{
			printDescription(description);
			printResultImpl(description.descriptions);
		}

		failureId = 0;

		printPending;
		printFailures;

		write("\n", numberOfTests, " ", pluralize("test", numberOfTests),", ", numberOfFailures, " ", pluralize("failure", numberOfFailures));
		printNumberOfPending;
		writeln();
	}

	void printResultImpl (DescriptionManager descriptions)
	{
		restore(indentation) in {
			indentation ~= defaultIndentation;

			foreach (description ; descriptions)
			{
				printDescription(description);
				printResultImpl(description.descriptions);
			}
		};
	}

	void printDescription (Description description)
	{
		writeln(indentation, description.message);

		restore(indentation) in {
			indentation ~= defaultIndentation;

			foreach (i, ref test ; description.tests)
			{
				write(indentation, "- ", test.message);

				if (test.isPending)
					write(" (PENDING: Not Yet Implemented)");

				if (test.failed)
					write(" (FAILED - ", ++failureId, ')');

				writeln();
			}
		};
	}

	void printPending ()
	{
		if (!hasPending)
			return;

		writeln("\nPending:");

		restore(indentation) in {
			indentation ~= defaultIndentation;

			foreach (description ; descriptions)
			{
				printPendingDescription(description);
				printPendingImpl(description.descriptions);
			}
		};
	}

	void printPendingImpl (DescriptionManager descriptions)
	{
		foreach (description ; descriptions)
		{
			printPendingDescription(description);
			printPendingImpl(description.descriptions);
		}
	}

	void printPendingDescription (Description description)
	{
		foreach (test ; description.pending)
			writeln(indentation, description.message, " ", test.message, "\n", indentation, indentation, "# Not Yet Implemented");
	}

	void printFailures ()
	{
		if (!hasFailures)
			return;

		writeln("\nFailures:");

		restore(indentation) in {
			indentation ~= defaultIndentation;

			foreach (description ; descriptions)
			{
				printFailuresDescription(description);
				printFailuresImpl(description.descriptions);
			}
		};
	}

	void printFailuresImpl (DescriptionManager descriptions)
	{
		foreach (description ; descriptions)
		{
			printFailuresDescription(description);
			printFailuresImpl(description.descriptions);
		}
	}

	void printFailuresDescription (Description description)
	{
		foreach (test ; description.failures)
		{
			auto str = indentation ~ to!(string)(++failureId) ~ ") ";
			auto whitespace = toWhitespace(str.length);

			writeln(str, description.message, " ", test.message);
			writeln(whitespace, "# ", test.exception.file, ".d:", test.exception.line);
			writeln(whitespace, "Stack trace:");
			write(whitespace);
		}
	}

	void printNumberOfPending ()
	{
		if (hasPending)
			write(", ", numberOfPending, " pending");
	}

	void printSuccess ()
	{
		writeln("All ", numberOfTests, pluralize(" test", numberOfTests), " passed successfully.");
	}

	bool isAllTestsSuccessful ()
	{
		return !hasPending && !hasFailures;
	}

	bool hasPending ()
	{
		return numberOfPending > 0;
	}

	bool hasFailures ()
	{
		return numberOfFailures > 0;
	}

	Use!(void delegate ()) execute ()
	{
		Use!(void delegate ()) use;

		use.args[0] = &executeImpl;

		return use;
	}

	void executeImpl (void delegate () dg)
	{
		auto before = this.before;
		auto after = this.after;

		if (before) before();
		if (dg) dg();
		if (after) after();
	}

	string toWhitespace (size_t value)
	{
		string str;

		for (size_t i = 0; i < value; i++)
			str ~= ' ';

		return str;
	}

	string pluralize (string str, size_t value)
	{
		if (value == 1)
			return str;

		return str ~ "s";
	}
}