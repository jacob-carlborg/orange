/**
 * Copyright: Copyright (c) 2012 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 7, 2012
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.NonMutable;

import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class B
{
    int a;

    pure this (int a)
    {
        this.a = a;
    }

    override equals_t opEquals (Object other)
    {
        if (auto o = cast(B) other)
            return a == o.a;

        return false;
    }
}

class A
{
    const int a;
    immutable int b;
    immutable string c;
    immutable B d;
    immutable(int)* e;

    this (int a, int b, string c, immutable B d, immutable(int)* e)
    {
        this.a = a;
        this.b = b;
        this.c = c;
        this.d = d;
        this.e = e;
    }

    override equals_t opEquals (Object other)
    {
        if (auto o = cast(A) other)
            return a == o.a &&
                b == o.b &&
                c == o.c &&
                d == o.d &&
                *e == *o.e;

        return false;
    }
}

A a;
immutable int ptr = 3;

class CTFEFieldsIssue35
{
    public immutable int FIRST;
    public immutable int SECOND1;
    public bool someFlag;

    this ()
    {
        FIRST = 1;
        SECOND1 = 1;
    }
}

unittest
{
    archive = new XmlArchive!(char);
    serializer = new Serializer(archive);

    a = new A(1, 2, "str", new immutable(B)(3), &ptr);

    describe("serialize object with immutable and const fields") in {
        it("should return a serialized object") in {
            auto expected = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.NonMutable.A" type="tests.NonMutable.A" key="0" id="0">
            <int key="a" id="1">1</int>
            <int key="b" id="2">2</int>
            <object runtimeType="tests.NonMutable.B" type="immutable(tests.NonMutable.B)" key="d" id="4">
                <int key="a" id="5">3</int>
            </object>
            <pointer key="e" id="6">
                <int key="1" id="7">3</int>
            </pointer>
            <string type="immutable(char)" length="3" key="c" id="3">str</string>
        </object>
    </data>
</archive>
xml";
            serializer.reset;
            serializer.serialize(a);

            assert(expected.equalToXml(archive.data));
        };
    };

    describe("deserialize object") in {
        it("should return a deserialized object equal to the original object") in {
            auto aDeserialized = serializer.deserialize!(A)(archive.untypedData);
            assert(a == aDeserialized);
        };
    };

    describe("serializing object with CTFE fields") in {
        it("should compile") in {
            assert(__traits(compiles, {
                serializer.serialize(new CTFEFieldsIssue35);
            }));
        };
    };
}
