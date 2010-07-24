/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 30, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.archives.ArchiveException;

import orange.serialization.SerializationException;
import orange.util.string;

class ArchiveException : SerializationException
{	
	this (string message)
	{
		super(message);
	}
	
	this (string message, string file, long line)
	{
		super(message, file, line);
	}
	
	this (ExceptionBase exception)
	{
		super(exception);
	}
}