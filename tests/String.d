/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.String;

import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class C
{
    string str;
    wstring wstr;
    dstring dstr;
}

C c;
C u;

unittest
{
    archive = new XmlArchive!(char);
    serializer = new Serializer(archive);

    c = new C;
    c.str = "foo";
    c.wstr = "bar";
    c.dstr = "foobar";

    describe("serialize strings") in {
        it("should return serialized strings") in {
            auto expected2066 = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.String.C" type="tests.String.C" key="0" id="0">
            <string type="immutable(wchar)" length="3" key="wstr" id="2">bar</string>
            <string type="immutable(char)" length="3" key="str" id="1">foo</string>
            <string type="immutable(dchar)" length="6" key="dstr" id="3">foobar</string>
        </object>
    </data>
</archive>
xml";

            auto expected2067 = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.String.C" type="tests.String.C" id="0" key="0">
            <string id="2" type="immutable(wchar)" length="3" key="wstr">bar</string>
            <string id="3" type="immutable(dchar)" length="6" key="dstr">foobar</string>
            <string id="1" type="immutable(char)" length="3" key="str">foo</string>
        </object>
    </data>
</archive>
xml";
            static if (__VERSION__ >= 2067) auto expected = expected2067;
            else auto expected = expected2066;

            serializer.reset;
            serializer.serialize(c);

            assert(expected.equalToXml(archive.data));
        };
    };

    describe("deserialize string") in {
        it("should return a deserialized string equal to the original string") in {
            auto cDeserialized = serializer.deserialize!(C)(archive.untypedData);

            assert(c.str == cDeserialized.str);
            assert(c.wstr == cDeserialized.wstr);
            assert(c.dstr == cDeserialized.dstr);
        };
    };

    u = new C;
    u.str = "foo åäö";
    u.wstr = "foo ÅÄÖ";
    u.dstr = "foo åäö ÅÄÖ";

    describe("serialize Unicode strings") in {
        it("should return a serialized string containing proper Unicode") in {
            auto expected2066 = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.String.C" type="tests.String.C" key="0" id="0">
            <string type="immutable(wchar)" length="7" key="wstr" id="2">foo ÅÄÖ</string>
            <string type="immutable(char)" length="10" key="str" id="1">foo åäö</string>
            <string type="immutable(dchar)" length="11" key="dstr" id="3">foo åäö ÅÄÖ</string>
        </object>
    </data>
</archive>
xml";

            auto expected2067 = q"xml
<?xml version="1.0" encoding="UTF-8"?>
<archive version="1.0.0" type="org.dsource.orange.xml">
    <data>
        <object runtimeType="tests.String.C" type="tests.String.C" id="0" key="0">
            <string id="2" type="immutable(wchar)" length="7" key="wstr">foo ÅÄÖ</string>
            <string id="3" type="immutable(dchar)" length="11" key="dstr">foo åäö ÅÄÖ</string>
            <string id="1" type="immutable(char)" length="10" key="str">foo åäö</string>
        </object>
    </data>
</archive>
xml";
            static if (__VERSION__ >= 2067) auto expected = expected2067;
            else auto expected = expected2066;

            serializer.reset;
            serializer.serialize(u);

            assert(expected.equalToXml(archive.data));
        };
    };

    describe("deserialize Unicode string") in {
        it("should return a deserialize Unicode string equal to the original strings") in {
            auto uDeserialized = serializer.deserialize!(C)(archive.untypedData);

            assert(u.str == uDeserialized.str);
            assert(u.wstr == uDeserialized.wstr);
            assert(u.dstr == uDeserialized.dstr);
        };
    };
}
