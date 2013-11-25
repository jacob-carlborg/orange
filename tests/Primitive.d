/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Primitive;

import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class H
{
	bool bool_;
	byte byte_;
	//cdouble cdouble_; // currently not suppported by to!()
	//cent cent_; // currently not implemented but a reserved keyword
	//cfloat cfloat_; // currently not suppported by to!()
	char char_;
	//creal creal_; // currently not suppported by to!()
	dchar dchar_;
	double double_;
	float float_;
	//idouble idouble_; // currently not suppported by to!()
	//ifloat ifloat_; // currently not suppported by to!()
	int int_;
	//ireal ireal_;  // currently not suppported by to!()
	long long_;
	real real_;
	short short_;
	ubyte ubyte_;
	//ucent ucent_; // currently not implemented but a reserved keyword
	uint uint_;
	ulong ulong_;
	ushort ushort_;
	wchar wchar_;

	override equals_t opEquals (Object other)
	{
		if (auto o =  cast(H) other)
		{
			return bool_ == o.bool_ &&
				   byte_ == o.byte_ &&
				   //cdouble_ == o.cdouble_ && // currently not suppported by to!()
				   //cent_ == o.cent_ && // currently not implemented but a reserved keyword
				   //cfloat_ == o.cfloat_ && // currently not suppported by to!()
				   char_ == o.char_ &&
				   //creal_ == o.creal_ && // currently not suppported by to!()
				   dchar_ == o.dchar_ &&
				   double_ == o.double_ &&
				   float_ == o.float_ &&
				   //idouble_ == o.idouble_ && // currently not suppported by to!()
				   //ifloat_ == o.ifloat_ && // currently not suppported by to!()
				   int_ == o.int_ &&
				   //ireal_ == o.ireal_ &&  // currently not suppported by to!()
				   long_ == o.long_ &&
				   real_ == o.real_ &&
				   short_ == o.short_ &&
				   ubyte_ == o.ubyte_ &&
				   //ucent_ == o.ucent_ && // currently not implemented but a reserved keyword
				   uint_ == o.uint_ &&
				   ulong_ == o.ulong_ &&
				   ushort_ == o.ushort_ &&
				   wchar_ == o.wchar_;
		}

		return false;
	}
}

H h;

unittest
{
	archive = new XmlArchive!(char);
	serializer = new Serializer(archive);

	h = new H;
	h.bool_ = true;
	h.byte_ = 1;
	h.char_ = 'a';
	//h.cdouble_ = 0.0 + 0.0 * 1.0i; // currently not supported by to!()
	//h.cfloat_ = 0.0f + 0.0f * 1.0i; // currently not supported by to!()
	//h.creal_ = 0.0 + 0.0 * 1.0i; // currently not supported by to!()
	h.dchar_ = 'b';
	h.double_ = 0.0;
	h.float_ = 0.0f;
	//h.idouble_ = 0.0 * 1.0i; // currently not supported by to!()
	//h.ifloat_ = 0.0f * 1.0i; // currently not supported by to!()
	h.int_ = 1;
	//h.ireal_ = 0.0 * 1.0i; // currently not supported by to!()
	h.long_ = 1L;
	h.real_ = 0.0;
	h.short_ = 1;
	h.ubyte_ = 1U;
	h.uint_ = 1U;
	h.ulong_ = 1LU;
	h.ushort_ = 1U;
	h.wchar_ = 'c';

	version(Windows)
		enum zero = "0x0.p+0";
	else
		enum zero = "0x0p+0";

	describe("serialize primitives") in {
		it("should return serialized primitives") in {
			serializer.reset;
			serializer.serialize(h);

			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.Primitive.H" type="tests.Primitive.H" key="0" id="0"`));
			assert(archive.data().containsXmlTag("bool", `key="bool_" id="1"`, "true"));
			assert(archive.data().containsXmlTag("byte", `key="byte_" id="2"`, "1"));
			assert(archive.data().containsXmlTag("char", `key="char_" id="3"`, "a"));
			assert(archive.data().containsXmlTag("dchar", `key="dchar_" id="4"`, "b"));
			assert(archive.data().containsXmlTag("double", `key="double_" id="5"`, zero));
			assert(archive.data().containsXmlTag("float", `key="float_" id="6"`, zero));
			assert(archive.data().containsXmlTag("int", `key="int_" id="7"`, "1"));
			assert(archive.data().containsXmlTag("long", `key="long_" id="8"`, "1"));
			assert(archive.data().containsXmlTag("real", `key="real_" id="9"`, zero));
			assert(archive.data().containsXmlTag("short", `key="short_" id="10"`, "1"));
			assert(archive.data().containsXmlTag("ubyte", `key="ubyte_" id="11"`, "1"));
			assert(archive.data().containsXmlTag("uint", `key="uint_" id="12"`, "1"));
			assert(archive.data().containsXmlTag("ulong", `key="ulong_" id="13"`, "1"));
			assert(archive.data().containsXmlTag("ushort", `key="ushort_" id="14"`, "1"));
			assert(archive.data().containsXmlTag("wchar", `key="wchar_" id="15"`, "c"));
		};
	};

	describe("deserialize primitives") in {
		it("should return deserialized primitives equal to the original primitives") in {
			auto hDeserialized = serializer.deserialize!(H)(archive.untypedData);
			assert(h == hDeserialized);
		};
	};
}