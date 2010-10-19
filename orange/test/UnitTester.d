/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Oct 17, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.test.UnitTester;

import tango.core.Exception;
import orange.core._;
import orange.util._;

class UnitTester
{	
	private
	{
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
				return !exception;
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
		
		Test[] tests;
		AssertException[] exceptions;
		void delegate () pre_;
		void delegate () post_;
		size_t failures;
		size_t pending;
		size_t lastIndex = size_t.max;
	}	
	
	Use!(void delegate (), string) test (string message)
	{
		tests ~= Test(null, message);
		lastIndex++;
		
		Use!(void delegate (), string) use;
		
		use.args[0] = &internalTest;		
		use.args[1] = message;
		
		return use;
	}
	
	void run ()
	{
		foreach (test ; tests)
		{
			if (test.isPending)
				pending++;
			
			try
			{
				execute in {
					test.run();
				};				
			}				
			
			catch (AssertException e)
			{
				exceptions ~= e;
				failures++;
			}				
		}
		
		printResult;
	}
	
	void delegate () pre ()
	{
		return pre_;
	}
	
	void delegate () pre (void delegate () pre)
	{
		return pre_ = pre;
	}
	
	void delegate () post ()
	{
		return post_;
	}

	void delegate () post (void delegate () post)
	{
		return post_ = post;
	}
	
	private void internalTest (void delegate () dg, string message)
	{
		tests[lastIndex] = Test(dg, message);
	}
	
	private void printResult ()
	{	
		if (isAllTestsSuccessful)
			return printSuccess();
		
		foreach (test ; tests)
		{
			print("- ", test.message);
			
			if (test.isPending)
				print(" ", "(PENDING: Not Yet Implemented)");
			
			println();
		}
		
		print("\n", tests.length, " test, ", failures, " failures");
		printPending();	
		println();
	}
	
	private void printPending ()
	{
		if (hasPending)
			print(", ", pending, " pending");
	}
	
	private void printSuccess ()
	{
		println("All ", tests.length, " tests passed successfully.");
	}
	
	private bool isAllTestsSuccessful ()
	{
		return !hasPending && !hasFailures;
	}
	
	private bool hasPending ()
	{
		return pending > 0;
	}
	
	private bool hasFailures ()
	{
		return failures > 0;
	}
	
	private Use!(void delegate ()) execute ()
	{
		Use!(void delegate ()) use;
		
		use.args[0] = &executeImpl;
		
		return use;
	}
	
	private void executeImpl (void delegate () dg)
	{
		if (pre) pre();
		if (dg) dg();
		if (post) post();
	}
}