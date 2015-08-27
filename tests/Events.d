/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 7, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Events;

import orange.serialization.Serializer;
import orange.serialization.Events;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

int b;
int c;

int udaB;
int udaC;

class Events
{
    int a;
    int d;

    int udaA;
    int udaD;

    void serializing ()
    {
        a = 3;
    }

    mixin OnSerializing!(serializing);

    @onSerializing void udaSerializing ()
    {
        udaA = 3;
    }

    void serialized ()
    {
        b = 4;
    }

    mixin OnSerialized!(serialized);

    @onSerialized void udaSerialized ()
    {
        udaB = 4;
    }

    void deserializing ()
    {
        c = 5;
    }

    mixin OnDeserializing!(deserializing);

    @onDeserializing void udaDeserializing ()
    {
        udaC = 5;
    }

    void deserialized ()
    {
        d = 6;
    }

    mixin OnDeserialized!(deserialized);

    @onDeserialized void udaDeserialized ()
    {
        udaD = 6;
    }
}

Events events;

unittest
{
    archive = new XmlArchive!(char);
    serializer = new Serializer(archive);

    events = new Events;

    describe("serialize a class with event handlers") in {
        it("should return serialized class with the correct values set by the event handlers") in {
            auto expected =q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.Events.Events" type="tests.Events.Events" key="0" id="0">
            <int key="a" id="1">3</int>
            <int key="d" id="2">0</int>
            <int key="udaA" id="3">3</int>
            <int key="udaD" id="4">0</int>
        </object>
    </data>
</archive>
xml";
            serializer.reset;
            serializer.serialize(events);

            assert(b == 4);
            assert(udaB == 4);
            assert(expected.equalToXml(archive.data));
        };
    };

    describe("deserialize class with a base class") in {
        it("should return a deserialized string equal to the original string") in {
            auto eventsDeserialized = serializer.deserialize!(Events)(archive.untypedData);

            assert(eventsDeserialized.a == 3);
            assert(eventsDeserialized.d == 6);

            assert(eventsDeserialized.udaA == 3);
            assert(eventsDeserialized.udaD == 6);

            assert(c == 5);
            assert(udaC == 5);
        };
    };
}
