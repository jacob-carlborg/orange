/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.archives.XmlArchive;

import std.conv;

import orange.serialization.archives._;
import orange.serialization.Serializer;
import orange.util._;
import orange.xml.XmlDocument;

private enum ArchiveMode
{
	archiving,
	unarchiving
}

/**
 * This class is a concrete implementation of the Archive interface. This archive
 * uses XML as the final format for the serialized data.
 */
final class XmlArchive (U = char) : ArchiveBase!(U)
{
	private alias Archive.Id Id;

	private struct Tags
	{
		static enum Data structTag = "struct";
		static enum Data dataTag = "data";
		static enum Data archiveTag = "archive";
		static enum Data arrayTag = "array";
		static enum Data objectTag = "object";
		static enum Data baseTag = "base";
		static enum Data stringTag = "string";
		static enum Data referenceTag = "reference";
		static enum Data pointerTag = "pointer";
		static enum Data associativeArrayTag = "associativeArray";
		static enum Data typedefTag = "typedef";
		static enum Data nullTag = "null";
		static enum Data enumTag = "enum";
		static enum Data sliceTag = "slice";
		static enum Data elementTag = "element";
		static enum Data keyTag = "key";
		static enum Data valueTag = "value";
	}

	private struct Attributes
	{
		static enum Data invalidAttribute = "\0";
		static enum Data typeAttribute = "type";
		static enum Data versionAttribute = "version";
		static enum Data lengthAttribute = "length";
		static enum Data keyAttribute = "key";
		static enum Data runtimeTypeAttribute = "runtimeType";
		static enum Data idAttribute = "id";
		static enum Data keyTypeAttribute = "keyType";
		static enum Data valueTypeAttribute = "valueType";
		static enum Data offsetAttribute = "offset";
		static enum Data baseTypeAttribute = "baseType";
	}

	private struct Node
	{
		XmlDocument.Node parent;
		XmlDocument.Node node;
		Id id;
		string key;
	}

	private
	{
		Data archiveType = "org.dsource.orange.xml";
		Data archiveVersion = "1.0.0";

		XmlDocument doc;
		doc.Node lastElement;

		bool hasBegunArchiving;
		bool hasBegunUnarchiving;

		Node[Id] archivedArrays;
		Node[Id] archivedPointers;
		void[][Data] unarchivedSlices;
	}

	/**
	 * Creates a new instance of this class with the give error callback.
	 *
	 * Params:
	 *     errorCallback = The callback to be called when an error occurs
	 */
	this (ErrorCallback errorCallback = null)
	{
		super(errorCallback);
		doc = new XmlDocument;
	}

	/// Starts the archiving process. Call this method before archiving any values.
	public void beginArchiving ()
	{
		if (!hasBegunArchiving)
		{
			doc.header;
			lastElement = doc.tree.element(Tags.archiveTag)
				.attribute(Attributes.typeAttribute, archiveType)
				.attribute(Attributes.versionAttribute, archiveVersion);
			lastElement = lastElement.element(Tags.dataTag);

			hasBegunArchiving = true;
		}
	}

	/**
	 * Begins the unarchiving process. Call this method before unarchiving any values.
	 *
	 * Params:
	 *     untypedData = the data to unarchive
	 */
	public void beginUnarchiving (UntypedData untypedData)
	{
		auto data = cast(Data) untypedData;

		if (!hasBegunUnarchiving)
		{
			doc.parse(data);
			hasBegunUnarchiving = true;

			auto set = doc.query[Tags.archiveTag][Tags.dataTag];

			if (set.nodes.length == 1)
				lastElement = set.nodes[0];

			else
			{
				auto dataTag = to!(string)(Tags.dataTag);

				if (set.nodes.length == 0)
					error(errorMessage!(ArchiveMode.unarchiving) ~ `The "` ~ to!(string)(Tags.dataTag) ~ `" tag could not be found.`, [dataTag]);

				else
					error(errorMessage!(ArchiveMode.unarchiving) ~ `There were more than one "` ~ to!(string)(Tags.dataTag) ~ `" tag.`, [dataTag]);
			}
		}
	}

	/// Returns the data stored in the archive in an untyped form.
	UntypedData untypedData ()
	{
		return doc.toString();
	}

	/// Returns the data stored in the archive in an typed form.
	Data data ()
	{
		return doc.toString;
	}

	/**
	 * Resets the archive. This resets the archive in a state making it ready to start
	 * a new archiving process.
	 */
	void reset ()
	{
		hasBegunArchiving = false;
		hasBegunUnarchiving = false;
		doc.reset;
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
		restore(lastElement) in {
			internalArchiveArray(array, type, key, id, Tags.arrayTag);
			dg();
		};
	}

