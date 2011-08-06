/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.AssociativeArrayReference;

import orange.core.string;
import orange.serialization.Serializer;
import orange.serialization.archives.XMLArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XMLArchive!(char) archive;

class K
{
	int[int] a;
	int[int] b;
}

K k;

unittest
{
	archive = new XMLArchive!(char);
	serializer = new Serializer(archive);

	k = new K;
	k.a = [3 : 4, 1 : 2, 39 : 472, 6 : 7];
	k.b = k.a;

	describe("serialize associative array references") in {
		it("should return a serialized associative array and a serialized reference") in {
			serializer.reset();
			serializer.serialize(k);
	
			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.AssociativeArrayReference.K" type="K" key="0" id="0"`));
			version (Tango) assert(archive.data().containsXmlTag("associativeArray", `keyType="int" valueType="int" length="4" key="a" id="1"`));
	
			assert(archive.data().containsXmlTag("key", `key="0"`));
			assert(archive.data().containsXmlTag("int", `key="0" id="2"`, "1"));
			assert(archive.data().containsXmlTag("value", `key="0"`));
			assert(archive.data().containsXmlTag("int", `key="0" id="3"`, "2"));
			
			assert(archive.data().containsXmlTag("key", `key="1"`));
			assert(archive.data().containsXmlTag("int", `key="1" id="4"`, "3"));
			assert(archive.data().containsXmlTag("value", `key="1"`));
			assert(archive.data().containsXmlTag("int", `key="1" id="5"`, "4"));
			
			assert(archive.data().containsXmlTag("key", `key="2"`));
			assert(archive.data().containsXmlTag("int", `key="2" id="6"`, "6"));
			assert(archive.data().containsXmlTag("value", `key="2"`));
			assert(archive.data().containsXmlTag("int", `key="2" id="7"`, "7"));
			
			assert(archive.data().containsXmlTag("key", `key="3"`));
			assert(archive.data().containsXmlTag("int", `key="3" id="8"`, "39"));
			assert(archive.data().containsXmlTag("value", `key="3"`));
			assert(archive.data().containsXmlTag("int", `key="3" id="9"`, "472"));
	
			assert(archive.data().containsXmlTag("reference", `key="b"`, "1"));
		};
	};
	
	describe("deserialize associative array references") in {
		it("should return two deserialized associative arrays pointing to the same data") in {
			auto kDeserialized = serializer.deserialize!(K)(archive.untypedData);
			
			assert(kDeserialized.a is kDeserialized.b);
		};
	};
}