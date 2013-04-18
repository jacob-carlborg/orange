/**
 * Copyright: Copyright (c) 2013 Jacob Carlborg. All rights reserved.
 * Authors: Juan Manuel
 * Version: Initial created: Apr 14, 2013
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.CustomWithString;

import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class Foo
{
	int a;
	string b;

	void toData (Serializer serializer, Serializer.Data key)
	{
		i++;
		serializer.serialize(a, "x");
		serializer.serialize(b, "y");
	}

	void fromData (Serializer serializer, Serializer.Data key)
	{
		i++;
		a = serializer.deserialize!(int)("x");
		b = serializer.deserialize!(string)("y");
	}
}

Foo foo;
int i;

unittest
{
	archive = new XmlArchive!(char);
	serializer = new Serializer(archive);

	foo = new Foo;
	foo.a = 3;
	foo.b = "a string";
	i = 3;

	describe("serialize object using custom serialization methods") in {
		it("should return a custom serialized object") in {
			serializer.serialize(foo);

			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.CustomWithString.Foo" type="tests.CustomWithString.Foo" key="0" id="0"`));
			assert(archive.data().containsXmlTag("int", `key="x" id="1"`));
			assert(archive.data().containsXmlTag("string", `type="immutable(char)" length="8" key="y" id="2"`));

			assert(i == 4);
		};
	};

	describe("deserialize object using custom serialization methods") in {
		it("should deserialize the string field properly") in {
			auto f = serializer.deserialize!(Foo)(archive.untypedData);

			assert(foo.a == f.a);
			assert(foo.b == f.b);

			assert(i == 5);
		};
	};
}
