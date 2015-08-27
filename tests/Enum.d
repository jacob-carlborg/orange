/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Enum;

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
            auto expected = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.Enum.G" type="tests.Enum.G" key="0" id="0">
            <enum type="tests.Enum.Foo" baseType="int" key="foo" id="1">1</enum>
        </object>
    </data>
</archive>
xml";

            serializer.reset();
            serializer.serialize(g);

            assert(expected.equalToXml(archive.data));
        };
    };


    describe("deserialize enum") in {
        it("should return an enum equal to the original enum") in {
            auto gDeserialized = serializer.deserialize!(G)(archive.untypedData);
            assert(g.foo == gDeserialized.foo);
        };
    };
}
