/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 6, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.archives.Archive;

version (Tango)
	import tango.util.Convert;

else
{
	import std.array;
	import std.conv;
	import std.utf;
	static import std.string;

	private alias ConvException ConversionException;
}

import orange.serialization.archives.ArchiveException;
import orange.core.string;
import orange.util.Traits;

private enum ArchiveMode
{
	archiving,
	unarchiving
}

/**
 * This struct is a type independent representation of an array. This struct is used
 * when sending an array for archiving from the serializer to the archive.
 */
struct Array
{
	version (Tango)
		/// The start address of the array.
		void* ptr;
		
	else
		/// The start address of the array.
		mixin(`const(void)* ptr;`);

	/// The length of the array
	size_t length;
	
	/// The size of an individual element stored in the array, in bytes.
	size_t elementSize;
	
	/**
	 * Returns true if the given array is a slice of the receiver.
	 * 
	 * Params:
	 *     b = the array to check if it's a slice 
	 *     
	 * Returns: true if the given array is a slice of the receiver.
	 */
	bool isSliceOf (Array b)
	{
		return ptr >= b.ptr && ptr + length * elementSize <= b.ptr + b.length * b.elementSize;
	}
}

/**
 * This struct is a type independent representation of a slice. This struct is used
 * when sending a slice for archiving from the serializer to the archive.
 */
struct Slice
{
	/// The length of the slice.
	size_t length;
	
	/// The offset of the slice, i.e. where the slice begins in the array.
	size_t offset;
	
	/// The id of the slice.
	size_t id = size_t.max;
}

/**
 * This interface represents an archive. This is the interface all archive
 * implementations need to implement to be able to be used as an archive with the
 * serializer.
 * 
 * The archive is the backend in the serialization process. It's independent of the
 * serializer and any archive implementation. Although there are a couple of
 * limitations of what archive types can be implemented (see below).
 * 
 * The archive is responsible for archiving primitive types in the format chosen by
 * the archive implementation. The archive ensures that all types are properly
 * archived in a format that can be later unarchived.
 * 
 * The archive can only handle primitive types, like strings, integers, floating
 * point numbers and so on. It can not handle more complex types like objects or
 * arrays; the serializer is responsible for breaking the complex types into
 * primitive types that the archive can handle.
 * 
 * Implementing an Archive Type:
 * 
 * There are a couple of limitations when implementing a new archive, this is due
 * to how the serializer and the archive interface is built. Except for what this
 * interface says explicitly an archive needs to be able to handle the following:
 * 
 * $(UL
 * 	$(LI unarchive a value based on a key or id, regardless of where in the archive
 * 		the value is located)
 * $(LI most likely be able to modify already archived data)
 * $(LI structured formats like JSON, XML and YAML works best)
 * )
 * 
 * If a method takes a delegate as one of its parameters that delegate should be
 * considered as a callback to the serializer. The archive need to make sure that
 * any archiving that is performed in the callback be a part of the type that is
 * currently being archived. This is easiest explained by an example:
 * 
 * ---
 * void archiveArray (Array array, string type, string key, Id id, void delegate () dg)
 * {
 * 	markBegningOfNewType("array");
 * 	storeMetadata(type, key, id);
 * 
 * 	beginNewScope();
 * 	dg();
 * 	endScope();
 * 
 * 	markEndOfType();
 * }
 * ---
 * 
 * In the above example the archive have to make sure that any values archived by
 * the callback (the delegate) get archived as an element of the array. The same
 * principle applies to objects, structs, associative arrays and other
 * non-primitive that accepts an delegate as a parameter.
 * 
 * When implementing a new archive type, if any of these methods do not make sense
 * for that particular implementation just implement an empty method and return
 * T.init, if the method returns a value.
 */
interface Archive
{
	/// The type of an ID.
	alias size_t Id;
	
	version (Tango)
		/// The typed used to represent the archived data in an untyped form.
		alias void[] UntypedData;
	
	else
		/// The typed used to represent the archived data in an untyped form.
		mixin ("alias immutable(void)[] UntypedData;");
	
	/// Starts the archiving process. Call this method before archiving any values.
	void beginArchiving ();
	
	/**
	 * There are a couple of limitations when implementing a new archive, this is due
	 * Begins the unarchiving process. Call this method before unarchiving any values.
	 * 
	 * Params:
	 *     data = the data to unarchive
	 */
	void beginUnarchiving (UntypedData data);
	
	/// Returns the data stored in the archive in an untyped form.
	UntypedData untypedData ();
	
