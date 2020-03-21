/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.NonCopyableStruct;

import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

struct B
{
    @disable this(this);
    @disable ref B opAssign () (auto ref B other);

    bool opEquals (ref const B) const
    {
        return true;
    }
}

B b;

unittest
{
    archive = new XmlArchive!(char);
    serializer = new Serializer(archive);

    describe("serialize struct") in {
        it("should return a serialized struct") in {
auto expected = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <struct type="tests.Struct.B" key="0" id="0"/>
    </data>
</archive>
xml";
            serializer.reset;
            serializer.serialize(B());

            assert(expected.equalToXml(archive.data));
        };
    };

    describe("deserialize struct") in {
        it("should return a deserialized struct equal to the original struct") in {
            auto bDeserialized = serializer.deserialize!(B)(archive.untypedData);
            assert(b == bDeserialized);
        };
    };
}
