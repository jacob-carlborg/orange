/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Pointer;

import orange.core.string;
import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class F
{
	int value;
	int* ptr;
	int* ptr2;
}

F f;
F fDeserialized;
int pointee;

unittest
{
	archive = new XmlArchive!(char);
	serializer = new Serializer(archive);

	pointee = 3;
	f = new F;
	f.value = 9;
	f.ptr = &f.value;
	f.ptr2 = &pointee;

	describe("serialize pointer") in {
		it("should return a serialized pointer") in {
			serializer.reset();
			serializer.serialize(f);
	
			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.Pointer.F" type="F" key="0" id="0"`));
			assert(archive.data().containsXmlTag("pointer", `key="ptr" id="2"`));
			assert(archive.data().containsXmlTag("reference", `key="1"`, "1"));
			assert(archive.data().containsXmlTag("int", `key="value" id="1"`, "9"));
		};
	};
	
	describe("deserialize pointer") in {
		fDeserialized = serializer.deserialize!(F)(archive.untypedData);
	
		it("should return a deserialized pointer equal to the original pointer") in {
			assert(*f.ptr == *fDeserialized.ptr);
		};
		
		it("the pointer should point to the deserialized value") in {
			assert(fDeserialized.ptr == &fDeserialized.value);
		};
	};
}