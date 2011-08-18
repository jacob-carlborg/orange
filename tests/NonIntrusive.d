/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 18, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.NonIntrusive;

import orange.core._;
import orange.serialization.Serializer;
import orange.serialization.archives.XMLArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XMLArchive!(char) archive;

class Foo
{
	private int a_;
	private int b_;
	
	int a () { return a_; }
	int a (int a) { return a_ = a; }
	int b () { return b_; }
	int b (int b) { return b_ = b; }
}

Foo foo;
int i;

void toData (Foo foo, Serializer serializer, Serializer.Data key)
{
	i++;
	serializer.serialize(foo.a, "a");
	serializer.serialize(foo.b, "b");
}

void fromData (ref Foo foo, Serializer serializer, Serializer.Data key)
{
	i++;
	foo.a = serializer.deserialize!(int)("a");
	foo.b = serializer.deserialize!(int)("b");
}

unittest
{
	archive = new XMLArchive!(char);
	serializer = new Serializer(archive);
	
	serializer.registerSerializer(Foo.classinfo.name, &toData);
	serializer.registerDeserializer(Foo.classinfo.name, &fromData);
	
	foo = new Foo;
	foo.a = 3;
	foo.b = 4;
	i = 3;

	describe("serialize object using a non-intrusive method") in {
		it("should return a custom serialized object") in {
			serializer.serialize(foo);

			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.NonIntrusive.Foo" type="Foo" key="0" id="0"`));
			assert(archive.data().containsXmlTag("int", `key="a" id="1"`, "3"));
			assert(archive.data().containsXmlTag("int", `key="b" id="2"`, "4"));
			
			assert(i == 4);
		};
	};
	
	describe("deserialize object using a non-intrusive method") in {
		it("short return a custom deserialized object equal to the original object") in {
			auto f = serializer.deserialize!(Foo)(archive.untypedData);

			assert(foo.a == f.a);
			assert(foo.b == f.b);
			
			assert(i == 5);
		};
	};
}