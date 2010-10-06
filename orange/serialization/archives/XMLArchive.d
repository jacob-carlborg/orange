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

import orange.serialization.archives._;
import orange.util._;
import orange.xml.XMLDocument;

final class XMLArchive (U = char) : Archive!(U)
{
	private alias IArchive.IDataType IDataType;
	
	private struct Tags
	{
		static const DataType structTag = "struct";	
		static const DataType dataTag = "data";
		static const DataType archiveTag = "archive";
		static const DataType arrayTag = "array";
		static const DataType objectTag = "object";
		static const DataType baseTag = "base";
		static const DataType stringTag = "string";
		static const DataType referenceTag = "reference";
		static const DataType pointerTag = "pointer";
		static const DataType associativeArrayTag = "associativeArray";
		static const DataType typedefTag = "typedef";
		static const DataType nullTag = "null";
		static const DataType enumTag = "enum";
		static const DataType sliceTag = "slice";
	}

	private struct Attributes
	{
		static const DataType typeAttribute = "type";
		static const DataType versionAttribute = "version";
		static const DataType lengthAttribute = "length";
		static const DataType keyAttribute = "key";
		static const DataType runtimeTypeAttribute = "runtimeType";
		static const DataType idAttribute = "id";
		static const DataType keyTypeAttribute = "keyType";
		static const DataType valueTypeAttribute = "valueType";
		static const DataType offsetAttribute = "offset";
	}
	
	private struct ArrayNode
	{
		XMLDocument!(U).Node parent;
		XMLDocument!(U).Node node;
		DataType id;
		DataType key;
	}
	