	private void internalArchiveArray(Array array, string type, string key, Id id, Data tag, Data content = null)
	{
		auto parent = lastElement;

		if (array.length == 0)
			lastElement = lastElement.element(tag);

		else
			lastElement = doc.createNode(tag, content);

		lastElement.attribute(Attributes.typeAttribute, toData(type))
		.attribute(Attributes.lengthAttribute, toData(array.length))
		.attribute(Attributes.keyAttribute, toData(key))
		.attribute(Attributes.idAttribute, toData(id));

		addArchivedArray(id, parent, lastElement, key);
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
		restore(lastElement) in {
			lastElement = lastElement.element(Tags.associativeArrayTag)
			.attribute(Attributes.keyTypeAttribute, toData(keyType))
			.attribute(Attributes.valueTypeAttribute, toData(valueType))
			.attribute(Attributes.lengthAttribute, toData(length))
			.attribute(Attributes.keyAttribute, key)
			.attribute(Attributes.idAttribute, toData(id));

			dg();
		};
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
		internalArchiveAAKeyValue(key, Tags.keyTag, dg);
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
		internalArchiveAAKeyValue(key, Tags.valueTag, dg);
	}

	private void internalArchiveAAKeyValue (string key, Data tag, void delegate () dg)
	{
		restore(lastElement) in {
			lastElement = lastElement.element(tag)
			.attribute(Attributes.keyAttribute, toData(key));

			dg();
		};
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
		lastElement.element(Tags.enumTag, toData(value))
		.attribute(Attributes.typeAttribute, toData(type))
		.attribute(Attributes.baseTypeAttribute, toData(T.stringof))
		.attribute(Attributes.keyAttribute, toData(key))
		.attribute(Attributes.idAttribute, toData(id));
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
		lastElement = lastElement.element(Tags.baseTag)
		.attribute(Attributes.typeAttribute, toData(type))
		.attribute(Attributes.keyAttribute, toData(key))
		.attribute(Attributes.idAttribute, toData(id));
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
		lastElement.element(Tags.nullTag)
		.attribute(Attributes.typeAttribute, toData(type))
		.attribute(Attributes.keyAttribute, toData(key));
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
		restore(lastElement) in {
			lastElement = lastElement.element(Tags.objectTag)
			.attribute(Attributes.runtimeTypeAttribute, toData(runtimeType))
			.attribute(Attributes.typeAttribute, toData(type))
			.attribute(Attributes.keyAttribute, toData(key))
			.attribute(Attributes.idAttribute, toData(id));

			dg();
		};
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
		restore(lastElement) in {
			lastElement = lastElement.element(Tags.pointerTag)
			.attribute(Attributes.keyAttribute, toData(key))
			.attribute(Attributes.idAttribute, toData(id));

			dg();
		};
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
		lastElement.element(Tags.referenceTag, toData(id))
		.attribute(Attributes.keyAttribute, toData(key));
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
		if (auto sliceNode = getArchivedArray(sliceId))
		{
			if (auto arrayNode = getArchivedArray(arrayId))
			{
				sliceNode.parent.element(Tags.sliceTag, toData(arrayNode.id))
				.attribute(Attributes.keyAttribute, toData(sliceNode.key))
				.attribute(Attributes.offsetAttribute, toData(slice.offset))
				.attribute(Attributes.lengthAttribute, toData(slice.length));
			}
		}
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
		restore(lastElement) in {
			lastElement = lastElement.element(Tags.structTag)
			.attribute(Attributes.typeAttribute, toData(type))
			.attribute(Attributes.keyAttribute, toData(key))
			.attribute(Attributes.idAttribute, toData(id));

			dg();
		};
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
		restore(lastElement) in {
			lastElement = lastElement.element(Tags.typedefTag)
			.attribute(Attributes.typeAttribute, toData(type))
			.attribute(Attributes.keyAttribute, toData(key))
			.attribute(Attributes.idAttribute, toData(id));

			dg();
		};
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
		restore(lastElement) in {
			alias ElementTypeOfArray!(T) ElementType;
			auto array = Array(value.ptr, value.length, ElementType.sizeof);

			internalArchiveArray(array, ElementType.stringof, key, id, Tags.stringTag, toData(value));
		};
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
		archivePrimitive(value, key, id);
	}

