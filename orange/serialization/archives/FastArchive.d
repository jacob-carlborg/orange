/**
 * Copyright: Copyright (c) 2012 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Sep 19, 2012
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.archives.FastArchive;

import orange.core._;
import orange.serialization.archives._;
import orange.serialization.Serializer;
import orange.util._;

import std.bitmanip;
import std.array : Appender, appender;

/**
 * This class is a concrete implementation of the Archive interface. This archive uses a
 * binary format as the final format for the serialized data. The binary format tries to be
 * as fast as possible. It's ABI dependent, it breaks every rule, the implicit contract with
 * the serializer and platform portability.
 * 
 * Use this archive on your own risk when you know what you are doing and just want the
 * fastest archive possible.
 */ 
final class FastArchive : Archive//ArchiveBase!(ubyte)
{
	version (Tango) alias U[] Data;
	else mixin ("alias immutable(ubyte)[] Data;");

	private
	{
		Data rawData;
		size_t cursor;
		Appender!(Data) buffer;
	}

	/**
	 * This callback will be called when an unexpected event occurs, i.e. an expected element
	 * is missing in the unarchiving process.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * serializer.errorCallback = (SerializationException exception) {
	 * 	println(exception);
	 * 	throw exception;
	 * };
	 * ---
	 */
	ErrorCallback errorCallback ()
	{
		return null;
	}
	
	/**
	 * This callback will be called when an unexpected event occurs, i.e. an expected element
	 * is missing in the unarchiving process.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * serializer.errorCallback = (SerializationException exception) {
	 * 	println(exception);
	 * 	throw exception;
	 * };
	 * ---
	 */
	ErrorCallback errorCallback (ErrorCallback errorCallback)
	{
		return null;
	}
	
	/// Starts the archiving process. Call this method before archiving any values.
	void beginArchiving ()
	{
		buffer = appender(rawData);
	}
	
	/**
	 * Begins the unarchiving process. Call this method before unarchiving any values.
	 * 
	 * Params:
	 *     data = the data to unarchive
	 */
	void beginUnarchiving (UntypedData data)
	{
		rawData = cast(Data) data;
	}
	
	/// Returns the data stored in the archive in an untyped form.
	UntypedData untypedData ()
	{
		return rawData;
	}

	/// Returns the data stored in the archive in an typed form.
	Data data ()
	{
		if (rawData.length > 0)
			return rawData;

		return buffer.data;
	}

	/**
	 * Resets the archive. This resets the archive in a state making it ready to start
	 * a new archiving process.
	 */	
	void reset ()
	{
		rawData = null;
		buffer = appender(rawData);
	}
	
	/**
	 * Archives an array.
	 * 
	 * Examples:
	 * ---
	 * int[] arr = [1, 2, 3];
	 * 
	 * auto archive = new XmlArchive!();
	 * 
	 * auto a = Array(arr.ptr, arr.length, typeof(a[0]).sizeof);
	 * 
	 * archive.archive(a, typeof(a[0]).string, "arr", 0, {
	 * 	// archive the individual elements
	 * });
	 * ---
	 * 
	 * Params:
	 *     array = the array to archive
	 *     type = the runtime type of an element of the array
	 *     key = the key associated with the array
	 *     id = the id associated with the array
	 *     dg = a callback that performs the archiving of the individual elements
	 */
	void archiveArray (Array array, string type, string key, Id id, void delegate () dg)
	{
		dg();
	}
	
	/**
	 * Archives an associative array.
	 * 
	 * Examples:
	 * ---
	 * int[string] arr = ["a"[] : 1, "b" : 2, "c" : 3];
	 * 
	 * auto archive = new XmlArchive!();
	 * 
	 * archive.archive(string.stringof, int.stringof, arr.length, "arr", 0, {
	 * 	// archive the individual keys and values
	 * });
	 * ---
	 * 
	 * 
	 * Params:
	 *     keyType = the runtime type of the keys 
	 *     valueType = the runtime type of the values
	 *     length = the length of the associative array
	 *     key = the key associated with the associative array
	 *     id = the id associated with the associative array
	 *     dg = a callback that performs the archiving of the individual keys and values
	 *     
	 * See_Also: archiveAssociativeArrayValue
	 * See_Also: archiveAssociativeArrayKey
	 */
	void archiveAssociativeArray (string keyType, string valueType, size_t length, string key, Id id, void delegate () dg)
	{
		dg();
	}
	
