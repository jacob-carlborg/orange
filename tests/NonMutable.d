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
	public immutable FIRST = 1;
	public immutable SECOND = 1;
	public bool someFlag;
}

unittest
{
	archive = new XmlArchive!(char);
	serializer = new Serializer(archive);

	a = new A(1, 2, "str", new immutable(B)(3), &ptr);

	describe("serialize object with immutable and const fields") in {
		it("should return a serialized object") in {
			serializer.reset;
			serializer.serialize(a);

			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().contains(`<object runtimeType="tests.NonMutable.A" type="tests.NonMutable.A" key="0" id="0">`));

			assert(archive.data().containsXmlTag("int", `key="a" id="1"`, "1"));
			assert(archive.data().containsXmlTag("int", `key="b" id="2"`, "2"));
			assert(archive.data().containsXmlTag("string", `type="immutable(char)" length="3" key="c" id="3"`, "str"));

			assert(archive.data().contains(`<object runtimeType="tests.NonMutable.B" type="immutable(tests.NonMutable.B)" key="d" id="4">`));

			assert(archive.data().containsXmlTag("pointer", `key="e" id="6"`));
			assert(archive.data().containsXmlTag("int", `key="1" id="7"`, "3"));
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