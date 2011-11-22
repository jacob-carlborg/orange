/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.AssociativeArray;

import orange.core.string;
import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class E
{
	int[int] aa;
}

E e;

unittest
{
	archive = new XmlArchive!(char);
	serializer = new Serializer(archive);

	e = new E;
	e.aa = [3 : 4, 1 : 2, 39 : 472, 6 : 7];

	describe("serialize associative array") in {
		it("should return a serialized associative array") in {
			serializer.reset();
			serializer.serialize(e);
	
			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.AssociativeArray.E" type="tests.AssociativeArray.E" key="0" id="0"`));
			version (Tango) assert(archive.data().containsXmlTag("associativeArray", `keyType="int" valueType="int" length="4" key="aa" id="1"`));
	
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
		};
	};
	
	describe("deserialize associative array") in {
		it("should return an associative array equal to the original associative array") in {
			auto eDeserialized = serializer.deserialize!(E)(archive.untypedData);
			
			foreach (k, v ; eDeserialized.aa)
				assert(e.aa[k] == v);
			
			version (D_Version2)
				assert(e.aa == eDeserialized.aa);
		};
	};
}