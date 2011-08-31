/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 30, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.SerializationException;

import orange.core.string;

version (Tango)
	alias Exception ExceptionBase;

else
	alias Throwable ExceptionBase;

/**
 * 
 * Authors: doob
 */
class SerializationException : ExceptionBase
{	
	/**
	 * 
	 * Params:
	 *     message =
	 */
	this (string message)
	{
		super(message);
	}
	
	/**
	 * 
	 * Params:
	 *     message = 
	 *     file = 
	 *     line =
	 */
	this (string message, string file, long line)
	{
		version (Tango)
			super(message, file, line);
		
		else
			super(message);
	}
	
	version (Tango)
	{
		/**
		 * 
		 * Params:
		 *     exception =
		 */
		this (ExceptionBase exception)
		{
			super(exception.msg, exception.file, exception.line, exception.next, exception.info);
		}
	}
	
	else
	{
		/**
		 * 
		 * Params:
		 *     exception =
		 */
		this (ExceptionBase exception)
		{
			super(exception.msg, exception.file, exception.line);
		}
	}
}