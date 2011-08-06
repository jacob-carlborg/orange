/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Typedef;

import orange.core.string;
import orange.serialization.Serializer;
import orange.serialization.archives.XMLArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XMLArchive!(char) archive;

typedef int Int;

class I
{
	Int a;
}

I i;

unittest
{
	archive = new XMLArchive!(char);
	serializer = new Serializer(archive);

	i = new I;
	i.a = 1;

	describe("serialize typedef") in {
		it("should return a serialized typedef") in {
			serializer.reset();
			serializer.serialize(i);
			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.Typedef.I" type="I" key="0" id="0"`));
			assert(archive.data().containsXmlTag("typedef", `type="Int" key="a" id="2"`));
			assert(archive.data().containsXmlTag("int", `key="1" id="3"`, "1"));
		};
	};
	
	// describe("deserialize typedef") in {
	// 	it("should return a deserialized typedef equal to the original typedef") in {
	// 		auto iDeserialized = serializer.deserialize!(I)(archive.untypedData);
	// 		assert(i.a == iDeserialized.a);
	// 	};
	// };
}