/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Array;

import orange.core._;
import orange.serialization.Serializer;
import orange.serialization.archives.XMLArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XMLArchive!(char) archive;

class D
{
	int[] arr;
}

D d;

unittest
{
	archive = new XMLArchive!(char);
	serializer = new Serializer(archive);

	d = new D;
	d.arr = [27, 382, 283, 3820, 32, 832].dup;

	describe("serialize array") in {
		it("should return a serialized array") in {
			serializer.reset;
			serializer.serialize(d);

			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.Array.D" type="D" key="0" id="0"`));
			assert(archive.data().containsXmlTag("array", `type="int" length="6" key="arr" id="1"`));
			assert(archive.data().containsXmlTag("int", `key="0" id="2"`, "27"));
			assert(archive.data().containsXmlTag("int", `key="1" id="3"`, "382"));
			assert(archive.data().containsXmlTag("int", `key="2" id="4"`, "283"));
			assert(archive.data().containsXmlTag("int", `key="3" id="5"`, "3820"));
			assert(archive.data().containsXmlTag("int", `key="4" id="6"`, "32"));
			assert(archive.data().containsXmlTag("int", `key="5" id="7"`, "832"));
		};
	};
	
	describe("deserialize array") in {
		it("should return a deserialize array equal to the original array") in {
			auto dDeserialized = serializer.deserialize!(D)(archive.untypedData);
			assert(d.arr == dDeserialized.arr);
		};
	};
}