#!/bin/sh

dmd -unittest -ofunittest \
orange/core/io.d \
orange/core/string.d \
orange/core/_.d \
orange/serialization/Events.d \
orange/serialization/RegisterWrapper.d \
orange/serialization/Serializable.d \
orange/serialization/SerializationException.d \
orange/serialization/Serializer.d \
orange/serialization/_.d \
orange/serialization/archives/Archive.d \
orange/serialization/archives/ArchiveException.d \
orange/serialization/archives/XMLArchive.d \
orange/serialization/archives/_.d \
orange/test/UnitTester.d \
orange/util/CTFE.d \
orange/util/Reflection.d \
orange/util/Traits.d \
orange/util/Use.d \
orange/util/_.d \
orange/util/collection/Array.d \
orange/util/collection/_.d \
orange/xml/PhobosXML.d \
orange/xml/XMLDocument.d \
orange/xml/_.d \
tests/all.d \
tests/Array.d \
tests/AssociativeArray.d \
tests/AssociativeArrayReference.d \
tests/Enum.d \
tests/Object.d \
tests/Pointer.d \
tests/Primitive.d \
tests/Slice.d \
tests/String.d \
tests/Struct.d \
tests/Typedef.d \
tests/Util.d \
tests/_.d

if [ "$?" = 0 ] ; then
	./unittest
fi