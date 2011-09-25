/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Enum;

import orange.core.string;
import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

enum Foo
{
	a,
	b,
	c
}

class G
{
	Foo foo;
}

G g;

unittest
{
	archive = new XmlArchive!(char);
	serializer = new Serializer(archive);

	g = new G;
	g.foo = Foo.b;

	describe("serialize enum") in {
		it("should return a serialized enum") in {
			serializer.reset();
			serializer.serialize(g);
	
			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.Enum.G" type="G" key="0" id="0"`));
			assert(archive.data().containsXmlTag("enum", `type="Foo" baseType="int" key="foo" id="1"`, "1"));
		};
	};
	
	
	describe("deserialize enum") in {
		it("should return an enum equal to the original enum") in {
			auto gDeserialized = serializer.deserialize!(G)(archive.untypedData);
			assert(g.foo == gDeserialized.foo);
		};
	};
}