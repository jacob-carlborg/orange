/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Oct 17, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.test.UnitTester;

version (Tango)
{
	import tango.core.Exception;
	import tango.io.device.File;
	import tango.io.FilePath;
	import tango.io.stream.Lines;
	import tango.sys.Environment;
	import tango.util.Convert;
}
	

else
{
	import core.exception;
	import std.conv;
	
	private alias AssertError AssertException;
}


import orange.core._;
import orange.util._;

/**
 * 
 * Params:
 *     message = 
 * Returns:
 */
Use!(void delegate (), string) describe (string message)
{
	return UnitTester.instance.describe(message);
}

/**
 * 
 * Params:
 *     message = 
 * Returns:
 */
Use!(void delegate (), string) it (string message)
{
	return UnitTester.instance.test(message);
}

/**
 * 
 * Returns:
 */
void delegate () before ()
{
	return UnitTester.instance.before;
}

/**
 * 
 * Params:
 *     before = 
 * Returns:
 */
void delegate () before (void delegate () before)
{
	return UnitTester.instance.before = before;
}

/**
 * 
 * Returns:
 */
void delegate () after ()
{
	return UnitTester.instance.after;
}

/**
 * 
 * Params:
 *     after = 
 * Returns:
 */
void delegate () after (void delegate () after)
{
	return UnitTester.instance.after = after;
}

/**
 * 
 *
 */
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

		print("\n", numberOfTests, " ", pluralize("test", numberOfTests),", ", numberOfFailures, " ", pluralize("failure", numberOfFailures));
		printNumberOfPending;
		println();
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
		println(indentation, description.message);

		restore(indentation) in {
			indentation ~= defaultIndentation;

			foreach (i, ref test ; description.tests)
			{
				print(indentation, "- ", test.message);
				
				if (test.isPending)
					print(" (PENDING: Not Yet Implemented)");
				
				if (test.failed)
					print(" (FAILED - ", ++failureId, ')');
				
				println();
			}
		};
	}
	
	void printPending ()
	{
		if (!hasPending)
			return;
		
		println("\nPending:");

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
			println(indentation, description.message, " ", test.message, "\n", indentation, indentation, "# Not Yet Implemented");
	}
	
	void printFailures ()
	{
		if (!hasFailures)
			return;
		
		println("\nFailures:");

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
			
			println(str, description.message, " ", test.message);			
			println(whitespace, "# ", test.exception.file, ".d:", test.exception.line);
			println(whitespace, "Stack trace:");
			print(whitespace);
			
			version (Tango)
			{
				test.exception.writeOut(&printStackTrace);
				println();
				println(readFailedTest(test));
			}				
		}
	}
	
	void printStackTrace (string str)
	{
		return print(str);
		
		/*if (str.find("start") < size_t.max ||
		    str.find("main") < size_t.max ||
		    str.find("rt.compiler.") < size_t.max ||
		    str.find("orange.") ||
		    str.find(":0") ||
		    str.find("_d_assert") ||
		    str.find("onAssertError") ||
		    str.find("tango.core.Exception.AssertException._ctor ") ||
		    str.find("object.") ||
		    str.find("tango.core.tools."))
				return;*/
	}

	version (Tango)
	{
		string readFailedTest (ref Test test, int numberOfSurroundingLines = 3)
		{		
			auto filename = test.exception.file.dup.replace('.', '/');

			filename ~= ".d";
			filename = Environment.toAbsolute(filename);
			auto lineNumber = test.exception.line;
			string str;
			auto file = new File(filename);		

			foreach (i, line ; new Lines!(char)(file))			
				if (i >= (lineNumber - 1) - numberOfSurroundingLines && i <= (lineNumber - 1) + numberOfSurroundingLines)
					str ~= line ~ '\n';

			file.close;

			return str;
		}
	}
	
	void printNumberOfPending ()
	{
		if (hasPending)
			print(", ", numberOfPending, " pending");
	}
	
	void printSuccess ()
	{
		println("All ", numberOfTests, pluralize(" test", numberOfTests), " passed successfully.");
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
	
	string pluralize (string str, int value)
	{
		if (value == 1)
			return str;
		
		return str ~ "s";
	}
}