	/// Ditto
	void archive (float value, string key, Id id)
	{
		archivePrimitive(value, key, id);
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
		archivePrimitive(value, key, id);
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
		lastElement.element(toData(T.stringof), toData(value))
		.attribute(Attributes.keyAttribute, toData(key))
		.attribute(Attributes.idAttribute, toData(id));
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
	Id unarchiveArray (string key, void delegate (size_t) dg)
	{
		return restore!(Id)(lastElement) in {
			auto element = getElement(Tags.arrayTag, key);

			if (!element.isValid)
				return Id.max;

			lastElement = element;
			auto len = getValueOfAttribute(Attributes.lengthAttribute);

			if (!len)
				return Id.max;

			auto length = fromData!(size_t)(len);
			auto id = getValueOfAttribute(Attributes.idAttribute);

			if (!id)
				return Id.max;

			dg(length);

			return toId(id);
		};
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
	void unarchiveArray (Id id, void delegate (size_t) dg)
	{
		restore(lastElement) in {
			auto element = getElement(Tags.arrayTag, to!(string)(id), Attributes.idAttribute);

			if (!element.isValid)
				return;

			lastElement = element;
			auto len = getValueOfAttribute(Attributes.lengthAttribute);

			if (!len)
				return;

			auto length = fromData!(size_t)(len);
			auto stringId = getValueOfAttribute(Attributes.idAttribute);

			if (!stringId)
				return;

			dg(length);
		};
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
		return restore!(Id)(lastElement) in {
			auto element = getElement(Tags.associativeArrayTag, key);

			if (!element.isValid)
				return Id.max;

			lastElement = element;
			auto len = getValueOfAttribute(Attributes.lengthAttribute);

			if (!len)
				return Id.max;

			auto length = fromData!(size_t)(len);
			auto id = getValueOfAttribute(Attributes.idAttribute);

			if (!id)
				return Id.max;

			dg(length);

			return toId(id);
		};
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
		internalUnarchiveAAKeyValue(key, Tags.keyTag, dg);
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
		internalUnarchiveAAKeyValue(key, Tags.valueTag, dg);
	}

	private void internalUnarchiveAAKeyValue (string key, Data tag, void delegate () dg)
	{
		restore(lastElement) in {
			auto element = getElement(tag, key);

			if (!element.isValid)
				return;

			lastElement = element;

			dg();
		};
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
		auto tag = Tags.enumTag;

		static if (isString!(U))
			auto element = getElement(Tags.enumTag, keyOrId);

		else static if (is(U == Id))
			auto element = getElement(tag, toData(keyOrId), Attributes.idAttribute);

		else
			static assert (false, format!(`Invalid type "`, U, `". Valid types are "string" and "Id"`));

		if (!element.isValid)
			return T.init;

		return fromData!(T)(element.value);
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
		auto element = getElement(Tags.baseTag, key);

		if (element.isValid)
			lastElement = element;
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
		restore(lastElement) in {
			auto tmp = getElement(Tags.objectTag, key, Attributes.keyAttribute, false);

			if (!tmp.isValid)
			{
				lastElement = getElement(Tags.nullTag, key);
				return;
			}

			lastElement = tmp;

			auto runtimeType = getValueOfAttribute(Attributes.runtimeTypeAttribute);

			if (!runtimeType)
				return;

			auto name = fromData!(string)(runtimeType);
			auto stringId = getValueOfAttribute(Attributes.idAttribute);

			if (!stringId)
				return;

			id = toId(stringId);
			result = newInstance(name);
			dg();
		};
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
		return restore!(Id)(lastElement) in {
			auto tmp = getElement(Tags.pointerTag, key, Attributes.keyAttribute, false);

			if (!tmp.isValid)
			{
				lastElement = getElement(Tags.nullTag, key);
				return Id.max;
			}

			lastElement = tmp;
			auto id = getValueOfAttribute(Attributes.idAttribute);

			if (!id)
				return Id.max;

			dg();

			return toId(id);
		};
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
		auto element = getElement(Tags.referenceTag, key, Attributes.keyAttribute, false);

		if (element.isValid)
			return toId(element.value);

		return Id.max;
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
		auto element = getElement(Tags.sliceTag, key, Attributes.keyAttribute, false);

		if (element.isValid)
		{
			auto length = fromData!(size_t)(getValueOfAttribute(Attributes.lengthAttribute, element));
			auto offset = fromData!(size_t)(getValueOfAttribute(Attributes.offsetAttribute, element));
			auto id = toId(element.value);

			return Slice(length, offset, id);
		}

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
	 *     key = the key associated with the struct
	 *     dg = a callback that performs the unarchiving of the individual fields
	 */
	void unarchiveStruct (string key, void delegate () dg)
	{
		restore(lastElement) in {
			auto element = getElement(Tags.structTag, key);

			if (!element.isValid)
				return;

			lastElement = element;
			dg();
		};
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
		restore(lastElement) in {
			auto element = getElement(Tags.structTag, toData(id), Attributes.idAttribute);

			if (!element.isValid)
				return;

			lastElement = element;
			dg();
		};
	}

	private T unarchiveTypeDef (T) (DataType key)
	{
		auto element = getElement(Tags.typedefTag, key);

		if (element.isValid)
			lastElement = element;

		return T.init;
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
		restore(lastElement) in {
			auto element = getElement(Tags.typedefTag, key);

			if (!element.isValid)
				return;

			lastElement = element;
			dg();
		};
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

	private T internalUnarchiveString (T) (string key, out Id id)
	{
		auto element = getElement(Tags.stringTag, key);

		if (!element.isValid)
			return T.init;

		auto value = fromData!(T)(element.value);
		auto stringId = getValueOfAttribute(Attributes.idAttribute, element);

		if (!stringId)
			return T.init;

		id = toId(stringId);
		return value;
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
	string unarchiveString (Id id)
	{
		return internalUnarchiveString!(string)(id);
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

	private T internalUnarchiveString (T) (Id id)
	{
		auto element = getElement(Tags.stringTag, to!(string)(id), Attributes.idAttribute);

		if (!element.isValid)
			return T.init;

		return fromData!(T)(element.value);
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
		return unarchivePrimitive!(double)(key);
	}

	/// Ditto
	float unarchiveFloat (string key)
	{
		return unarchivePrimitive!(float)(key);
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
		return unarchivePrimitive!(real)(key);
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
		return unarchivePrimitive!(real)(id);
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
		auto tag = toData(T.stringof);

		static if (isString!(U))
			auto element = getElement(tag, keyOrId);

		else static if (is(U == Id))
			auto element = getElement(tag, to!(string)(keyOrId), Attributes.idAttribute);

		else
			static assert (false, format!(`Invalid type "`, U, `". Valid types are "string" and "Id"`));

		if (!element.isValid)
			return T.init;

		return fromData!(T)(element.value);
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
		if (auto array = getArchivedArray(id))
			array.parent.attach(array.node);
	}

	private void addArchivedArray (Id id, doc.Node parent, doc.Node element, string key)
	{
		archivedArrays[id] = Node(parent, element, id, key);
	}

	private Node* getArchivedArray (Id id)
	{
		if (auto array = id in archivedArrays)
			return array;

		error(`Could not continue archiving due to no array with the Id "` ~ to!(string)(id) ~ `" was found.`, [to!(string)(id)]);

		return null;
	}

	private Node* getArchivedPointer (Id id)
	{
		if (auto pointer = id in archivedPointers)
			return pointer;

		error(`Could not continue archiving due to no pointer with the Id "` ~ to!(string)(id) ~ `" was found.`, [to!(string)(id)]);

		return null;
	}

	private doc.Node getElement (Data tag, string key, Data attribute = Attributes.keyAttribute, bool throwOnError = true)
	{
		auto set = lastElement.query[tag].attribute((doc.Node node) {
			if (node.name == attribute && node.value == key)
				return true;

			return false;
		});

		if (set.nodes.length == 1)
			return set.nodes[0].parent;

		if (throwOnError)
		{
			if (set.nodes.length == 0)
				error(`Could not find an element "` ~ to!(string)(tag) ~ `" with the attribute "` ~ to!(string)(attribute) ~ `" with the value "` ~ to!(string)(key) ~ `".`, [tag, Attributes.keyAttribute, key]);

			else
				error(`Could not unarchive the value with the key "` ~ to!(string)(key) ~ `" due to malformed data.`, [tag, Attributes.keyAttribute, key]);
		}

		return doc.Node.invalid;
	}

	private Data getValueOfAttribute (Data attribute, doc.Node element = doc.Node.invalid)
	{
		if (!element.isValid)
			element = lastElement;

		auto set = element.query.attribute(attribute);

		if (set.nodes.length == 1)
			return set.nodes[0].value;

		else
		{
			if (set.nodes.length == 0)
				error(`Could not find the attribute "` ~ to!(string)(attribute) ~ `".`, [attribute]);

			else
				error(`Could not unarchive the value of the attribute "` ~ to!(string)(attribute) ~ `" due to malformed data.`, [attribute]);
		}

		return null;
	}

	private template errorMessage (ArchiveMode mode = ArchiveMode.archiving)
	{
		static if (mode == ArchiveMode.archiving)
			enum errorMessage = "Could not continue archiving due to unrecognized data format: ";

		else static if (mode == ArchiveMode.unarchiving)
			enum errorMessage = "Could not continue unarchiving due to unrecognized data format: ";
	}
}