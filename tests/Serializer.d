
/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 5, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Serializer;

private:

import orange.serialization.Serializer;
import orange.serialization.archives.XMLArchive;
import orange.core.io;
import orange.core.string;

bool containsDefaultXmlContent (string source)
{
	return source.containsXmlHeader() &&
		   source.containsArchive() &&
		   source.containsXmlTag("data");
}

bool containsXmlHeader (string source)
{
	return source.contains(`<?xml version="1.0" encoding="UTF-8"?>`);
}

bool containsArchive (string source)
{
	return source.containsArchiveHeader() && source.contains("</archive>");
}

bool containsArchiveHeader (string source)
{
	return source.contains(`<archive type="org.dsource.orange.xml" version="1.0.0">`);
}

bool containsXmlTag (string source, string tag, bool simple = false)
{
	return source.containsXmlTag(tag, null, null, simple);
}

bool containsXmlTag (string source, string tag, string attributes, bool simple = false)
{
	return source.containsXmlTag(tag, attributes, null, simple);
}

bool containsXmlTag (string source, string tag, string attributes, string content, bool simple = false)
{
	string pattern = '<' ~ tag;
		
	if (attributes.length > 0)
		pattern ~= ' ' ~ attributes;
	
	if (simple)
		return source.contains(pattern ~ "/>");
	
	if (content.length > 0)
		return source.contains(pattern ~ '>' ~ content ~ "</" ~ tag ~ '>');
	
	return source.contains(pattern ~ '>') && source.contains("</" ~ tag ~ '>');
}

enum Foo { a, b, c }
typedef int Int;

class A
{
	equals_t opEquals (Object other)
	{
		if (auto o = cast(A) other)
			return true;
		
		return false;
	}
}

struct B
{
	equals_t opEquals (B b)
	{
		return true;
	}
}

class C { string str; }
class D { int[] arr; }
class E { int[int] aa; }
class F { int value; int* ptr; }
class G { Foo foo; }

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
	
	equals_t opEquals (Object other)
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

class I
{
	Int a;
}

class J
{
	string firstSource;
	string firstSlice;
	
	string secondSlice;
	string secondSource;
}

class K
{
	int[int] a;
	int[int] b;
}

import orange.test.UnitTester;
Serializer serializer;
XMLArchive!(char) archive;

A a;
B b;
C c;
D d;
E e;
F f;
G g;
H h;
I i;
J j;
J jDeserialized;
K k;

string data;

