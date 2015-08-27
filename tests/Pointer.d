/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Pointer;

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

class OutOfOrder
{
    int* ptr;
    int value;
    int* ptr2;
}

OutOfOrder outOfOrder;
OutOfOrder outOfOrderDeserialized;
int outOfOrderPointee;

unittest
{
    archive = new XmlArchive!(char);
    serializer = new Serializer(archive);

    pointee = 3;
    f = new F;
    f.value = 9;
    f.ptr = &f.value;
    f.ptr2 = &pointee;

    outOfOrderPointee = 3;
    outOfOrder = new OutOfOrder;
    outOfOrder.value = 9;
    outOfOrder.ptr = &outOfOrder.value;
    outOfOrder.ptr2 = &outOfOrderPointee;

    describe("serialize pointer") in {
        it("should return a serialized pointer") in {
            auto expected = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.Pointer.F" type="tests.Pointer.F" key="0" id="0">
            <int key="value" id="1">9</int>
            <pointer key="ptr" id="2">
                <reference key="1">1</reference>
            </pointer>
            <pointer key="ptr2" id="3">
                <int key="2" id="4">3</int>
            </pointer>
        </object>
    </data>
</archive>
xml";
            serializer.reset();
            serializer.serialize(f);

            assert(expected.equalToXml(archive.data));
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

    describe("serialize pointer out of order") in {
        it("should return a serialized pointer") in {
            auto expected = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.Pointer.OutOfOrder" type="tests.Pointer.OutOfOrder" key="0" id="0">
            <pointer key="ptr" id="1">
                <int key="1" id="2">9</int>
            </pointer>
            <reference key="value">1</reference>
            <pointer key="ptr2" id="4">
                <int key="2" id="5">3</int>
            </pointer>
        </object>
    </data>
</archive>
xml";
            serializer.reset();
            serializer.serialize(outOfOrder);

            assert(expected.equalToXml(archive.data));
        };
    };

    describe("deserialize pointer out of order") in {
        outOfOrderDeserialized = serializer.deserialize!(OutOfOrder)(archive.untypedData);

        it("should return a deserialized pointer equal to the original pointer") in {
            assert(*outOfOrder.ptr == *outOfOrderDeserialized.ptr);
        };

        it("the pointer should point to the deserialized value") in {
            assert(outOfOrderDeserialized.ptr == &outOfOrderDeserialized.value);
        };
    };
}
