/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.serialization.archives.XMLArchive;

version (Tango)
	import tango.util.Convert : to;

else
	import std.conv;

import orange.core._;
import orange.serialization.archives._;
import orange.serialization.Serializer;
import orange.util._;
import orange.xml.XMLDocument;

final class XMLArchive (U = char) : Base!(U)
{
	private alias Archive.Id Id;
	
	private struct Tags
	{
		static const Data structTag = "struct";	
		static const Data dataTag = "data";
		static const Data archiveTag = "archive";
		static const Data arrayTag = "array";
		static const Data objectTag = "object";
		static const Data baseTag = "base";
		static const Data stringTag = "string";
		static const Data referenceTag = "reference";
		static const Data pointerTag = "pointer";
		static const Data associativeArrayTag = "associativeArray";
		static const Data typedefTag = "typedef";
		static const Data nullTag = "null";
		static const Data enumTag = "enum";
		static const Data sliceTag = "slice";
		static const Data elementTag = "element";
		static const Data keyTag = "key";
		static const Data valueTag = "value";
	}

	private struct Attributes
	{
		static const Data invalidAttribute = "\0";
		static const Data typeAttribute = "type";
		static const Data versionAttribute = "version";
		static const Data lengthAttribute = "length";
		static const Data keyAttribute = "key";
		static const Data runtimeTypeAttribute = "runtimeType";
		static const Data idAttribute = "id";
		static const Data keyTypeAttribute = "keyType";
		static const Data valueTypeAttribute = "valueType";
		static const Data offsetAttribute = "offset";
		static const Data baseTypeAttribute = "baseType";
	}
	
	private struct Node
	{
		XMLDocument!(U).Node parent;
		XMLDocument!(U).Node node;
		Id id;
		string key;
	}
	
	private
	{
		Data archiveType = "org.dsource.orange.xml";
		Data archiveVersion = "1.0.0";
		
		XMLDocument!(U) doc;
		doc.Node lastElement;
		
		bool hasBegunArchiving;
		bool hasBegunUnarchiving;
		
		Node[Id] archivedArrays;
		Node[Id] archivedPointers;
		void[][Data] unarchivedSlices;
	}
	
