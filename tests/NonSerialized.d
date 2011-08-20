/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 20, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.NonSerialized;

import orange.core._;
import orange.serialization.Serializer;
import orange.serialization.Serializable;
import orange.serialization.archives.XMLArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XMLArchive!(char) archive;

class Bar
{
	mixin NonSerialized;
	
	int c;
}

class Foo
{
	int a;
	int b;
	Bar bar;
	
	mixin NonSerialized!(a);
}

Foo foo;

unittest
{
	archive = new XMLArchive!(char);
	serializer = new Serializer(archive);
	
	foo = new Foo;
	foo.a = 3;
	foo.b = 4;
	foo.bar = new Bar;

	describe("serialize object with a non-serialized field") in {
		it("should return serialized object with only one serialized field") in {
			serializer.serialize(foo);

			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.NonSerialized.Foo" type="Foo" key="0" id="0"`));
			assert(archive.data().containsXmlTag("int", `key="b" id="1"`, "4"));
			assert(!archive.data().containsXmlTag("object", `runtimeType="tests.NonSerialized.Bar" type="Bar" key="bar" id="2"`));
		};
	};
	
	describe("deserialize object with a non-serialized field") in {
		it("short return deserialized object equal to the original object, where only one field is deserialized") in {
			auto f = serializer.deserialize!(Foo)(archive.untypedData);

			assert(foo.b == f.b);
			assert(f.a == foo.a.init);
			assert(f.bar is foo.bar.init);
		};
	};
}