	private
	{
		DataType archiveType = "org.dsource.orange.xml";
		DataType archiveVersion = "0.1";
		
		XMLDocument!(U) doc;
		doc.Node lastElement;
		
		bool hasBegunArchiving;
		bool hasBegunUnarchiving;
		
		ArrayNode[Array] arraysToBeArchived;
		void[][DataType] unarchivedSlices;
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
	
	public void beginUnarchiving (IDataType untypedData)
	{
		auto data = cast(DataType) untypedData;
		
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
					if (set.nodes.length == 0)
						errorCallback(new ArchiveException(errorMessage!(ArchiveMode.unarchiving) ~ `The "` ~ to!(string)(Tags.dataTag) ~ `" tag could not be found.`, __FILE__, __LINE__), [Tags.dataTag]);
					
					else
						errorCallback(new ArchiveException(errorMessage!(ArchiveMode.unarchiving) ~ `There were more than one "` ~ to!(string)(Tags.dataTag) ~ `" tag.`, __FILE__, __LINE__), [Tags.dataTag]);
				}	
			}
		}
	}
	
	IDataType data ()
	{
		return doc.toString();
	}
	
	void postProcess ()
	{
		bool foundSlice = true;
		
		foreach (slice, sliceNode ; arraysToBeArchived)
		{
			foreach (array, arrayNode ; arraysToBeArchived)
			{
				if (slice.isSliceOf(array) && slice != array)
				{
					sliceNode.parent.element(Tags.sliceTag, arrayNode.id)
					.attribute(Attributes.keyAttribute, sliceNode.key)
					.attribute(Attributes.offsetAttribute, toDataType((slice.ptr - array.ptr) / slice.elementSize))
					.attribute(Attributes.lengthAttribute, toDataType(slice.length));
					
					foundSlice = true;
					break;
				}
				
				else
					foundSlice = false;
			}
			
			if (!foundSlice)
				sliceNode.parent.attach(sliceNode.node);
		}
	}
	
	void reset ()
	{
		hasBegunArchiving = false;
		hasBegunUnarchiving = false;
		doc.reset;
	}
	
	void archiveArray (Array array, string type, string key, size_t id, void delegate () dg)
	{
		internalArchiveArray(type, array, key, id, Tags.arrayTag);
		dg();
	}
	
	private void internalArchiveArray(string type, Array array, string key, size_t id, DataType tag, DataType content = null)
	{
		auto parent = lastElement;
		
		if (array.length == 0)
			lastElement = lastElement.element(tag);
		
		else
			lastElement = doc.createNode(tag, content);			
		
		lastElement.attribute(Attributes.typeAttribute, toDataType(type))
		.attribute(Attributes.lengthAttribute, toDataType(array.length))
		.attribute(Attributes.keyAttribute, toDataType(key))
		.attribute(Attributes.idAttribute, toDataType(id));
	}
	
	void archiveAssociativeArray (string keyType, string valueType, size_t length, string key, size_t id, void delegate () dg)
	{
		lastElement = lastElement.element(Tags.associativeArrayTag)		
		.attribute(Attributes.keyTypeAttribute, toDataType(keyType))
		.attribute(Attributes.valueTypeAttribute, toDataType(valueType))
		.attribute(Attributes.lengthAttribute, toDataType(length))
		.attribute(Attributes.keyAttribute, key);
		
		dg();
	}
	
	void archiveEnum (bool value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (byte value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (char value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (dchar value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (int value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (long value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (short value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (ubyte value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (uint value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (ulong value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (ushort value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	void archiveEnum (wchar value, string key, size_t id)
	{
		internalArchiveEnum(value, key, id);
	}
	
	private void internalArchiveEnum (T) (T value, string key, size_t id)
	{
		lastElement.element(Tags.enumTag, toDataType(value))
		.attribute(Attributes.typeAttribute, toDataType(T.stringof))
		.attribute(Attributes.keyAttribute, toDataType(key));
	}
	
	void archiveBaseClass (string type, string key, size_t id)
	{
		lastElement = lastElement.element(Tags.baseTag)
		.attribute(Attributes.typeAttribute, toDataType(type))
		.attribute(Attributes.keyAttribute, toDataType(key)); 
	}
	
	void archiveNull (string type, string key)
	{
		lastElement.element(Tags.nullTag)
		.attribute(Attributes.typeAttribute, toDataType(type))
		.attribute(Attributes.keyAttribute, toDataType(key));
	}
	
	void archiveObject (string runtimeType, string type, string key, size_t id, void delegate () dg)
	{
		lastElement = lastElement.element(Tags.objectTag)
		.attribute(Attributes.runtimeTypeAttribute, toDataType(runtimeType))
		.attribute(Attributes.typeAttribute, toDataType(type))
		.attribute(Attributes.keyAttribute, toDataType(key))
		.attribute(Attributes.idAttribute, toDataType(id));
		
		dg();
	}
	
	void archivePointer (string key, size_t id)
	{		
		lastElement = lastElement.element(Tags.pointerTag)
		.attribute(Attributes.keyAttribute, toDataType(key))
		.attribute(Attributes.idAttribute, toDataType(id));
	}
	
	void archiveReference (string key, size_t id)
	{
		lastElement.element(Tags.referenceTag, toDataType(id))
		.attribute(Attributes.keyAttribute, toDataType(key));
	}
	
	/*void archiveSlice (Array array, Array slice)
	{
		sliceNode.parent.element(Tags.sliceTag, arrayNode.id)
		.attribute(Attributes.keyAttribute, sliceNode.key)
		.attribute(Attributes.offsetAttribute, toDataType((slice.ptr - array.ptr) / slice.elementSize))
		.attribute(Attributes.lengthAttribute, toDataType(slice.length));
	}*/
	
	void archiveStruct (string type, string key, size_t id, void delegate () dg)
	{
		lastElement = lastElement.element(Tags.structTag)
		.attribute(Attributes.typeAttribute, toDataType(type))
		.attribute(Attributes.keyAttribute, toDataType(key));
		
		dg();
	}
	
	void archiveTypedef (string type, string key, size_t id, void delegate () dg)
	{
		lastElement = lastElement.element(Tags.typedefTag)
		.attribute(Attributes.typeAttribute, toDataType(type))
		.attribute(Attributes.keyAttribute, toDataType(key));
		
		dg();
	}
	
	void archive (string value, string key, size_t id)
	{
		archiveString(value, key, id);
	}
	
	void archive (wstring value, string key, size_t id)
	{
		archiveString(value, key, id);
	}
	
	void archive (dstring value, string key, size_t id)
	{
		archiveString(value, key, id);
	}
	
	private void archiveString (T) (T value, string key, size_t id)
	{
		alias BaseTypeOfArray!(T) ArrayBaseType;
		auto array = Array(value.ptr, value.length, ArrayBaseType.sizeof);
		
		internalArchiveArray(ArrayBaseType.stringof, array, key, id, Tags.stringTag, toDataType(value));
	}
	
	void archive (bool value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	void archive (byte value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	/*void archive (cdouble value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}*/
	
	/*void archive (cent value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}*/
	
	/*void archive (cfloat value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}*/
	
	void archive (char value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	/*void archive (creal value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}*/
	
	void archive (dchar value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	void archive (double value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	void archive (float value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	/*void archive (idouble value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}*/
	
	/*void archive (ifloat value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}*/
	
	void archive (int value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	/*void archive (ireal value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}*/
	
	void archive (long value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	void archive (real value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	void archive (short value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	void archive (ubyte value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	/*void archive (ucent value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}*/
	
	void archive (uint value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	void archive (ulong value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	void archive (ushort value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}
	
	void archive (wchar value, string key, size_t id)
	{
		archivePrimitive(value, key);
	}	
	
	private void archivePrimitive (T) (T value, string key)
	{
		lastElement.element(toDataType(T.stringof), toDataType(value))
		.attribute(Attributes.keyAttribute, toDataType(key));
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