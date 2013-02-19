## Introduction

Orange is a serialization library for the D programming language. It supports D1/Tango and D2/Phobos.
It can serialize most of the available types in D, including third party types and can serialize
through base class references. It supports fully automatic serialization of all supported types
and also supports several ways to customize the serialization process. Orange has a separate front end
(the serializer) and back end (the archive) making it possible for the user to create new archive
types that can be used with the existing serializer.

**Github is only used for the code repository, for more information and
issue reporting see the project page: [http://dsource.org/projects/orange](http://dsource.org/projects/orange)**

## Deb Package

A deb package is available on:

[APT_Repository_for_D](https://code.google.com/p/d-apt/wiki/APT_Repository#APT_Repository_for_D)

## Build Dependencies

Make or [DSSS](http://dsource.org/projects/dsss)

## D Versions

* D2/Phobos - master branch
* D2/Tango - See the [mambo repository](https://github.com/jacob-carlborg/mambo).
The API is the same, just replace "orange" with "mambo" for the imports
* D1/Tango - d1 branch
* D1/Tango and D2/Phobos in the same branch - mix branch

## Building

The master branch is for D2/Phobos.

1. Clone the repository
2. Build the library either using make or dsss

## Unit Tests

To run the unit test run the shell script "unittest.sh":

	$ ./unittest.sh

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

## Detailed Build Instructions

Clone the repository:

	$ git clone git://github.com/jacob-carlborg/orange.git

Change to the new directory "orange"

	$ cd orange

Build the library by running one of the following:

	$ dsss build
Or

	$ make