unittest
{
	archive = new XMLArchive!(char);
	serializer = new Serializer(archive);
	
	a = new A;
	
	c = new C;
	c.str = "foo";
	
	d = new D;
	d.arr = [27, 382, 283, 3820, 32, 832].dup;
	
	e = new E;
	e.aa = [3 : 4, 1 : 2, 39 : 472, 6 : 7];
	
	f = new F;
	f.value = 9;
	f.ptr = &f.value;
	
	g = new G;
	g.foo = Foo.b;
	
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
	
	i = new I;
	i.a = 1;
	
	j = new J;
	j.firstSource = "0123456789";
	j.firstSlice = j.firstSource[3 .. 7];
	j.secondSource = "abcdefg";
	j.secondSlice = j.secondSource[1 .. 4];
	
	k = new K;
	k.a = [3 : 4, 1 : 2, 39 : 472, 6 : 7];
	k.b = k.a;
	
	describe("Serializer") in {
		describe("serialize object") in {
			it("should return a serialized object") in {
				serializer.reset;
				serializer.serialize(a);
				
				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().contains(`<object runtimeType="tests.Serializer.A" type="A" key="0" id="0"/>`));
			};
		};
		
		describe("deserialize object") in {
			it("should return a deserialized object equal to the original object") in {
				auto aDeserialized = serializer.deserialize!(A)(archive.data);
				assert(a == aDeserialized);
			};
		};
		
		describe("serialize struct") in {
			it("should return a serialized struct") in {
				serializer.reset;
				serializer.serialize(B());

				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().contains(`<struct type="B" key="0" id="0"/>`));
			};
		};
		
		describe("deserialize struct") in {
			it("should return a deserialized struct equal to the original struct") in {
				auto bDeserialized = serializer.deserialize!(B)(archive.data);
				assert(b == bDeserialized);
			};
		};
		
		describe("serialize string") in {
			it("should return a serialized string") in {
				serializer.reset;

				serializer.serialize(c);
				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().containsXmlTag("object", `runtimeType="tests.Serializer.C" type="C" key="0" id="0"`));
				assert(archive.data().containsXmlTag("string", `type="char" length="3" key="str" id="1"`, "foo"));
			};
		};
		
		describe("deserialize string") in {
			it("should return a deserialized string equal to the original string") in {
				auto cDeserialized = serializer.deserialize!(C)(archive.data);
				assert(c.str == cDeserialized.str);
			};
		};
		
		describe("serialize array") in {
			it("should return a serialized array") in {
				serializer.reset;
				serializer.serialize(d);

				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().containsXmlTag("object", `runtimeType="tests.Serializer.D" type="D" key="0" id="0"`));
				assert(archive.data().containsXmlTag("array", `type="int" length="6" key="arr" id="1"`));
				assert(archive.data().containsXmlTag("int", `key="0" id="2"`, "27"));
				assert(archive.data().containsXmlTag("int", `key="1" id="3"`, "382"));
				assert(archive.data().containsXmlTag("int", `key="2" id="4"`, "283"));
				assert(archive.data().containsXmlTag("int", `key="3" id="5"`, "3820"));
				assert(archive.data().containsXmlTag("int", `key="4" id="6"`, "32"));
				assert(archive.data().containsXmlTag("int", `key="5" id="7"`, "832"));
			};
		};
		
		describe("deserialize array") in {
			it("should return a deserialize array equal to the original array") in {
				auto dDeserialized = serializer.deserialize!(D)(archive.data);
				assert(d.arr == dDeserialized.arr);
			};
		};
		
		describe("serialize associative array") in {
			it("should return a serialized associative array") in {
				serializer.reset();
				serializer.serialize(e);
				
				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().containsXmlTag("object", `runtimeType="tests.Serializer.E" type="E" key="0" id="0"`));
				assert(archive.data().containsXmlTag("associativeArray", `keyType="int" valueType="int" length="4" key="aa" id="1"`));

				assert(archive.data().containsXmlTag("key", `key="0"`));
				assert(archive.data().containsXmlTag("int", `key="0" id="2"`, "1"));
				assert(archive.data().containsXmlTag("value", `key="0"`));
				assert(archive.data().containsXmlTag("int", `key="0" id="3"`, "2"));
				
				assert(archive.data().containsXmlTag("key", `key="1"`));
				assert(archive.data().containsXmlTag("int", `key="1" id="4"`, "3"));
				assert(archive.data().containsXmlTag("value", `key="1"`));
				assert(archive.data().containsXmlTag("int", `key="1" id="5"`, "4"));
				
				assert(archive.data().containsXmlTag("key", `key="2"`));
				assert(archive.data().containsXmlTag("int", `key="2" id="6"`, "6"));
				assert(archive.data().containsXmlTag("value", `key="2"`));
				assert(archive.data().containsXmlTag("int", `key="2" id="7"`, "7"));
				
				assert(archive.data().containsXmlTag("key", `key="3"`));
				assert(archive.data().containsXmlTag("int", `key="3" id="8"`, "39"));
				assert(archive.data().containsXmlTag("value", `key="3"`));
				assert(archive.data().containsXmlTag("int", `key="3" id="9"`, "472"));
			};
		};
		
		describe("deserialize associative array") in {
			it("should return an associative array equal to the original associative array") in {
				auto eDeserialized = serializer.deserialize!(E)(archive.data);
				
				foreach (k, v ; eDeserialized.aa)
					assert(e.aa[k] == v);
				
				//assert(e.aa == eDeserialized.aa); // cannot compare associative array
			};
		};
		
		describe("serialize pointer") in {
			it("should return a serialized pointer") in {
				serializer.reset();
				serializer.serialize(f);

				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().containsXmlTag("object", `runtimeType="tests.Serializer.F" type="F" key="0" id="0"`));
				assert(archive.data().containsXmlTag("pointer", `key="ptr" id="2"`));
				assert(archive.data().containsXmlTag("reference", null, "1"));
				assert(archive.data().containsXmlTag("int", `key="value" id="1"`, "9"));
			};
		};
		
		describe("deserialize pointer") in {
			it("should return a deserialized pointer equal to the original pointer") in {
				auto fDeserialized = serializer.deserialize!(F)(archive.data);

				assert(*f.ptr == *fDeserialized.ptr);
			};
		};
		
		describe("serialize enum") in {
			it("should return a serialized enum") in {
				serializer.reset();
				serializer.serialize(g);

				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().containsXmlTag("object", `runtimeType="tests.Serializer.G" type="G" key="0" id="0"`));
				assert(archive.data().containsXmlTag("enum", `type="Foo" baseType="int" key="foo" id="1"`, "1"));
			};
		};

		
		describe("deserialize enum") in {
			it("should return an enum equal to the original enum") in {
				auto gDeserialized = serializer.deserialize!(G)(archive.data);
				assert(g.foo == gDeserialized.foo);
			};
		};
		
		describe("serialize primitives") in {
			it("should return serialized primitives") in {
				serializer.reset;
				serializer.serialize(h);

				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().containsXmlTag("object", `runtimeType="tests.Serializer.H" type="H" key="0" id="0"`));
				assert(archive.data().containsXmlTag("bool", `key="bool_" id="1"`, "true"));
				assert(archive.data().containsXmlTag("byte", `key="byte_" id="2"`, "1"));
				assert(archive.data().containsXmlTag("char", `key="char_" id="3"`, "a"));
				assert(archive.data().containsXmlTag("dchar", `key="dchar_" id="4"`, "b"));
				assert(archive.data().containsXmlTag("double", `key="double_" id="5"`, "0"));
				assert(archive.data().containsXmlTag("float", `key="float_" id="6"`, "0"));
				assert(archive.data().containsXmlTag("int", `key="int_" id="7"`, "1"));
				assert(archive.data().containsXmlTag("long", `key="long_" id="8"`, "1"));
				assert(archive.data().containsXmlTag("real", `key="real_" id="9"`, "0"));
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
				auto hDeserialized = serializer.deserialize!(H)(archive.data);
				assert(h == hDeserialized);
			};
		};
		
		describe("serialize typedef") in {
			it("should return a serialized typedef") in {
				serializer.reset();
				serializer.serialize(i);
				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().containsXmlTag("object", `runtimeType="tests.Serializer.I" type="I" key="0" id="0"`));
				assert(archive.data().containsXmlTag("typedef", `type="Int" key="a" id="2"`));
				assert(archive.data().containsXmlTag("int", `key="1" id="3"`, "1"));
			};
		};
		
		describe("deserialize typedef") in {
			it("should return a deserialized typedef equal to the original typedef") in {
				auto iDeserialized = serializer.deserialize!(I)(archive.data);
				assert(i.a == iDeserialized.a);
			};
		};
		
		describe("serialize slices") in {
			it("should return serialized slices") in {
				serializer.reset();
				serializer.serialize(j);

				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().containsXmlTag("object", `runtimeType="tests.Serializer.J" type="J" key="0" id="0"`));
				assert(archive.data().containsXmlTag("string", `type="char" length="10" key="firstSource" id="1"`, "0123456789"));
				assert(archive.data().containsXmlTag("slice", `key="firstSlice" offset="3" length="4"`, "1"));
				assert(archive.data().containsXmlTag("slice", `key="secondSlice" offset="1" length="3"`, "4"));
				assert(archive.data().containsXmlTag("string", `type="char" length="7" key="secondSource" id="4"`, "abcdefg"));
			};
		};
		
		describe("deserialize slices") in {
			jDeserialized = serializer.deserialize!(J)(archive.data);
			
			it("should return deserialized strings equal to the original strings") in {
				assert(j.firstSource == jDeserialized.firstSource);
				assert(j.secondSource == jDeserialized.secondSource);
			};
			
			it("should return deserialized slices equal to the original slices") in {
				assert(j.firstSlice == jDeserialized.firstSlice);
				assert(j.secondSlice == jDeserialized.secondSlice);
			};
			
			it("the slices should be equal to a slice of the original sources") in {
				assert(jDeserialized.firstSource[3 .. 7] == jDeserialized.firstSlice);
				assert(jDeserialized.secondSource[1 .. 4] == jDeserialized.secondSlice);
				
				assert(j.firstSource[3 .. 7] == jDeserialized.firstSlice);
				assert(j.secondSource[1 .. 4] == jDeserialized.secondSlice);
			};
			
			it("the slices should be able to modify the sources") in {
				jDeserialized.firstSlice[0] = 'a';
				jDeserialized.secondSlice[0] = '0';

				assert(jDeserialized.firstSource == "012a456789");
				assert(jDeserialized.secondSource == "a0cdefg");
			};
		};
		
		describe("serialize associative array references") in {
			it("should return a serialized associative array and a serialized reference") in {
				serializer.reset();
				serializer.serialize(k);
				
				assert(archive.data().containsDefaultXmlContent());
				assert(archive.data().containsXmlTag("object", `runtimeType="tests.Serializer.K" type="K" key="0" id="0"`));
				assert(archive.data().containsXmlTag("associativeArray", `keyType="int" valueType="int" length="4" key="a" id="1"`));

				assert(archive.data().containsXmlTag("key", `key="0"`));
				assert(archive.data().containsXmlTag("int", `key="0" id="2"`, "1"));
				assert(archive.data().containsXmlTag("value", `key="0"`));
				assert(archive.data().containsXmlTag("int", `key="0" id="3"`, "2"));
				
				assert(archive.data().containsXmlTag("key", `key="1"`));
				assert(archive.data().containsXmlTag("int", `key="1" id="4"`, "3"));
				assert(archive.data().containsXmlTag("value", `key="1"`));
				assert(archive.data().containsXmlTag("int", `key="1" id="5"`, "4"));
				
				assert(archive.data().containsXmlTag("key", `key="2"`));
				assert(archive.data().containsXmlTag("int", `key="2" id="6"`, "6"));
				assert(archive.data().containsXmlTag("value", `key="2"`));
				assert(archive.data().containsXmlTag("int", `key="2" id="7"`, "7"));
				
				assert(archive.data().containsXmlTag("key", `key="3"`));
				assert(archive.data().containsXmlTag("int", `key="3" id="8"`, "39"));
				assert(archive.data().containsXmlTag("value", `key="3"`));
				assert(archive.data().containsXmlTag("int", `key="3" id="9"`, "472"));

				assert(archive.data().containsXmlTag("reference", `key="b"`, "1"));
			};
		};
		
		describe("deserialize associative array references") in {
			it("should return two deserialized associative arrays pointing to the same data") in {
				auto kDeserialized = serializer.deserialize!(K)(archive.data);
				
				assert(kDeserialized.a is kDeserialized.b);
			};
		};
	};
}