	/**
	 * Resets the archive. This resets the archive in a state making it ready to start
	 * a new archiving process.
	 */	
	void reset ();
	
	/**
	 * Archives an array.
	 * 
	 * Examples:
	 * ---
	 * int[] arr = [1, 2, 3];
	 * 
	 * auto archive = new XMLArchive!();
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
	void archiveArray (Array array, string type, string key, Id id, void delegate () dg);
	
	/**
	 * Archives an associative array.
	 * 
	 * Examples:
	 * ---
	 * int[string] arr = ["a"[] : 1, "b" : 2, "c" : 3];
	 * 
	 * auto archive = new XMLArchive!();
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
	void archiveAssociativeArray (string keyType, string valueType, size_t length, string key, Id id, void delegate () dg);
	
	/**
	 * Archives an associative array key.
	 * 
	 * There are separate methods for archiving associative array keys and values
	 * because both the key and the value can be of arbitrary type and needs to be
	 * archive on its own.
	 * 
	 * Examples:
	 * ---
	 * int[string] arr = ["a"[] : 1, "b" : 2, "c" : 3];
	 * 
	 * auto archive = new XMLArchive!();
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
	void archiveAssociativeArrayKey (string key, void delegate () dg);
	
	/**
	 * Archives an associative array value.
	 * 
	 * There are separate methods for archiving associative array keys and values
	 * because both the key and the value can be of arbitrary type and needs to be
	 * archive on its own.
	 *
	 * Examples:
	 * ---
	 * int[string] arr = ["a"[] : 1, "b" : 2, "c" : 3];
	 * 
	 * auto archive = new XMLArchive!();
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
	void archiveAssociativeArrayValue (string key, void delegate () dg);
	
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
	 * auto archive = new XMLArchive!();
	 * archive.archive(foo, "bool", "foo", 0);
	 * ---
	 * 
	 * Params:
	 *     value = the value to archive
	 *     baseType = the base type of the enum 
	 *     key = the key associated with the value
	 *     id = the id associated with the value
	 */
	void archiveEnum (bool value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (bool value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (byte value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (char value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (dchar value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (int value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (long value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (short value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (ubyte value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (uint value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (ulong value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (ushort value, string baseType, string key, Id id);
	
	/// Ditto
	void archiveEnum (wchar value, string baseType, string key, Id id);
	
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
	 * class Base {}
	 * class Foo : Base {}
	 * 
	 * auto archive = new XMLArchive!();
	 * archive.archiveBaseClass("Base", "base", "0");
	 * ---
	 * 
	 * Params:
	 *     type = the type of the base class to archive
	 *     key = the key associated with the base class
	 *     id = the id associated with the base class
	 */
	void archiveBaseClass (string type, string key, Id id);
	
	/**
	 * Archives a null pointer or reference.
	 * 
	 * Examples:
	 * ---
	 * int* ptr;
	 * 
	 * auto archive = new XMLArchive!();
	 * archive.archiveNull(typeof(ptr).stringof, "ptr");
	 * ---
	 * 
	 * Params:
	 *     type = the runtime type of the pointer or reference to archive 
	 *     key = the key associated with the null pointer
	 */
	void archiveNull (string type, string key);
	
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
	 * auto archive = new XMLArchive!();
	 * archive.archiveObject(Foo.classinfo.name, "Foo", "foo", "0", {
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
	void archiveObject (string runtimeType, string type, string key, Id id, void delegate () dg);
	
	/**
	 * Archives a pointer.
	 * 
	 * 
	 * 
	 * Params:
	 *     key = the key associated with the pointer
	 *     id = the id associated with the pointer
	 *     dg = a callback that performs the archiving of value pointed to by the pointer
	 */
	void archivePointer (string key, Id id, void delegate () dg);
	
	/**
	 * Archives a pointer.
	 * 
	 * Params:
	 *     pointeeId = the id associated with the value the pointer points to
	 *     key = the key associated with the pointer
	 *     id = the id associated with the pointer
	 */
	void archivePointer (Id pointeeId, string key, Id id);
	
	/**
	 * Archives a reference.
	 * 
	 * A reference is reference to another value. For example, if an object is archived
	 * more than once, the first time it's archived it will actual archive the object.
	 * The second time the object will be archived a reference will be archived instead
	 * of the actual object.
	 * 
	 * Params:
	 *     key = the key associated with the reference
	 *     id = the id of the value this reference refers to
	 */
	void archiveReference (string key, Id id);
	
	/**
	 * Archives a slice.
	 * 
	 * 
	 * Params:
	 *     slice = the slice to be archived 
	 *     sliceId = the id associated with the slice
	 *     arrayId = the id associated with the array this slice is a slice of
	 */
	void archiveSlice (Slice slice, Id sliceId, Id arrayId);
	
	/**
	 * 
	 * Params:
	 *     type = 
	 *     key = 
	 *     id = 
	 *     dg =
	 */
	void archiveStruct (string type, string key, Id id, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     type = 
	 *     key = 
	 *     id = 
	 *     dg =
	 */
	void archiveTypedef (string type, string key, Id id, void delegate () dg);

	/**
	 * 
	 * Params:
	 *     value = 
	 *     key = 
	 *     id =
	 */
	void archive (string value, string key, Id id);
	
	///
	void archive (wstring value, string key, Id id);
	
	///
	void archive (dstring value, string key, Id id);
	
	///	
	void archive (bool value, string key, Id id);
	
	///
	void archive (byte value, string key, Id id);
	
	
	//void archive (cdouble value, string key, Id id); // currently not supported by to!()
	
	
	//void archive (cent value, string key, Id id);
	
	//void archive (cfloat value, string key, Id id); // currently not supported by to!()
	
	///
	void archive (char value, string key, Id id); // currently not implemented but a reserved keyword
	
	//void archive (creal value, string key, Id id); // currently not supported by to!()
	
	///
	void archive (dchar value, string key, Id id);
	
	///
	void archive (double value, string key, Id id);
	
	///
	void archive (float value, string key, Id id);
	
	
	//void archive (idouble value, string key, Id id); // currently not supported by to!()
	
	//void archive (ifloat value, string key, Id id); // currently not supported by to!()
	
	///
	void archive (int value, string key, Id id);
	

	//void archive (ireal value, string key, Id id); // currently not supported by to!()
	
	///
	void archive (long value, string key, Id id);
	
	///
	void archive (real value, string key, Id id);
	
	///
	void archive (short value, string key, Id id);
	
	///
	void archive (ubyte value, string key, Id id);
	
	//void archive (ucent value, string key, Id id); // currently not implemented but a reserved keyword
	
	///
	void archive (uint value, string key, Id id);
	
	///
	void archive (ulong value, string key, Id id);
	
	///
	void archive (ushort value, string key, Id id);
	
	///
	void archive (wchar value, string key, Id id);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg = 
	 * Returns:
	 */
	Id unarchiveArray (string key, void delegate (size_t length) dg);
	
	/**
	 * 
	 * Params:
	 *     id = 
	 *     dg =
	 */
	void unarchiveArray (Id id, void delegate (size_t length) dg);
	
	/**
	 * 
	 * Params:
	 *     type = 
	 *     dg = 
	 * Returns:
	 */
	Id unarchiveAssociativeArray (string type, void delegate (size_t length) dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg =
	 */
	void unarchiveAssociativeArrayKey (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg =
	 */
	void unarchiveAssociativeArrayValue (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 * Returns:
	 */
	bool unarchiveEnumBool (string key);
	
	///
	byte unarchiveEnumByte (string key);
	
	///
	char unarchiveEnumChar (string key);
	
	///
	dchar unarchiveEnumDchar (string key);
	
	///
	int unarchiveEnumInt (string key);
	
	///
	long unarchiveEnumLong (string key);
	
	///
	short unarchiveEnumShort (string key);
	
	///
	ubyte unarchiveEnumUbyte (string key);
	
	///
	uint unarchiveEnumUint (string key);
	
	///
	ulong unarchiveEnumUlong (string key);
	
	///
	ushort unarchiveEnumUshort (string key);
	
	///
	wchar unarchiveEnumWchar (string key);
	
	/**
	 * 
	 * Params:
	 *     key =
	 */
	void unarchiveBaseClass (string key);
	
	/**
	 * 
	 * Params:
	 *     key =
	 */
	//void unarchiveNull (string key);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     id = 
	 *     result = 
	 *     dg =
	 */
	void unarchiveObject (string key, out Id id, out Object result, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg = 
	 * Returns:
	 */
	Id unarchivePointer (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 * Returns:
	 */
	Id unarchiveReference (string key);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 * Returns:
	 */
	Slice unarchiveSlice (string key);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg =
	 */
	void unarchiveStruct (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     dg =
	 */
	void unarchiveTypedef (string key, void delegate () dg);
	
	/**
	 * 
	 * Params:
	 *     id = 
	 * Returns:
	 */
	string unarchiveString (Id id);
	
	///
	wstring unarchiveWstring (Id id);
	
	///
	dstring unarchiveDstring (Id id);
	
	/**
	 * 
	 * Params:
	 *     key = 
	 *     id = 
	 * Returns:
	 */
	string unarchiveString (string key, out Id id);
	
	///
	wstring unarchiveWstring (string key, out Id id);
	
	///
	dstring unarchiveDstring (string key, out Id id);
	
	///
    bool unarchiveBool (string key);
	
	///
    byte unarchiveByte (string key);
    
    //cdouble unarchiveCdouble (string key); // currently not supported by to!()
    //cent unarchiveCent (string key); // currently not implemented but a reserved keyword
    //cfloat unarchiveCfloat (string key); // currently not supported by to!()
	
	///
    char unarchiveChar (string key); // currently not implemented but a reserved keyword
    //creal unarchiveCreal (string key); // currently not supported by to!()
    
    dchar unarchiveDchar (string key);
	
	///
    double unarchiveDouble (string key);
	
	///
    float unarchiveFloat (string key);
    //idouble unarchiveIdouble (string key); // currently not supported by to!()
    //ifloat unarchiveIfloat (string key); // currently not supported by to!()*/
	
	///
    int unarchiveInt (string key);
    
	//int unarchiveInt (Id id);
    //ireal unarchiveIreal (string key); // currently not supported by to!()
	
	///
    long unarchiveLong (string key);
	
	///
    real unarchiveReal (string key);
	
	///
    short unarchiveShort (string key);
	
	///
    ubyte unarchiveUbyte (string key);
	
	///
    //ucent unarchiveCcent (string key); // currently not implemented but a reserved keyword
    uint unarchiveUint (string key);
	
	///
    ulong unarchiveUlong (string key);
	
	///
    ushort unarchiveUshort (string key);
	
	///
    wchar unarchiveWchar (string key);
	
	/**
	 * 
	 * Params:
	 *     id =
	 */
	void postProcessArray (Id id);
	
	/**
	 * 
	 * Params:
	 *     id =
	 */
	void postProcessPointer (Id id);
}

/**
 * 
 * Authors: doob
 */
abstract class Base (U) : Archive
{
	///
	version (Tango) alias U[] Data;
	else mixin ("alias immutable(U)[] Data;");
	
	///
	alias void delegate (ArchiveException exception, string[] data) ErrorCallback;
	
	///
	protected ErrorCallback errorCallback;
	
	/**
	 * 
	 * Params:
	 *     errorCallback =
	 */
	protected this (ErrorCallback errorCallback)
	{
		this.errorCallback = errorCallback;
	}
	
	/**
	 * 
	 * Params:
	 *     value = 
	 * Returns:
	 */
	protected Data toData (T) (T value)
	{
		try
		{
			static if (isFloatingPoint!(T))
				return floatingPointToData(value);

			else
				return to!(Data)(value);
		}
		
		catch (ConversionException e)
			throw new ArchiveException(e);
	}
	
	/**
	 * 
	 * Params:
	 *     value = 
	 * Returns:
	 */
	protected T fromData (T) (Data value)
	{
		try
		{
			static if (is(T == wchar))
				return toWchar(value);

			else
				return to!(T)(value);
		}

		catch (ConversionException e)
			throw new ArchiveException(e);
	}
	
	/**
	 * 
	 * Params:
	 *     value = 
	 * Returns:
	 */
	protected Data floatingPointToData (T) (T value)
	{
		static assert(isFloatingPoint!(T), format!(`The given value of the type "`, T,
			`" is not a valid type, the only valid types for this method are floating point types.`));
		
		version (Tango)
			return to!(Data)(value);
			
		else
			return to!(Data)(std.string.format("%a", value));
	}
	
	/**
	 * 
	 * Params:
	 *     value = 
	 * Returns:
	 */
	protected Id toId (Data value)
	{
		return fromData!(Id)(value);
	}
	
	/**
	 * 
	 * Params:
	 *     a = 
	 *     b = 
	 * Returns:
	 */
	protected bool isSliceOf (T, U = T) (T[] a, U[] b)
	{
		void* aPtr = a.ptr;
		void* bPtr = b.ptr;
		
		return aPtr >= bPtr && aPtr + a.length * T.sizeof <= bPtr + b.length * U.sizeof;
	}
	
	private wchar toWchar (Data value)
	{
		version (Tango)
			return to!(wchar)(value);
		
		else
		{
			auto c = value.front;

			if (codeLength!(wchar)(c) > 2)
				throw new ConversionException("Could not convert `" ~
					to!(string)(value) ~ "` of type " ~
					Data.stringof ~ " to type wchar.");

			return cast(wchar) c;
		}
	}
}]