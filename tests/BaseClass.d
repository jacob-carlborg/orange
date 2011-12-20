/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 7, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.BaseClass;

import orange.core.string;
import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class Base
{
	int a;
	
	int getA ()
	{
		return a;
	}
	
	int getB ()
	{
		return a;
	}
}

class Sub : Base
{
	int b;

	int getB ()
	{
		return b;
	}
}

Sub sub;
Base base;

unittest
{
	archive = new XmlArchive!(char);
	serializer = new Serializer(archive);

	sub = new Sub;
	sub.a = 3;
	sub.b = 4;
	base = sub;

	describe("serialize subclass through a base class reference") in {
		it("should return serialized subclass with the static type \"Base\" and the runtime type \"tests.BaseClass.Sub\"") in {
			Serializer.register!(Sub);
			serializer.serialize(base);
	
			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.BaseClass.Sub" type="tests.BaseClass.Base" key="0" id="0"`));
			assert(archive.data().containsXmlTag("int", `key="b" id="1"`, "4"));
			assert(archive.data().containsXmlTag("base", `type="tests.BaseClass.Base" key="1" id="2"`));
			assert(archive.data().containsXmlTag("int", `key="a" id="3"`, "3"));
		};
	};
	
	describe("deserialize subclass through a base class reference") in {
		it("should return a deserialized subclass with the static type \"Base\" and the runtime type \"tests.BaseClass.Sub\"") in {
			auto subDeserialized = serializer.deserialize!(Base)(archive.untypedData);

			assert(sub.a == subDeserialized.getA);
			assert(sub.b == subDeserialized.getB);
			
			Serializer.resetRegisteredTypes;
		};
	};
}