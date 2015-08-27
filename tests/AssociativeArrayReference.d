/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.AssociativeArrayReference;

import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class K
{
    int[int] a;
    int[int] b;
}

K k;

unittest
{
    archive = new XmlArchive!(char);
    serializer = new Serializer(archive);

    k = new K;
    k.a = [3 : 4, 1 : 2, 39 : 472, 6 : 7];
    k.b = k.a;

    describe("serialize associative array references") in {
        it("should return a serialized associative array and a serialized reference") in {
            auto expected = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.AssociativeArrayReference.K" type="tests.AssociativeArrayReference.K" key="0" id="0">
            <associativeArray keyType="int" length="4" valueType="int" key="a" id="1">
                <key key="0">
                    <int key="0" id="2">1</int>
                </key>
                <value key="0">
                    <int key="0" id="3">2</int>
                </value>
                <key key="1">
                    <int key="1" id="4">3</int>
                </key>
                <value key="1">
                    <int key="1" id="5">4</int>
                </value>
                <key key="2">
                    <int key="2" id="6">6</int>
                </key>
                <value key="2">
                    <int key="2" id="7">7</int>
                </value>
                <key key="3">
                    <int key="3" id="8">39</int>
                </key>
                <value key="3">
                    <int key="3" id="9">472</int>
                </value>
            </associativeArray>
            <reference key="b">1</reference>
        </object>
    </data>
</archive>
xml";
            serializer.reset();
            serializer.serialize(k);

            assert(expected.equalToXml(archive.data));
        };
    };

    describe("deserialize associative array references") in {
        it("should return two deserialized associative arrays pointing to the same data") in {
            auto kDeserialized = serializer.deserialize!(K)(archive.untypedData);

            assert(kDeserialized.a is kDeserialized.b);
        };
    };
}
