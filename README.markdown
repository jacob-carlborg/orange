# Orange [![Build Status](https://travis-ci.org/jacob-carlborg/orange.svg?branch=master)](https://travis-ci.org/jacob-carlborg/orange) [![Go to orange](https://img.shields.io/dub/v/orange.svg)](https://code.dlang.org/packages/orange)

Orange is a serialization library for the D programming language. It supports D1/Tango and D2/Phobos.
It can serialize most of the available types in D, including third party types and can serialize
through base class references. It supports fully automatic serialization of all supported types
and also supports several ways to customize the serialization process. Orange has a separate front end
(the serializer) and back end (the archive) making it possible for the user to create new archive
types that can be used with the existing serializer.

## Building

### Requirements

* Dub http://code.dlang.org/download

### Building

1. Install all requirements
1. Clone the repository
1. Run `dub build`

## Unit Tests

Run the unit tests using Dub `dub test`

## Simple Usage Example

```d
module main;

import orange.serialization._;
import orange.serialization.archives._;

class Foo
{
	int a;
}

void main ()
{
	auto foo = new Foo; // create something to serialize
	foo.a = 3; // change the default value of "a"

	auto archive = new XmlArchive!(char); // create an XML archive
	auto serializer = new Serializer(archive); // create the serializer

	serializer.serialize(foo); // serialize "foo"

	// deserialize the serialized data as an instance of "Foo"
	auto f = serializer.deserialize!(Foo)(archive.untypedData);

	// verify that the deserialized value is equal to the original value
	assert(f.a == foo.a);
}
```

### More Examples

See the [test](https://github.com/jacob-carlborg/orange/tree/master/tests)
directory for some examples.

## D Versions

* D2/Phobos - master branch
* D2/Tango - See the [mambo repository](https://github.com/jacob-carlborg/mambo).
The API is the same, just replace "orange" with "mambo" for the imports
* D1/Tango - d1 branch
* D1/Tango and D2/Phobos in the same branch - mix branch
