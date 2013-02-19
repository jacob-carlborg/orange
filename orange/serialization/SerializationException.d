/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 30, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.SerializationException;

/**
 * This class represents an exception, it's the base class of all exceptions used
 * throughout this library.
 */
class SerializationException : Exception
{
	/**
	 * Creates a new exception with the given message, file and line info.
	 *
	 * Params:
	 *     message = the message of the exception
	 *     file = the file where the exception occurred
	 *     line = the line in the file where the exception occurred
	 */
	this (string message, string file = __FILE__, size_t line = __LINE__)
	{
		super(message);
	}

	/**
	 * Creates a new exception out of the given exception. Used for wrapping already existing
	 * exceptions as SerializationExceptions.
	 *
	 *
	 * Params:
	 *     exception = the exception exception to wrap
	 */
	this (Exception exception)
	{
		super(exception.msg, exception.file, exception.line);
	}
}