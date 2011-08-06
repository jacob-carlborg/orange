/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Object;

import orange.core.string;
import orange.serialization.Serializer;
import orange.serialization.archives.XMLArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XMLArchive!(char) archive;

class A
{
	equals_t opEquals (Object other)
	{
		if (auto o = cast(A) other)
			return true;
		
		return false;
	}
}

A a;

unittest
{
	archive = new XMLArchive!(char);
	serializer = new Serializer(archive);

	a = new A;

	describe("serialize object") in {
		it("should return a serialized object") in {
			serializer.reset;
			serializer.serialize(a);
	
			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().contains(`<object runtimeType="tests.Object.A" type="A" key="0" id="0"/>`));
		};
	};
	
	describe("deserialize object") in {
		it("should return a deserialized object equal to the original object") in {
			auto aDeserialized = serializer.deserialize!(A)(archive.untypedData);
			assert(a == aDeserialized);
		};
	};
}