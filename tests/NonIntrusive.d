/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 18, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.NonIntrusive;

import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class Base
{
    int x;
}

class Foo : Base
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
    serializer.serializeBase(foo);
}

void fromData (ref Foo foo, Serializer serializer, Serializer.Data key)
{
    i++;
    foo.a = serializer.deserialize!(int)("a");
    foo.b = serializer.deserialize!(int)("b");
    serializer.deserializeBase(foo);
}

unittest
{
    archive = new XmlArchive!(char);
    serializer = new Serializer(archive);

    foo = new Foo;
    foo.a = 3;
    foo.b = 4;
    foo.x = 5;
    i = 3;

    describe("serialize object using a non-intrusive method") in {
        it("should return a custom serialized object") in {
            auto expected = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.NonIntrusive.Foo" type="tests.NonIntrusive.Foo" key="0" id="0">
            <int key="a" id="1">3</int>
            <int key="b" id="2">4</int>
            <base type="tests.NonIntrusive.Base" key="1" id="3">
                <int key="x" id="4">5</int>
            </base>
        </object>
    </data>
</archive>
xml";
            Serializer.registerSerializer!(Foo)(&toData);
            Serializer.registerDeserializer!(Foo)(&fromData);

            serializer.serialize(foo);

            assert(i == 4);
            assert(expected.equalToXml(archive.data));
        };
    };

    describe("deserialize object using a non-intrusive method") in {
        it("short return a custom deserialized object equal to the original object") in {
            auto f = serializer.deserialize!(Foo)(archive.untypedData);

            assert(foo.a == f.a);
            assert(foo.b == f.b);
            assert(foo.x == f.x);

            assert(i == 5);

            Serializer.resetSerializers;
        };
    };
}
