/**
 * Copyright: Copyright (c) 2007-2008 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: 2007
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 * 
 */
module orange.util.io;

version (Tango)
{
	import tango.io.Stdout;
	import tango.io.Console;
	
	import orange.util.string;
}

else 
	import std.stdio;

/**
 * Print to the standard output
 * 
 * Params:
 *     args = what to print
 */
void print (A...)(A args)
{
	version (Tango)
	{
		const string fmt = "{}{}{}{}{}{}{}{}"
					        "{}{}{}{}{}{}{}{}"
					        "{}{}{}{}{}{}{}{}";
				
		static assert (A.length <= fmt.length / 2, "mambo.io.print :: too many arguments");
		
		Stdout.format(fmt[0 .. args.length * 2], args).flush;
	}
		
	
	else
		foreach(t ; a)
			writef(t);
}

/**
 * Print to the standard output, adds a new line
 * 
 * Params:
 *     args = what to print
 */
void println (A...)(A args)
{
	version (Tango)
	{
		const string fmt = "{}{}{}{}{}{}{}{}"
					        "{}{}{}{}{}{}{}{}"
					        "{}{}{}{}{}{}{}{}";

		static assert (A.length <= fmt.length / 2, "mambo.io.println :: too many arguments");
		
		Stdout.formatln(fmt[0 .. args.length * 2], args);
	}

	else
	{
		foreach(t ; args)
			writef(t);
		
		writef("\n");
	}
}

/**
 * Read from the standard input
 * 
 * Returns: what was read
 */
string read ()
{
	return Cin.get;
}
