/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.util.Traits;

public import mambo.util.Traits;

import orange.serialization.Serializable;
import orange.serialization.archives.Archive;
import orange.util._;

template isArchive (T)
{
	const isArchive = is(typeof({
		alias T.DataType Foo;
	})) &&

	is(typeof(T.archive(0, TypeOfDataType!(T).init, {}))) &&
	is(typeof(T.unarchive!(int))) && 
	is(typeof(T.beginArchiving)) &&
	is(typeof(T.beginUnarchiving(TypeOfDataType!(T).init))) &&
	is(typeof(T.archiveBaseClass!(Object))) &&
	is(typeof(T.unarchiveBaseClass!(Object))) &&
	is(typeof(T.reset)) &&
	is(typeof({TypeOfDataType!(T) a = T.data;})) &&
	is(typeof(T.unarchiveAssociativeArrayVisitor!(int[string])));
	
}

template isSerializable (T, ArchiveType)
{
	const isSerializable = is(typeof(T.toData(ArchiveType.init, ArchiveType.DataType.init))) && is(typeof(T.fromData(ArchiveType.init, ArchiveType.DataType.init)));
}

template isISerializable (T)
{
	const isISerializable = is(T : ISerializable);
}

template TypeOfDataType (T)
{
	alias T.DataType TypeOfDataType;
}