	this (ErrorCallback errorCallback = null)
	{
		super(errorCallback);
		doc = new XMLDocument!(U);
	}
	
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
				if (errorCallback)
				{
					auto dataTag = to!(string)(Tags.dataTag);
					
					if (set.nodes.length == 0)
						errorCallback(new ArchiveException(errorMessage!(ArchiveMode.unarchiving) ~ `The "` ~ to!(string)(Tags.dataTag) ~ `" tag could not be found.`, __FILE__, __LINE__), [dataTag]);
					
					else
						errorCallback(new ArchiveException(errorMessage!(ArchiveMode.unarchiving) ~ `There were more than one "` ~ to!(string)(Tags.dataTag) ~ `" tag.`, __FILE__, __LINE__), [dataTag]);
				}	
			}
		}
	}
	
	UntypedData untypedData ()
	{
		return doc.toString();
	}
	
	Data data ()
	{
		return doc.toString;
	}
	
	void reset ()
	{
		hasBegunArchiving = false;
		hasBegunUnarchiving = false;
		doc.reset;
	}
	
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
	
	void archiveAssociativeArrayKey (string key, void delegate () dg)
	{
		internalArchiveAAKeyValue(key, Tags.keyTag, dg);
	}
	
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
	
	void archiveEnum (bool value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	void archiveEnum (byte value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	void archiveEnum (char value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	void archiveEnum (dchar value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	void archiveEnum (int value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	void archiveEnum (long value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	void archiveEnum (short value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	void archiveEnum (ubyte value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	void archiveEnum (uint value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	void archiveEnum (ulong value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

	void archiveEnum (ushort value, string type, string key, Id id)
	{
		internalArchiveEnum(value, type, key, id);
	}

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
	
	void archiveBaseClass (string type, string key, Id id)
	{
		lastElement = lastElement.element(Tags.baseTag)
		.attribute(Attributes.typeAttribute, toData(type))
		.attribute(Attributes.keyAttribute, toData(key))
		.attribute(Attributes.idAttribute, toData(id));
	}
	
	void archiveNull (string type, string key)
	{
		lastElement.element(Tags.nullTag)
		.attribute(Attributes.typeAttribute, toData(type))
		.attribute(Attributes.keyAttribute, toData(key));
	}
	
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
	
	void archivePointer (string key, Id id, void delegate () dg)
	{
		restore(lastElement) in {
			auto parent = lastElement;
			lastElement = doc.createNode(Tags.pointerTag);
			
			lastElement.attribute(Attributes.keyAttribute, toData(key))
			.attribute(Attributes.idAttribute, toData(id));
			
			addArchivedPointer(id, parent, lastElement, key);			
			dg();
		};
	}
	
	void archivePointer (Id pointeeId, string key, Id id)
	{
		if (auto pointerNode = getArchivedPointer(id))
		{
			pointerNode.parent.element(Tags.pointerTag)
			.attribute(Attributes.keyAttribute, toData(pointerNode.key))
			.attribute(Attributes.idAttribute, toData(id))
			.element(Tags.referenceTag, toData(pointeeId))
			.attribute(Attributes.keyAttribute, toData(key));
		}
	}
	
	void archiveReference (string key, Id id)
	{
		lastElement.element(Tags.referenceTag, toData(id))
		.attribute(Attributes.keyAttribute, toData(key));
	}

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
	
	void archive (string value, string key, Id id)
	{
		archiveString(value, key, id);
	}
	
	void archive (wstring value, string key, Id id)
	{
		archiveString(value, key, id);
	}
	
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
	
	void archive (bool value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

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

	void archive (char value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	//currently not suppported by to!()
	/*void archive (creal value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	void archive (dchar value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	void archive (double value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

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

	void archive (int value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	//currently not suppported by to!()
	/*void archive (ireal value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	void archive (long value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	void archive (real value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	void archive (short value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	void archive (ubyte value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	//currently not implemented but a reserved keyword
	/*void archive (ucent value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}*/

	void archive (uint value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	void archive (ulong value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

	void archive (ushort value, string key, Id id)
	{
		archivePrimitive(value, key, id);
	}

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
	
	void unarchiveAssociativeArrayKey (string key, void delegate () dg)
	{
		internalUnarchiveAAKeyValue(key, Tags.keyTag, dg);
	}
	
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
	
	bool unarchiveEnumBool (string key)
	{
		return unarchiveEnum!(bool)(key);
	}
	
	byte unarchiveEnumByte (string key)
	{
		return unarchiveEnum!(byte)(key);
	}
	
	char unarchiveEnumChar (string key)
	{
		return unarchiveEnum!(char)(key);
	}
	
	dchar unarchiveEnumDchar (string key)
	{
		return unarchiveEnum!(dchar)(key);
	}
	
	int unarchiveEnumInt (string key)
	{
		return unarchiveEnum!(int)(key);
	}
	
	long unarchiveEnumLong (string key)
	{
		return unarchiveEnum!(long)(key);
	}
	
	short unarchiveEnumShort (string key)
	{
		return unarchiveEnum!(short)(key);
	}
	
	ubyte unarchiveEnumUbyte (string key)
	{
		return unarchiveEnum!(ubyte)(key);
	}
	
	uint unarchiveEnumUint (string key)
	{
		return unarchiveEnum!(uint)(key);
	}
	
	ulong unarchiveEnumUlong (string key)
	{
		return unarchiveEnum!(ulong)(key);
	}
	
	ushort unarchiveEnumUshort (string key)
	{
		return unarchiveEnum!(ushort)(key);
	}
	
	wchar unarchiveEnumWchar (string key)
	{
		return unarchiveEnum!(wchar)(key);
	}	
	
	private T unarchiveEnum (T) (string key)
	{
		auto element = getElement(Tags.enumTag, key);
		
		if (!element.isValid)
			return T.init;
		
		return fromData!(T)(element.value);
	}
	
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
	
	Id unarchiveReference (string key)
	{
		auto element = getElement(Tags.referenceTag, key, Attributes.keyAttribute, false);
		
		if (element.isValid)
			return toId(element.value);
		
		return Id.max;
	}
	
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
	
	private T unarchiveTypeDef (T) (DataType key)
	{
		auto element = getElement(Tags.typedefTag, key);
		
		if (element.isValid)
			lastElement = element;
		
		return T.init;
	}
	
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
	
	string unarchiveString (string key, out Id id)
	{
		return internalUnarchiveString!(string)(key, id);
	}
	
	wstring unarchiveWstring (string key, out Id id)
	{
		return internalUnarchiveString!(wstring)(key, id);
	}
	
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
	
	string unarchiveString (Id id)
	{
		return internalUnarchiveString!(string)(id);
	}
	
	wstring unarchiveWstring (Id id)
	{
		return internalUnarchiveString!(wstring)(id);
	}
	
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
	
	bool unarchiveBool (string key)
	{
		return unarchivePrimitive!(bool)(key);
	}
	
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
	
	char unarchiveChar (string key)
	{
		return unarchivePrimitive!(char)(key);
	}
	 
	 //currently not implemented but a reserved keyword
	/*creal unarchiveCreal (string key)
	{
		return unarchivePrimitive!(creal)(key);
	}*/
	
	dchar unarchiveDchar (string key)
	{
		return unarchivePrimitive!(dchar)(key);
	}
	
	double unarchiveDouble (string key)
	{
		return unarchivePrimitive!(double)(key);
	}
	
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

	int unarchiveInt (string key)
	{
		return unarchivePrimitive!(int)(key);
	}

	// currently not suppported by to!()
    /*ireal unarchiveIreal (string key)
	{
		return unarchivePrimitive!(ireal)(key);
	}*/

	long unarchiveLong (string key)
	{
		return unarchivePrimitive!(long)(key);
	}
	
	real unarchiveReal (string key)
	{
		return unarchivePrimitive!(real)(key);
	}
	
	short unarchiveShort (string key)
	{
		return unarchivePrimitive!(short)(key);
	}
	
	ubyte unarchiveUbyte (string key)
	{
		return unarchivePrimitive!(ubyte)(key);
	}

	// currently not implemented but a reserved keyword
    /*ucent unarchiveCcent (string key)
	{
		return unarchivePrimitive!(ucent)(key);
	}*/

	uint unarchiveUint (string key)
	{
		return unarchivePrimitive!(uint)(key);
	}
	
	ulong unarchiveUlong (string key)
	{
		return unarchivePrimitive!(ulong)(key);
	}
	
	ushort unarchiveUshort (string key)
	{
		return unarchivePrimitive!(ushort)(key);
	}
	
	wchar unarchiveWchar (string key)
	{
		return unarchivePrimitive!(wchar)(key);
	}
	
	T unarchivePrimitive (T) (string key)
	{
		auto element = getElement(toData(T.stringof), key);

		if (!element.isValid)
			return T.init;
		
		return fromData!(T)(element.value);
	}
	
	void postProcessArray (Id id)
	{
		if (auto array = getArchivedArray(id))
			array.parent.attach(array.node);
	}
	
	void postProcessPointer (Id id)
	{
		if (auto pointer = getArchivedPointer(id))
			pointer.parent.attach(pointer.node);
	}
	
	private void addArchivedArray (Id id, doc.Node parent, doc.Node element, string key)
	{
		archivedArrays[id] = Node(parent, element, id, key);
	}
	
	private Node* getArchivedArray (Id id)
	{
		if (auto array = id in archivedArrays)
			return array;

		if (errorCallback)
			errorCallback(new ArchiveException(`Could not continue archiving due to no array with the Id "` ~ to!(string)(id) ~ `" was found.`, __FILE__, __LINE__), [to!(string)(id)]);
		
		return null;
	}
	
	private void addArchivedPointer (Id id, doc.Node parent, doc.Node element, string key)
	{
		archivedPointers[id] = Node(parent, element, id, key);
	}
	
	private Node* getArchivedPointer (Id id)
	{
		if (auto pointer = id in archivedPointers)
			return pointer;

		if (errorCallback)
			errorCallback(new ArchiveException(`Could not continue archiving due to no pointer with the Id "` ~ to!(string)(id) ~ `" was found.`, __FILE__, __LINE__), [to!(string)(id)]);
		
		return null;
	}
	
	private doc.Node getElement (Data tag, string key, Data attribute = Attributes.keyAttribute, bool throwOnError = true)
	{
		auto set = lastElement.query[tag].attribute((doc.Node node) {
			if (node.name == attribute && node.value == key)
				return true;
			
			return false;
		});

		version (Tango)
		{
			if (set.nodes.length == 1)
				return set.nodes[0].parent;
		}
		
		else
		{	// Temporary fix, this is probably a problem in the Phobos
			// implementation of the XML query function
			if (set.nodes.length > 0)
				return set.nodes[set.nodes.length - 1].parent;
		}

		if (throwOnError && errorCallback)
		{
			if (set.nodes.length == 0)
				errorCallback(new ArchiveException(`Could not find an element "` ~ to!(string)(tag) ~ `" with the attribute "` ~ to!(string)(Attributes.keyAttribute) ~ `" with the value "` ~ to!(string)(key) ~ `".`, __FILE__, __LINE__), [tag, Attributes.keyAttribute, key]);

			else
				errorCallback(new ArchiveException(`Could not unarchive the value with the key "` ~ to!(string)(key) ~ `" due to malformed data.`, __FILE__, __LINE__), [tag, Attributes.keyAttribute, key]);
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
			if (errorCallback)
			{
				if (set.nodes.length == 0)
					errorCallback(new ArchiveException(`Could not find the attribute "` ~ to!(string)(attribute) ~ `".`, __FILE__, __LINE__), [attribute]);
				
				else
					errorCallback(new ArchiveException(`Could not unarchive the value of the attribute "` ~ to!(string)(attribute) ~ `" due to malformed data.`, __FILE__, __LINE__), [attribute]);
			}
		}

		return null;
	}
	
	version (Tango)
	{
		private template errorMessage (ArchiveMode mode = ArchiveMode.archiving)
		{
			static if (mode == ArchiveMode.archiving)
				const errorMessage = "Could not continue archiving due to unrecognized data format: ";
				
			else static if (mode == ArchiveMode.unarchiving)
				const errorMessage = "Could not continue unarchiving due to unrecognized data format: ";
		}
	}
	
	else
	{
		mixin(
			`private template errorMessage (ArchiveMode mode = ArchiveMode.archiving)
			{
				static if (mode == ArchiveMode.archiving)
					enum errorMessage = "Could not continue archiving due to unrecognized data format: ";
					
				else static if (mode == ArchiveMode.unarchiving)
					enum errorMessage = "Could not continue unarchiving due to unrecognized data format: ";
			}`
		);
	}
}