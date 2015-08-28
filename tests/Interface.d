/**
 * Copyright: Copyright (c) 2015 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 28, 2015
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Interface;

import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

interface Interface
{
    int b ();
}

class Foo : Interface
{
    int b_;
    int b () { return b_; }
}

class Bar
{
    Interface inter;
}

Bar bar;

unittest
{
    archive = new XmlArchive!(char);
    serializer = new Serializer(archive);

    auto foo = new Foo;
    foo.b_ = 3;

    bar = new Bar;
    bar.inter = foo;

    describe("serialize object") in {
        it("should return a serialized object") in {
            auto expected = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.Interface.Bar" type="tests.Interface.Bar" id="0" key="0">
            <object runtimeType="tests.Interface.Foo" type="tests.Interface.Interface" id="1" key="inter">
                <int id="2" key="b_">3</int>
            </object>
        </object>
    </data>
</archive>
xml";
            Serializer.register!(Foo);
            serializer.reset;
            serializer.serialize(bar);

            assert(expected.equalToXml(archive.data));
        };
    };

    describe("deserialize object") in {
        it("should return a deserialized object equal to the original object") in {
            auto barDeserialized = serializer.deserialize!(Bar)(archive.untypedData);
            assert(bar.inter.b == barDeserialized.inter.b);
        };
    };
}