	/**
	 * Archives an associative array key.
	 * 
	 * There are separate methods for archiving associative array keys and values
	 * because both the key and the value can be of arbitrary type and needs to be
	 * archived on its own.
	 * 
	 * Examples:
	 * ---
	 * int[string] arr = ["a"[] : 1, "b" : 2, "c" : 3];
	 * 
	 * auto archive = new XmlArchive!();
	 * 
	 * foreach(k, v ; arr)
	 * {
	 * 	archive.archiveAssociativeArrayKey(to!(string)(i), {
	 * 		// archive the key
	 * 	});
	 * }
	 * ---
	 * 
	 * The foreach statement in the above example would most likely be executed in the
	 * callback passed to the archiveAssociativeArray method.
	 * 
	 * Params:
	 *     key = the key associated with the key
	 *     dg = a callback that performs the actual archiving of the key
	 *     
	 * See_Also: archiveAssociativeArray
	 * See_Also: archiveAssociativeArrayValue
	 */
	void archiveAssociativeArrayKey (string key, void delegate () dg)
	{
		dg();
	}
	
	/**
	 * Archives an associative array value.
	 * 
	 * There are separate methods for archiving associative array keys and values
	 * because both the key and the value can be of arbitrary type and needs to be
	 * archived on its own.
	 *
	 * Examples:
	 * ---
	 * int[string] arr = ["a"[] : 1, "b" : 2, "c" : 3];
	 * 
	 * auto archive = new XmlArchive!();
	 * size_t i;
	 * 
	 * foreach(k, v ; arr)
	 * {
	 * 	archive.archiveAssociativeArrayValue(to!(string)(i), {
	 * 		// archive the value
	 * 	});
	 * 	
	 * 	i++;
	 * }
	 * ---
	 * 
	 * The foreach statement in the above example would most likely be executed in the
	 * callback passed to the archiveAssociativeArray method.
	 * 
	 * Params:
	 *     key = the key associated with the value
	 *     dg = a callback that performs the actual archiving of the value
	 *     
	 * See_Also: archiveAssociativeArray
	 * See_Also: archiveAssociativeArrayKey
	 */
	void archiveAssociativeArrayValue (string key, void delegate () dg)
	{
		dg();
	}
	
