/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 6, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module tests.Slice;

import orange.core.string;
import orange.serialization.Serializer;
import orange.serialization.archives.XmlArchive;
import orange.test.UnitTester;
import tests.Util;

Serializer serializer;
XmlArchive!(char) archive;

class J
{
	int[] firstSource;
	int[] firstSlice;

	int[] secondSlice;
	int[] secondSource;

	int[] firstEmpty;
	int[] secondEmpty;

	int[][] thirdEmpty;
}

J j;
J jDeserialized;
import orange.core.io;
unittest
{
	archive = new XmlArchive!(char);
	serializer = new Serializer(archive);

	j = new J;
	j.firstSource = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].dup;
	j.firstSlice = j.firstSource[3 .. 7];

	j.secondSource = [10, 11, 12, 13, 14, 15].dup;
	j.secondSlice = j.secondSource[1 .. 4];

	describe("serialize slices") in {
		serializer.reset();
		serializer.serialize(j);

		it("should return serialized slices") in {

			assert(archive.data().containsDefaultXmlContent());
			assert(archive.data().containsXmlTag("object", `runtimeType="tests.Slice.J" type="tests.Slice.J" key="0" id="0"`));
			assert(archive.data().containsXmlTag("array", `type="int" length="10" key="firstSource" id="1"`));

			assert(archive.data().containsXmlTag("int", `key="0" id="2"`, "0"));
			assert(archive.data().containsXmlTag("int", `key="1" id="3"`, "1"));
			assert(archive.data().containsXmlTag("int", `key="2" id="4"`, "2"));
			assert(archive.data().containsXmlTag("int", `key="3" id="5"`, "3"));
			assert(archive.data().containsXmlTag("int", `key="4" id="6"`, "4"));
			assert(archive.data().containsXmlTag("int", `key="5" id="7"`, "5"));
			assert(archive.data().containsXmlTag("int", `key="6" id="8"`, "6"));
			assert(archive.data().containsXmlTag("int", `key="7" id="9"`, "7"));
			assert(archive.data().containsXmlTag("int", `key="8" id="10"`, "8"));
			assert(archive.data().containsXmlTag("int", `key="9" id="11"`, "9"));

			assert(archive.data().containsXmlTag("array", `type="int" length="6" key="secondSource" id="21"`));

			assert(archive.data().containsXmlTag("int", `key="0" id="22"`, "10"));
			assert(archive.data().containsXmlTag("int", `key="1" id="23"`, "11"));
			assert(archive.data().containsXmlTag("int", `key="2" id="24"`, "12"));
			assert(archive.data().containsXmlTag("int", `key="3" id="25"`, "13"));
			assert(archive.data().containsXmlTag("int", `key="4" id="26"`, "14"));
			assert(archive.data().containsXmlTag("int", `key="5" id="27"`, "15"));

			assert(archive.data().containsXmlTag("array", `type="int" length="0" key="firstEmpty" id="28"`, true));
			assert(archive.data().containsXmlTag("array", `type="int" length="0" key="secondEmpty" id="29"`, true));
			assert(archive.data().containsXmlTag("array", `type="int[]" length="0" key="thirdEmpty" id="30"`, true));
		};

		it("should not contain slices to empty arrays") in {
			assert(!archive.data().containsXmlTag("slice", `key="firstEmpty" offset="0" length="0"`, "30"));
			assert(!archive.data().containsXmlTag("slice", `key="secondEmpty" offset="0" length="0"`, "30"));
			assert(!archive.data().containsXmlTag("slice", `key="thirdEmpty" offset="0" length="0"`, "28"));
		};
	};

	describe("deserialize slices") in {
		jDeserialized = serializer.deserialize!(J)(archive.untypedData);

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
			jDeserialized.firstSlice[0] = 55;
			jDeserialized.secondSlice[0] = 3;

			assert(jDeserialized.firstSource == [0, 1, 2, 55, 4, 5, 6, 7, 8, 9]);
			assert(jDeserialized.secondSource == [10, 3, 12, 13, 14, 15]);
		};
	};
}