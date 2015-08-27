/**
 * Copyright: Copyright (c) 2013 Jacob Carlborg. All rights reserved.
 * Authors: Juan Manuel
 * Version: Initial created: Apr 14, 2013
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.EnumConstantMember;

import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class G
{
    int a;
    enum int someConstant = 4 * 1024;
}

G g;

unittest
{
    archive = new XmlArchive!(char);
    serializer = new Serializer(archive);

    g = new G;
    g.a = 123;

    describe("serialize enum") in {
        it("shouldn't fail to compile when there is a constant enum member") in {
            serializer.reset();
            serializer.serialize(g);

            assert(archive.data().containsDefaultXmlContent());
            assert(archive.data().containsXmlTag("object", `runtimeType="tests.EnumConstantMember.G" type="tests.EnumConstantMember.G" key="0" id="0"`));
            assert(archive.data().containsXmlTag("int", `key="a" id="1"`, "123"));
        };
    };


    describe("deserialize enum") in {
        it("shouldn't fail to deserialize when there is a constant enum member") in {
            auto gDeserialized = serializer.deserialize!(G)(archive.untypedData);
            assert(g.a == gDeserialized.a);
        };
    };
}