	/**
	 * Archives the given value.
	 * 
	 * Example:
	 * ---
	 * enum Foo : bool
	 * {
	 * 	bar
	 * }
	 * 
	 * auto foo = Foo.bar;
	 * auto archive = new XmlArchive!();
	 * archive.archive(foo, "bool", "foo", 0);
	 * ---
	 * 
	 * Params:
	 *     value = the value to archive
	 *     baseType = the base type of the enum 
	 *     key = the key associated with the value
	 *     id = the id associated with the value
	 */
	void archiveEnum (bool value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (byte value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (char value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (dchar value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (int value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (long value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (short value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (ubyte value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (uint value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (ulong value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (ushort value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	/// Ditto
	void archiveEnum (wchar value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}
	
	private void internalArchiveEnum (T) (T value, string type, string key, Id id)
	{
		append(value);
	}
	
	/**
	 * Archives a base class.
	 * 
	 * This method is used to indicate that the all following calls to archive a value
	 * should be part of the base class. This method is usually called within the
	 * callback passed to archiveObject. The archiveObject method can the mark the end
	 * of the class.
	 * 
	 * Examples:
	 * ---
	 * class ArchiveBase {}
	 * class Foo : ArchiveBase {}
	 * 
	 * auto archive = new XmlArchive!();
	 * archive.archiveBaseClass("ArchiveBase", "base", 0);
	 * ---
	 * 
	 * Params:
	 *     type = the type of the base class to archive
	 *     key = the key associated with the base class
	 *     id = the id associated with the base class
	 */
	void archiveBaseClass (string type, string key, Id id)
	{
		//noop
	}
	
	/**
	 * Archives a null pointer or reference.
	 * 
	 * Examples:
	 * ---
	 * int* ptr;
	 * 
	 * auto archive = new XmlArchive!();
	 * archive.archiveNull(typeof(ptr).stringof, "ptr");
	 * ---
	 * 
	 * Params:
	 *     type = the runtime type of the pointer or reference to archive 
	 *     key = the key associated with the null pointer
	 */
	void archiveNull (string type, string key)
	{
		append!(ubyte)(0);
	}
	
	/**
	 * Archives an object, either a class or an interface.
	 * 
	 * Examples:
	 * ---
	 * class Foo
	 * {
	 * 	int a;
	 * }
	 * 
	 * auto foo = new Foo;
	 * 
	 * auto archive = new XmlArchive!();
	 * archive.archiveObject(Foo.classinfo.name, "Foo", "foo", 0, {
	 * 	// archive the fields of Foo
	 * });
	 * ---
	 * 
	 * Params:
	 *     runtimeType = the runtime type of the object
	 *     type = the static type of the object
	 *     key = the key associated with the object
	 *     id = the id associated with the object
	 *     dg = a callback that performs the archiving of the individual fields
	 */
	void archiveObject (string runtimeType, string type, string key, Id id, void delegate () dg)
	{
		archiveString(runtimeType, string.init, Id.max);
	}
	
	/**
	 * Archives a pointer.
	 * 
	 * If a pointer points to a value that is serialized as well, the pointer should be
	 * archived as a reference. Otherwise the value that the pointer points to should be
	 * serialized as a regular value.
	 * 
	 * Examples:
	 * ---
	 * class Foo
	 * {
	 * 	int a;
	 * 	int* b;
	 * }
	 * 
	 * auto foo = new Foo;
	 * foo.a = 3;
	 * foo.b = &foo.a;
	 * 
	 * archive = new XmlArchive!();
	 * archive.archivePointer("b", 0, {
	 * 	// archive "foo.b" as a reference
	 * });
	 * ---
	 * 
	 * ---
	 * int a = 3;
	 * 
	 * class Foo
	 * {
	 * 	int* b;
	 * }
	 * 
	 * auto foo = new Foo;
	 * foo.b = &a;
	 * 
	 * archive = new XmlArchive!();
	 * archive.archivePointer("b", 0, {
	 * 	// archive "foo.b" as a regular value
	 * });
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the pointer
	 *     id = the id associated with the pointer
	 *     dg = a callback that performs the archiving of value pointed to by the pointer
	 */
	void archivePointer (string key, Id id, void delegate () dg)
	{
		dg();
	}
	
	/**
	 * Archives a reference.
	 * 
	 * A reference is reference to another value. For example, if an object is archived
	 * more than once, the first time it's archived it will actual archive the object.
	 * The second time the object will be archived a reference will be archived instead
	 * of the actual object.
	 * 
	 * This method is also used when archiving a pointer that points to a value that has
	 * been or will be archived as well.
	 * 
	 * Examples:
	 * ---
	 * class Foo {}
	 * 
	 * class Bar
	 * {
	 * 	Foo f;
	 * 	Foo f2;
	 * }
	 * 
	 * auto bar = new Bar;
	 * bar.f = new Foo;
	 * bar.f2 = bar.f;
	 * 
	 * auto archive = new XmlArchive!();
	 * 
	 * // when achiving "bar" 
	 * archive.archiveObject(Foo.classinfo.name, "Foo", "f", 0, {});
	 * archive.archiveReference("f2", 0); // archive a reference to "f"
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the reference
	 *     id = the id of the value this reference refers to
	 */
	void archiveReference (string key, Id id)
	{
		append(id);
	}
	
	/**
	 * Archives a slice.
	 * 
	 * This method should be used when archiving an array that is a slice of an
	 * already archived array or an array that has not yet been archived.
	 * 
	 * Examples:
	 * ---
	 * auto arr = [1, 2, 3, 4];
	 * auto slice = arr[1 .. 3];
	 * 
	 * auto archive = new XmlArchive!();
	 * // archive "arr" with id 0
	 * 
	 * auto s = Slice(slice.length, 1);
	 * archive.archiveSlice(s, 1, 0); 
	 * ---
	 * 
	 * Params:
	 *     slice = the slice to be archived 
	 *     sliceId = the id associated with the slice
	 *     arrayId = the id associated with the array this slice is a slice of
	 */
	void archiveSlice (Slice slice, Id sliceId, Id arrayId)
	{
		//noop
	}
	
	/**
	 * Archives a struct.
	 * 
	 * Examples:
	 * ---
	 * struct Foo
	 * { 
	 * 	int a;
	 * }
	 * 
	 * auto foo = Foo(3);
	 * 
	 * auto archive = new XmlArchive!();
	 * archive.archiveStruct(Foo.stringof, "foo", 0, {
	 * 	// archive the fields of Foo
	 * });
	 * ---
	 * 
	 * Params:
	 *     type = the type of the struct
	 *     key = the key associated with the struct
	 *     id = the id associated with the struct
	 *     dg = a callback that performs the archiving of the individual fields
	 */
	void archiveStruct (string type, string key, Id id, void delegate () dg)
	{
		dg();
	}
	
	/**
	 * Archives a typedef.
	 * 
	 * Examples:
	 * ---
	 * typedef int Foo;
	 * Foo a = 3;
	 * 
	 * auto archive = new XmlArchive!();
	 * archive.archiveTypedef(Foo.stringof, "a", 0, {
	 * 	// archive "a" as the base type of Foo, i.e. int
	 * });
	 * ---
	 * 
	 * Params:
	 *     type = the type of the typedef
	 *     key = the key associated with the typedef
	 *     id = the id associated with the typedef
	 *     dg = a callback that performs the archiving of the value as the base
	 *     		type of the typedef
	 */
	void archiveTypedef (string type, string key, Id id, void delegate () dg)
	{
		dg();
	}

	/**
	 * Archives the given value.
	 * 
	 * Params:
	 *     value = the value to archive
	 *     key = the key associated with the value
	 *     id = the id associated wit the value
	 */
	void archive (string value, string key, Id id)
	{
		archiveString(value, key, id);
	}
	
	/// Ditto
	void archive (wstring value, string key, Id id)
	{
		archiveString(value, key, id);
	}

	/// Ditto	
	void archive (dstring value, string key, Id id)
	{
		archiveString(value, key, id);
	}
	
	private void archiveString (T) (T value, string key, Id id)
	{
		alias ElementTypeOfArray!(T) E;

		append(value.length);

		foreach (E e ; value)
			append(e);
	}
	
	/// Ditto
	void archive (bool value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	/// Ditto
	void archive (byte value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	//currently not suppported by to!()
	/*void archive (cdouble value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	//currently not implemented but a reserved keyword
	/*void archive (cent value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	//currently not suppported by to!()
	/*void archive (cfloat value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	/// Ditto
	void archive (char value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	//currently not suppported by to!()
	/*void archive (creal value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	/// Ditto
	void archive (dchar value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	/// Ditto
	void archive (double value, string key, Id id)
	{
		//archivePrimitive(value, key, id);
	}

	/// Ditto
	void archive (float value, string key, Id id)
	{
		//archivePrimitive(value, key, id);
	}

	//currently not suppported by to!()
	/*void archive (idouble value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	//currently not suppported by to!()
	/*void archive (ifloat value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	/// Ditto
	void archive (int value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	//currently not suppported by to!()
	/*void archive (ireal value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	/// Ditto
	void archive (long value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	/// Ditto
	void archive (real value, string key, Id id)
	{
		//archivePrimitive(value, key, id);
	}

	/// Ditto
	void archive (short value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	/// Ditto
	void archive (ubyte value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	//currently not implemented but a reserved keyword
	/*void archive (ucent value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	/// Ditto
	void archive (uint value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	/// Ditto
	void archive (ulong value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	/// Ditto
	void archive (ushort value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	/// Ditto
	void archive (wchar value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}
	
	private void archivePrimitive (T) (T value, string key, Id id)
	{
		append(value);
	}
	
	/**
	 * Unarchives the value associated with the given key as an array.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * auto id = archive.unarchiveArray("arr", (size_t length) {
	 * 	auto arr = new int[length]; // pre-allocate the array
	 * 	// unarchive the individual elements of "arr"
	 * });
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the array
	 *     dg = a callback that performs the unarchiving of the individual elements.
	 *     		$(I length) is the length of the archived array
	 *     
	 * Returns: the id associated with the array
	 * 
	 * See_Also: unarchiveArray
	 */
	Id unarchiveArray (string key, void delegate (size_t length) dg)
	{
		dg(readLength);
		return Id.max;
	}
	
	/**
	 * Unarchives the value associated with the given id as an array.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * archive.unarchiveArray(0, (size_t length) {
	 * 	auto arr = new int[length]; // pre-allocate the array
	 * 	// unarchive the individual elements of "arr"
	 * });
	 * ---
	 * 
	 * Params:
	 *     id = the id associated with the value
	 *     dg = a callback that performs the unarchiving of the individual elements.
	 *     		$(I length) is the length of the archived array
	 *     
	 * See_Also: unarchiveArray
	 */
	void unarchiveArray (Id id, void delegate (size_t length) dg)
	{
		dg(readLength);
	}
	
	/**
	 * Unarchives the value associated with the given id as an associative array.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * 
	 * auto id = archive.unarchiveAssociativeArray("aa", (size_t length) {
	 * 	// unarchive the individual keys and values
	 * });
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the associative array 
	 *     dg = a callback that performs the unarchiving of the individual keys and values.
	 *     		$(I length) is the length of the archived associative array
	 *     
	 * Returns: the id associated with the associative array
	 * 
	 * See_Also: unarchiveAssociativeArrayKey
	 * See_Also: unarchiveAssociativeArrayValue
	 */
	Id unarchiveAssociativeArray (string key, void delegate (size_t length) dg)
	{
		dg(readLength);
		return Id.max;
	}
	
	/**
	 * Unarchives an associative array key.
	 * 
	 * There are separate methods for unarchiving associative array keys and values
	 * because both the key and the value can be of arbitrary type and needs to be
	 * unarchived on its own.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * 
	 * for (size_t i = 0; i < length; i++)
	 * {
	 * 	unarchiveAssociativeArrayKey(to!(string(i), {
	 * 		// unarchive the key
	 * 	});	
	 * }
	 * ---
	 * 
	 * The for statement in the above example would most likely be executed in the
	 * callback passed to the unarchiveAssociativeArray method.
	 * 
	 * Params:
	 *     key = the key associated with the key
	 *     dg = a callback that performs the actual unarchiving of the key
	 *     
	 * See_Also: unarchiveAssociativeArrayValue
	 * See_Also: unarchiveAssociativeArray
	 */
	void unarchiveAssociativeArrayKey (string key, void delegate () dg)
	{
		dg();
	}
	
	/**
	 * Unarchives an associative array value.
	 * 
	 * There are separate methods for unarchiving associative array keys and values
	 * because both the key and the value can be of arbitrary type and needs to be
	 * unarchived on its own.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * 
	 * for (size_t i = 0; i < length; i++)
	 * {
	 * 	unarchiveAssociativeArrayValue(to!(string(i), {
	 * 		// unarchive the value
	 * 	});	
	 * }
	 * ---
	 * 
	 * The for statement in the above example would most likely be executed in the
	 * callback passed to the unarchiveAssociativeArray method.
	 * 
	 * Params:
	 *     key = the key associated with the value
	 *     dg = a callback that performs the actual unarchiving of the value
	 *     
	 * See_Also: unarchiveAssociativeArrayKey
	 * See_Also: unarchiveAssociativeArray
	 */
	void unarchiveAssociativeArrayValue (string key, void delegate () dg)
	{
		dg();
	}
	
	/**
	 * Unarchives the value associated with the given key as a bool.
	 * 
	 * This method is used when the unarchiving a enum value with the base type bool. 
	 * 
	 * Params:
	 *     key = the key associated with the value
	 *     
	 * Returns: the unarchived value
	 */
	bool unarchiveEnumBool (string key)
	{
		return unarchiveEnum!(bool)(key);
	}
	
	/// Ditto
	byte unarchiveEnumByte (string key)
	{
		return unarchiveEnum!(byte)(key);
	}

	/// Ditto	
	char unarchiveEnumChar (string key)
	{
		return unarchiveEnum!(char)(key);
	}
	
	/// Ditto
	dchar unarchiveEnumDchar (string key)
	{
		return unarchiveEnum!(dchar)(key);
	}

	/// Ditto	
	int unarchiveEnumInt (string key)
	{
		return unarchiveEnum!(int)(key);
	}
	
	/// Ditto
	long unarchiveEnumLong (string key)
	{
		return unarchiveEnum!(long)(key);
	}

	/// Ditto	
	short unarchiveEnumShort (string key)
	{
		return unarchiveEnum!(short)(key);
	}

	/// Ditto	
	ubyte unarchiveEnumUbyte (string key)
	{
		return unarchiveEnum!(ubyte)(key);
	}

	/// Ditto	
	uint unarchiveEnumUint (string key)
	{
		return unarchiveEnum!(uint)(key);
	}

	/// Ditto	
	ulong unarchiveEnumUlong (string key)
	{
		return unarchiveEnum!(ulong)(key);
	}
	
	/// Ditto	
	ushort unarchiveEnumUshort (string key)
	{
		return unarchiveEnum!(ushort)(key);
	}
	
	/// Ditto	
	wchar unarchiveEnumWchar (string key)
	{
		return unarchiveEnum!(wchar)(key);
	}

	/**
	 * Unarchives the value associated with the given id as a bool.
	 * 
	 * This method is used when the unarchiving a enum value with the base type bool. 
	 * 
	 * Params:
	 *     id = the id associated with the value
	 *     
	 * Returns: the unarchived value
	 */
	bool unarchiveEnumBool (Id id)
	{
		return unarchiveEnum!(bool)(id);
	}

	/// Ditto
	byte unarchiveEnumByte (Id id)
	{
		return unarchiveEnum!(byte)(id);
	}

	/// Ditto	
	char unarchiveEnumChar (Id id)
	{
		return unarchiveEnum!(char)(id);
	}

	/// Ditto
	dchar unarchiveEnumDchar (Id id)
	{
		return unarchiveEnum!(dchar)(id);
	}

	/// Ditto	
	int unarchiveEnumInt (Id id)
	{
		return unarchiveEnum!(int)(id);
	}

	/// Ditto
	long unarchiveEnumLong (Id id)
	{
		return unarchiveEnum!(long)(id);
	}

	/// Ditto	
	short unarchiveEnumShort (Id id)
	{
		return unarchiveEnum!(short)(id);
	}

	/// Ditto	
	ubyte unarchiveEnumUbyte (Id id)
	{
		return unarchiveEnum!(ubyte)(id);
	}

	/// Ditto	
	uint unarchiveEnumUint (Id id)
	{
		return unarchiveEnum!(uint)(id);
	}

	/// Ditto	
	ulong unarchiveEnumUlong (Id id)
	{
		return unarchiveEnum!(ulong)(id);
	}

	/// Ditto	
	ushort unarchiveEnumUshort (Id id)
	{
		return unarchiveEnum!(ushort)(id);
	}

	/// Ditto	
	wchar unarchiveEnumWchar (Id id)
	{
		return unarchiveEnum!(wchar)(id);
	}

	private T unarchiveEnum (T, U) (U keyOrId)
	{
		return read!(T);
	}

	/**
	 * Unarchives the base class associated with the given key.
	 * 
	 * This method is used to indicate that the all following calls to unarchive a
	 * value should be part of the base class. This method is usually called within the
	 * callback passed to unarchiveObject. The unarchiveObject method can the mark the
	 * end of the class.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * archive.unarchiveBaseClass("base");
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the base class.
	 *     
	 * See_Also: unarchiveObject
	 */
	void unarchiveBaseClass (string key)
	{
		//noop
	}
	
	/**
	 * Unarchives the object associated with the given key.
	 * 
	 * Examples:
	 * ---
	 * class Foo
	 * {
	 * 	int a;
	 * }
	 * 
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * 
	 * Id id;
	 * Object o;
	 * 
	 * archive.unarchiveObject("foo", id, o, {
	 * 	// unarchive the fields of Foo
	 * }); 
	 * 
	 * auto foo = cast(Foo) o;
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the object
	 *     id = the id associated with the object
	 *     result = the unarchived object
	 *     dg = a callback the performs the unarchiving of the individual fields
	 */
	void unarchiveObject (string key, out Id id, out Object result, void delegate () dg)
	{
		auto name = internalUnarchiveString!(string)(key, id);
		result = newInstance(name);
		id = Id.max;

		dg();
	}
	
	/**
	 * Unarchives the pointer associated with the given key.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * auto id = unarchivePointer("ptr", {
	 * 	// unarchive the value pointed to by the pointer
	 * });
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the pointer
	 *     dg = a callback that performs the unarchiving of value pointed to by the pointer
	 *     
	 * Returns: the id associated with the pointer
	 */
	Id unarchivePointer (string key, void delegate () dg)
	{
		dg();
		return Id.max;
	}
	
	/**
	 * Unarchives the reference associated with the given key.
	 * 
	 * A reference is reference to another value. For example, if an object is archived
	 * more than once, the first time it's archived it will actual archive the object.
	 * The second time the object will be archived a reference will be archived instead
	 * of the actual object.
	 * 
	 * This method is also used when unarchiving a pointer that points to a value that has
	 * been or will be unarchived as well.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * auto id = unarchiveReference("foo");
	 * 
	 * // unarchive the value with the associated id
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the reference
	 *     
	 * Returns: the id the reference refers to
	 */
	Id unarchiveReference (string key)
	{
		return read!(Id);
	}
	
	/**
	 * Unarchives the slice associated with the given key.
	 * 
	 * This method should be used when unarchiving an array that is a slice of an
	 * already unarchived array or an array that has not yet been unarchived.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * auto slice = unarchiveSlice("slice");
	 * 
	 * // slice the original array with the help of the unarchived slice 
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the slice
	 *     
	 * Returns: the unarchived slice
	 */
	Slice unarchiveSlice (string key)
	{
		return Slice.init;
	}
	
	/**
	 * Unarchives the struct associated with the given key.
	 * 
	 * Examples:
	 * ---
	 * struct Foo
	 * {
	 * 	int a;
	 * }
	 * 
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * archive.unarchiveStruct("foo", {
	 * 	// unarchive the fields of Foo
	 * });
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the string
	 *     dg = a callback that performs the unarchiving of the individual fields
	 */
	void unarchiveStruct (string key, void delegate () dg)
	{
		dg();
	}

	/**
	 * Unarchives the struct associated with the given id.
	 * 
	 * Examples:
	 * ---
	 * struct Foo
	 * {
	 * 	int a;
	 * }
	 * 
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * archive.unarchiveStruct(0, {
	 * 	// unarchive the fields of Foo
	 * });
	 * ---
	 * 
	 * Params:
	 *     id = the id associated with the struct
	 *     dg = a callback that performs the unarchiving of the individual fields.
	 * 	   		The callback will receive the key the struct was archived with.
	 */
	void unarchiveStruct (Id id, void delegate () dg)
	{
		dg();
	}

	/**
	 * Unarchives the typedef associated with the given key. 
	 * 
	 * Examples:
	 * ---
	 * typedef int Foo;
	 * Foo foo = 3;
	 * 
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * archive.unarchiveTypedef("foo", {
	 * 	// unarchive "foo" as the base type of Foo, i.e. int
	 * });
	 * ---
	 * 
	 * Params:
	 *     key = the key associated with the typedef
	 *     dg = a callback that performs the unarchiving of the value as
	 *     		 the base type of the typedef
	 */
	void unarchiveTypedef (string key, void delegate () dg)
	{
		dg();
	}
	
	/**
	 * Unarchives the string associated with the given id.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * auto str = archive.unarchiveString(0);
	 * ---
	 * 
	 * Params:
	 *     id = the id associated with the string
	 *     
	 * Returns: the unarchived string
	 */
	string unarchiveString (Id id)
	{
		return internalUnarchiveString!(string)(null, id);
	}
	
	/// Ditto
	wstring unarchiveWstring (Id id)
	{
		return internalUnarchiveString!(wstring)(id);
	}
	
	/// Ditto
	dstring unarchiveDstring (Id id)
	{
		return internalUnarchiveString!(dstring)(id);
	}
	
	/**
	 * Unarchives the string associated with the given key.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * 
	 * Id id;
	 * auto str = archive.unarchiveString("str", id);
	 * ---
	 * 
	 * Params:
	 *     id = the id associated with the string
	 *     
	 * Returns: the unarchived string
	 */
	string unarchiveString (string key, out Id id)
	{
		return internalUnarchiveString!(string)(key, id);
	}
	
	/// Ditto
	wstring unarchiveWstring (string key, out Id id)
	{
		return internalUnarchiveString!(wstring)(key, id);
	}
	
	/// Ditto
	dstring unarchiveDstring (string key, out Id id)
	{
		return internalUnarchiveString!(dstring)(key, id);
	}

	private T internalUnarchiveString (T) (string key, ref Id id = Id.max)
	{
		alias Unqual!(ElementTypeOfArray!(T)) E;

		E[] buffer = new E[readLength];

		foreach (i, E e ; buffer)
			buffer[i] = read!(E);

		return cast(T) buffer;
	}

	private T internalUnarchiveString (T) (ref Id id = Id.max)
	{
		return internalUnarchiveString!(T)(null, id);
	}

	/**
	 * Unarchives the value associated with the given key.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * auto foo = unarchiveBool("foo");
	 * ---
	 * Params:
	 *     key = the key associated with the value
	 *     
	 * Returns: the unarchived value
	 */
	bool unarchiveBool (string key)
	{
		return unarchivePrimitive!(bool)(key);
	}
	
	/// Ditto
	byte unarchiveByte (string key)
	{
		return unarchivePrimitive!(byte)(key);
	}
	
	//currently not suppported by to!()
    /*cdouble unarchiveCdouble (string key)
	{
		return unarchivePrimitive!(cdouble)(key);
	}*/
	 
	 //currently not implemented but a reserved keyword
    /*cent unarchiveCent (string key)
	{
		return unarchivePrimitive!(cent)(key);
	}*/
	
	// currently not suppported by to!()
    /*cfloat unarchiveCfloat (string key)
	{
		return unarchivePrimitive!(cfloat)(key);
	}*/
	
	/// Ditto
	char unarchiveChar (string key)
	{
		return unarchivePrimitive!(char)(key);
	}
	 
	 //currently not implemented but a reserved keyword
	/*creal unarchiveCreal (string key)
	{
		return unarchivePrimitive!(creal)(key);
	}*/

	/// Ditto
	dchar unarchiveDchar (string key)
	{
		return unarchivePrimitive!(dchar)(key);
	}
	
	/// Ditto
	double unarchiveDouble (string key)
	{
		//return unarchivePrimitive!(double)(key);
		return double.init;
	}

	/// Ditto	
	float unarchiveFloat (string key)
	{
		//return unarchivePrimitive!(float)(key);
		return float.init;
	}

	//currently not suppported by to!()
    /*idouble unarchiveIdouble (string key)
	{
		return unarchivePrimitive!(idouble)(key);
	}*/
    
    // currently not suppported by to!()*/
    /*ifloat unarchiveIfloat (string key)
	{
		return unarchivePrimitive!(ifloat)(key);
	}*/

	/// Ditto
	int unarchiveInt (string key)
	{
		return unarchivePrimitive!(int)(key);
	}

	// currently not suppported by to!()
    /*ireal unarchiveIreal (string key)
	{
		return unarchivePrimitive!(ireal)(key);
	}*/

	/// Ditto
	long unarchiveLong (string key)
	{
		return unarchivePrimitive!(long)(key);
	}

	/// Ditto
	real unarchiveReal (string key)
	{
		//return unarchivePrimitive!(real)(key);
		return real.init;
	}

	/// Ditto	
	short unarchiveShort (string key)
	{
		return unarchivePrimitive!(short)(key);
	}

	/// Ditto	
	ubyte unarchiveUbyte (string key)
	{
		return unarchivePrimitive!(ubyte)(key);
	}

	// currently not implemented but a reserved keyword
    /*ucent unarchiveCcent (string key)
	{
		return unarchivePrimitive!(ucent)(key);
	}*/

	/// Ditto
	uint unarchiveUint (string key)
	{
		return unarchivePrimitive!(uint)(key);
	}

	/// Ditto	
	ulong unarchiveUlong (string key)
	{
		return unarchivePrimitive!(ulong)(key);
	}

	/// Ditto	
	ushort unarchiveUshort (string key)
	{
		return unarchivePrimitive!(ushort)(key);
	}

	/// Ditto	
	wchar unarchiveWchar (string key)
	{
		return unarchivePrimitive!(wchar)(key);
	}

	/**
	 * Unarchives the value associated with the given id.
	 * 
	 * Examples:
	 * ---
	 * auto archive = new XmlArchive!();
	 * archive.beginUnarchiving(data);
	 * auto foo = unarchiveBool(0);
	 * ---
	 * Params:
	 *     id = the id associated with the value
	 *     
	 * Returns: the unarchived value
	 */
	bool unarchiveBool (Id id)
	{
		return unarchivePrimitive!(bool)(id);
	}

	/// Ditto
	byte unarchiveByte (Id id)
	{
		return unarchivePrimitive!(byte)(id);
	}

	//currently not suppported by to!()
	/*cdouble unarchiveCdouble (Id id)
	{
		return unarchivePrimitive!(cdouble)(id);
	}*/

	 //currently not implemented but a reserved keyword
	/*cent unarchiveCent (Id id)
	{
		return unarchivePrimitive!(cent)(id);
	}*/

	// currently not suppported by to!()
	/*cfloat unarchiveCfloat (Id id)
	{
		return unarchivePrimitive!(cfloat)(id);
	}*/

	/// Ditto
	char unarchiveChar (Id id)
	{
		return unarchivePrimitive!(char)(id);
	}

	 //currently not implemented but a reserved keyword
	/*creal unarchiveCreal (Id id)
	{
		return unarchivePrimitive!(creal)(id);
	}*/

	/// Ditto
	dchar unarchiveDchar (Id id)
	{
		return unarchivePrimitive!(dchar)(id);
	}

	/// Ditto
	double unarchiveDouble (Id id)
	{
		return unarchivePrimitive!(double)(id);
	}

	/// Ditto	
	float unarchiveFloat (Id id)
	{
		return unarchivePrimitive!(float)(id);
	}

	//currently not suppported by to!()
	/*idouble unarchiveIdouble (Id id)
	{
		return unarchivePrimitive!(idouble)(id);
	}*/

	// currently not suppported by to!()*/
	/*ifloat unarchiveIfloat (Id id)
	{
		return unarchivePrimitive!(ifloat)(id);
	}*/

	/// Ditto
	int unarchiveInt (Id id)
	{
		return unarchivePrimitive!(int)(id);
	}

	// currently not suppported by to!()
	/*ireal unarchiveIreal (Id id)
	{
		return unarchivePrimitive!(ireal)(id);
	}*/

	/// Ditto
	long unarchiveLong (Id id)
	{
		return unarchivePrimitive!(long)(id);
	}

	/// Ditto
	real unarchiveReal (Id id)
	{
		//return unarchivePrimitive!(real)(id);
		return real.init;
	}

	/// Ditto	
	short unarchiveShort (Id id)
	{
		return unarchivePrimitive!(short)(id);
	}

	/// Ditto	
	ubyte unarchiveUbyte (Id id)
	{
		return unarchivePrimitive!(ubyte)(id);
	}

	// currently not implemented but a reserved keyword
	/*ucent unarchiveCcent (Id id)
	{
		return unarchivePrimitive!(ucent)(id);
	}*/

	/// Ditto
	uint unarchiveUint (Id id)
	{
		return unarchivePrimitive!(uint)(id);
	}

	/// Ditto	
	ulong unarchiveUlong (Id id)
	{
		return unarchivePrimitive!(ulong)(id);
	}

	/// Ditto	
	ushort unarchiveUshort (Id id)
	{
		return unarchivePrimitive!(ushort)(id);
	}

	/// Ditto	
	wchar unarchiveWchar (Id id)
	{
		return unarchivePrimitive!(wchar)(id);
	}

	private T unarchivePrimitive (T, U) (U keyOrId)
	{
		return read!(T);
	}

	/**
	 * Performs post processing of the array associated with the given id.
	 * 
	 * Post processing can basically be anything that the archive wants to do. This
	 * method is called by the serializer once for each serialized array at the end of
	 * the serialization process when all values have been serialized.
	 * 
	 * With this method the archive has a last chance of changing an archived array to
	 * an archived slice instead.
	 * 
	 * Params:
	 *     id = the id associated with the array
	 */
	void postProcessArray (Id id)
	{
		//noop
	}

private:

	size_t readLength ()
	{
		return read!(size_t);
	}

	void append (T) (T value)
	{
		buffer.append!(BitType!(T))(value);
	}

	T read (T) ()
	{
		return cast(T) rawData.read!(BitType!(T));
	}

	template BitType (T)
	{
		static if (T.sizeof <= ubyte.sizeof)
			alias ubyte BitType;

		else static if (T.sizeof <= ushort.sizeof)
			alias ushort BitType;

		else static if (T.sizeof <= uint.sizeof)
			alias uint BitType;

		else static if (T.sizeof <= ulong.sizeof)
			alias ulong BitType;

		else
			static assert(false, format!(`Unsupported size "`, T.sizeof, `" of type "`, T, `"`));
	}
}