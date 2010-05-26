/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 30, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.SerializationException;

import orange.util.string;

class SerializationException : Exception
{	
	this (string message)
	{
		super(message);
	}
	
	this (string message, string file, long line)
	{
		version (Tango)
			super(message, file, line);
		
		else
			super(message);
	}
	
	this (Exception exception)
	{
		super(exception.msg, exception.file, exception.line, exception.next, exception.info);
	}
}