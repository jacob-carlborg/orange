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

private enum ArchiveMode
{
	archiving,
	unarchiving
}

class XMLArchive (U = char) : Archive!(U)
{
	static assert (isChar!(U), format!(`The given type "`, U, `" is not a valid type. Valid types are: "char", "wchar" and "dchar".`));
		
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
	
	private
	{
		struct ArrayNode
		{
			XMLDocument!(U).Node parent;
			XMLDocument!(U).Node node;
			DataType id;
			DataType key;
		}
		
		struct Array
		{
			void* ptr;
			size_t length;
			size_t elementSize;
			
			static Array opCall (T) (T[] value)
			{
				Array array;
				array.ptr = value.ptr;
				array.length = value.length;
				array.elementSize = T.sizeof;
				
				return array;
			}
			
			bool isSliceOf (Array b)
			{
				return ptr >= b.ptr && ptr + length * elementSize <= b.ptr + b.length * b.elementSize;
			}
		}
		
		struct Slice
		{
			size_t length;
			size_t offset;
			DataType id;
		}
		
		DataType archiveType = "org.dsource.orange.xml";
		DataType archiveVersion = "0.1";
		
		XMLDocument!(U) doc;
		doc.Node lastElement;
		//DocPrinter!(U) printer;
		doc.Node lastElementSaved;
		
		bool hasBegunArchiving;
		bool hasBegunUnarchiving;
		
		DataType[void*] archivedReferences;
		void*[DataType] unarchivedReferences;
		
		ArrayNode[Array] arraysToBeArchived;
		void[][DataType] unarchivedSlices;
		
		size_t idCounter;
	}
	
	this ()
	{
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
	
	public void beginUnarchiving (DataType data)
	{
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
	
	public DataType data ()
	{
		/*if (!printer)
			printer = new DocPrinter!(U);
		
		return printer.print(doc);*/
		
		return doc.toString();
	}
	
	public void reset ()
	{
		hasBegunArchiving = false;
		hasBegunUnarchiving = false;
		idCounter = 0;
		doc.reset;
	}
	
	private void begin ()
	{
		lastElementSaved = lastElement;
	}
	
	private void end ()
	{
		lastElement = lastElementSaved;
	}
	
	public void archive (T) (T value, DataType key, void delegate () dg = null)
	{
		if (!hasBegunArchiving)
			beginArchiving();
		
		restore(lastElement) in {
			bool callDelegate = true;
			
			static if (isTypeDef!(T))
				archiveTypeDef(value, key);
			
			else static if (isObject!(T))
				archiveObject(value, key, callDelegate);
			
			else static if (isStruct!(T))
				archiveStruct(value, key);
			 
			else static if (isString!(T))
				archiveString(value, key);
			
			else static if (isArray!(T))
				archiveArray(value, key);
			
			else static if (isAssociativeArray!(T))
				archiveAssociativeArray(value, key);
			
			else static if (isPrimitive!(T))
				archivePrimitive(value, key);
			
			else static if (isPointer!(T))
				archivePointer(value, key, callDelegate);
			
			else static if (isEnum!(T))
				archiveEnum(value, key);
			
			else
				static assert(false, format!(`The type "`, T, `" cannot be archived.`));
			
			if (callDelegate && dg)
				dg();
		};
	}
	
	private void archiveObject (T) (T value, DataType key, ref bool callDelegate)
	{		
		if (!value)
		{
			lastElement.element(Tags.nullTag)
			.attribute(Attributes.typeAttribute, toDataType(T.stringof))
			.attribute(Attributes.keyAttribute, key);
			callDelegate = false;
		}
		
		else if (auto reference = getArchivedReference(value))
		{
			archiveReference(key, reference);
			callDelegate = false;
		}
		
		else
		{
			DataType id = nextId;
			
			lastElement = lastElement.element(Tags.objectTag)
			.attribute(Attributes.runtimeTypeAttribute, toDataType(value.classinfo.name))
			.attribute(Attributes.typeAttribute, toDataType(T.stringof))
			.attribute(Attributes.keyAttribute, key)
			.attribute(Attributes.idAttribute, id);
			
			addArchivedReference(value, id);
		}
	}

	private void archiveStruct (T) (T value, DataType key)
	{
		lastElement = lastElement.element(Tags.structTag)
		.attribute(Attributes.typeAttribute, toDataType(T.stringof))
		.attribute(Attributes.keyAttribute, key);
	}
	
	private void archiveString (T) (T value, DataType key)
	{		
		archiveArrayImpl(value, key, Tags.stringTag, toDataType(value));
	}

	private void archiveArray (T) (T value, DataType key)
	{
		archiveArrayImpl(value, key, Tags.arrayTag);
	}
	
	private void archiveArrayImpl (T) (T value, DataType key, DataType tag, DataType content = null)
	{
		DataType id = nextId;
		auto parent = lastElement;
		
		if (value.length == 0)
			lastElement = lastElement.element(tag);
		
		else
			lastElement = doc.createNode(tag, content);			
		
		lastElement.attribute(Attributes.typeAttribute, toDataType(BaseTypeOfArray!(T).stringof))
		.attribute(Attributes.lengthAttribute, toDataType(value.length))
		.attribute(Attributes.keyAttribute, key)
		.attribute(Attributes.idAttribute, id);

		arraysToBeArchived[Array(value)] = ArrayNode(parent, lastElement, id, key);
	}

	private void archiveAssociativeArray (T) (T value, DataType key)
	{
		lastElement = lastElement.element(Tags.associativeArrayTag)		
		.attribute(Attributes.keyTypeAttribute, toDataType(KeyTypeOfAssociativeArray!(T).stringof))
		.attribute(Attributes.valueTypeAttribute, toDataType(ValueTypeOfAssociativeArray!(T).stringof))
		.attribute(Attributes.lengthAttribute, toDataType(value.length))
		.attribute(Attributes.keyAttribute, key);
	}

	private void archivePointer (T) (T value, DataType key, ref bool callDelegate)
	{
		if (auto reference = getArchivedReference(value))
		{
			archiveReference(key, reference);
			callDelegate = false;
		}
		
		else
		{
			DataType id = nextId;
			
			lastElement = lastElement.element(Tags.pointerTag)
			.attribute(Attributes.keyAttribute, key)
			.attribute(Attributes.idAttribute, id);
			
			addArchivedReference(value, id);
		}
	}
	
	private void archiveEnum (T) (T value, DataType key)
	{
		lastElement.element(Tags.enumTag, toDataType(value))
		.attribute(Attributes.typeAttribute, toDataType(T.stringof))
		.attribute(Attributes.keyAttribute, key);
	}

	private void archivePrimitive (T) (T value, DataType key)
	{
		lastElement.element(toDataType(T.stringof), toDataType(value))
		.attribute(Attributes.keyAttribute, key);
	}
	
	private void archiveTypeDef (T) (T value, DataType key)
	{
		lastElement = lastElement.element(Tags.typedefTag)
		.attribute(Attributes.typeAttribute, toDataType(BaseTypeOfTypeDef!(T).stringof));
		.attribute(Attributes.key, key);
	}
	
	public T unarchive (T) (DataType key, T delegate (T) dg = null)
	{
		if (!hasBegunUnarchiving)
			beginUnarchiving(data);
		
		return restore!(T)(lastElement) in {
			T value;
			
			bool callDelegate = true;
			
			static if (isTypeDef!(T))
				value = unarchiveTypeDef!(T)(key);
			
			else static if (isObject!(T))
				value = unarchiveObject!(T)(key, callDelegate);				

			else static if (isStruct!(T))
				value = unarchiveStruct!(T)(key);
			
			else static if (isString!(T))
				value = unarchiveString!(T)(key);
			 
			else static if (isArray!(T))
				value = unarchiveArray!(T)(key, callDelegate);

			else static if (isAssociativeArray!(T))
				value = unarchiveAssociativeArray!(T)(key);

			else static if (isPrimitive!(T))
				value = unarchivePrimitive!(T)(key);

			else static if (isPointer!(T))
				value = unarchivePointer!(T)(key, callDelegate);
			
			else static if (isEnum!(T))
				value = unarchiveEnum!(T)(key);
			
			else
				static assert(false, format!(`The type "`, T, `" cannot be unarchived.`));

			if (callDelegate && dg)
				return dg(value);
			
			return value;
		};
	}

	private T unarchiveObject (T) (DataType key, ref bool callDelegate)
	{			
		DataType id = unarchiveReference(key);
		
		if (auto reference = getUnarchivedReference!(T)(id))
		{
			callDelegate = false;
			return *reference;
		}
		
		auto tmp = getElement(Tags.objectTag, key, Attributes.keyAttribute, false);

		if (!tmp.isValid)
		{
			lastElement = getElement(Tags.nullTag, key);
			callDelegate = false;
			return null;
		}
	
		lastElement = tmp;
		
		auto runtimeType = getValueOfAttribute(Attributes.runtimeTypeAttribute);
		auto name = fromDataType!(string)(runtimeType);
		id = getValueOfAttribute(Attributes.idAttribute);				
		T result = cast(T) newInstance(name);
		
		addUnarchivedReference(result, id);
		
		return result;
	}

	private T unarchiveStruct (T) (DataType key)
	{
		auto element = getElement(Tags.structTag, key);
		
		if (element.isValid)
			lastElement = element;
		
		return T.init;
	}
	
	private T unarchiveString (T) (DataType key)
	{
		auto slice = unarchiveSlice(key);
		
		if (auto tmp = getUnarchivedSlice!(T)(slice))
			return *tmp;
		
		auto element = getElement(Tags.stringTag, key);
		
		if (!element.isValid)
			return T.init;			
			
		auto value = fromDataType!(T)(element.value);
		slice.id = getValueOfAttribute(Attributes.idAttribute, element);
		
		addUnarchivedSlice(value, slice.id);
		
		return value;
	}

	private T unarchiveArray (T) (DataType key, ref bool callDelegate)
	{		
		auto slice = unarchiveSlice(key);

		if (auto tmp = getUnarchivedSlice!(T)(slice))
		{
			callDelegate = false;
			return *tmp;
		}
		
		T value;
		
		auto element = getElement(Tags.arrayTag, key);
		
		if (!element.isValid)
			return T.init;
		
		lastElement = element;
		auto length = getValueOfAttribute(Attributes.lengthAttribute);		
		value.length = fromDataType!(size_t)(length);
		slice.id = getValueOfAttribute(Attributes.idAttribute);	
		
		addUnarchivedSlice(value, slice.id);
		
		return value;
	}

	private T unarchiveAssociativeArray (T) (DataType key)
	{		
		auto element = getElement(Tags.associativeArrayTag, key);
		
		if (element.isValid)		
			lastElement = element;
		
		return T.init;
	}

	private T unarchivePointer (T) (DataType key, ref bool callDelegate)
	{
		DataType id = unarchiveReference(key);
		
		if (auto reference = getUnarchivedReference!(T)(id))
		{
			callDelegate = false;
			return *reference;
		}
		
		auto element = getElement(Tags.pointerTag, key);
		
		if (!element.isValid)
			return T.init;

		lastElement = element; 
		id = getValueOfAttribute(Attributes.idAttribute);
				
		T result = new BaseTypeOfPointer!(T);
		
		addUnarchivedReference(result, id);
		
		return result;
	}
	
	private T unarchiveEnum (T) (DataType key)
	{
		auto element = getElement(Tags.enumTag, key);
		
		if (!element.isValid)
			return T.init;
		
		return fromDataType!(T)(element.value);
	}

	private T unarchivePrimitive (T) (DataType key)
	{		
		auto element = getElement(toDataType(T.stringof), key);
		
		if (!element.isValid)
			return T.init;
		
		return fromDataType!(T)(element.value);
	}
	
	private T unarchiveTypeDef (T) (DataType key)
	{
		auto element = getElement(Tags.typedefTag, key);
		
		if (element.isValid)
			lastElement = element;
		
		return T.init;
	}
	
	public AssociativeArrayVisitor!(KeyTypeOfAssociativeArray!(T), ValueTypeOfAssociativeArray!(T)) unarchiveAssociativeArrayVisitor (T)  ()
	{
		return AssociativeArrayVisitor!(KeyTypeOfAssociativeArray!(T), ValueTypeOfAssociativeArray!(T))(this);
	}
	
	public void archiveBaseClass (T : Object) (DataType key)
	{
		lastElement = lastElement.element(Tags.baseTag)
		.attribute(Attributes.typeAttribute, toDataType(T.stringof))
		.attribute(Attributes.keyAttribute, key);
	}
	
	public void unarchiveBaseClass (T : Object) (DataType key)
	{
		auto element = getElement(Tags.baseTag, key);
		
		if (element.isValid)
			lastElement = element;
	}
	
	version (Tango)
	{
		template errorMessage (ArchiveMode mode = ArchiveMode.archiving)
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
			`template errorMessage (ArchiveMode mode = ArchiveMode.archiving)
			{
				static if (mode == ArchiveMode.archiving)
					enum errorMessage = "Could not continue archiving due to unrecognized data format: ";
					
				else static if (mode == ArchiveMode.unarchiving)
					enum errorMessage = "Could not continue unarchiving due to unrecognized data format: ";
			}`
		);
	}
	
	private doc.Node getElement (DataType tag, DataType key, DataType attribute = Attributes.keyAttribute, bool throwOnError = true)
	{		
		auto set = lastElement.query[tag].attribute((doc.Node node) {
			if (node.name == attribute && node.value == key)
				return true;
			
			return false;
		});
		
		if (set.nodes.length == 1)
			return set.nodes[0].parent;
		
		else
		{
			if (throwOnError && errorCallback)
			{
				if (set.nodes.length == 0)					
					errorCallback(new ArchiveException(`Could not find an element "` ~ to!(string)(tag) ~ `" with the attribute "` ~ to!(string)(Attributes.keyAttribute) ~ `" with the value "` ~ to!(string)(key) ~ `".`, __FILE__, __LINE__), [tag, Attributes.keyAttribute, key]);
				
				else
					errorCallback(new ArchiveException(`Could not unarchive the value with the key "` ~ to!(string)(key) ~ `" due to malformed data.`, __FILE__, __LINE__), [tag, Attributes.keyAttribute, key]);
			}

			return doc.Node.invalid;
		}		
	}
	
	private DataType getValueOfAttribute (DataType attribute, doc.Node element = doc.Node.invalid)
	{
		if (!element.isValid) element = lastElement;
		
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
	}
	
	private void addArchivedReference (T) (T value, DataType id)
	{
		static assert(isReference!(T), format!(`The given type "`, T, `" is not a reference type, i.e. object or pointer.`));
		
		archivedReferences[cast(void*) value] = id;
	}
	
	private void addUnarchivedReference (T) (T value, DataType id)
	{
		static assert(isReference!(T), format!(`The given type "`, T, `" is not a reference type, i.e. object or pointer.`));
		
		unarchivedReferences[id] = cast(void*) value;
	}
	
	private void addUnarchivedSlice (T) (T value, DataType id)
	{
		static assert(isArray!(T) || isString!(T), format!(`The given type "`, T, `" is not a slice type, i.e. array or string.`));

		unarchivedSlices[id] = value;
	}
	
	private DataType getArchivedReference (T) (T value)
	{
		if (auto tmp = cast(void*) value in archivedReferences)
			return *tmp;
		
		return null;
	}
	
	private T* getUnarchivedReference (T) (DataType id)
	{
		if (auto reference = id in unarchivedReferences)
			return cast(T*) reference;
		
		return null;
	}
	
	private T* getUnarchivedSlice (T) (Slice slice)
	{
		if (auto array = slice.id in unarchivedSlices)	
			return &(cast(T) *array)[slice.offset .. slice.length + 1]; // dereference the array, cast it to the right type, 
																		// slice it and then return a pointer to the result		
		return null;
	}
	
	private DataType nextId ()
	{
		return toDataType(idCounter++);
	}
	
	private void archiveReference (DataType key, DataType id)
	{		
		lastElement.element(Tags.referenceTag, id)
		.attribute(Attributes.keyAttribute, key);
	}
	
	private DataType unarchiveReference (DataType key)
	{	
		auto element = getElement(Tags.referenceTag, key, Attributes.keyAttribute, false);
		
		if (element.isValid)
			return element.value;
		
		return cast(DataType) null;
	}
	
	private Slice unarchiveSlice (DataType key)
	{
		auto element = getElement(Tags.sliceTag, key, Attributes.keyAttribute, false);
		
		if (element.isValid)
		{
			auto length = fromDataType!(size_t)(getValueOfAttribute(Attributes.lengthAttribute, element));
			auto offset = fromDataType!(size_t)(getValueOfAttribute(Attributes.offsetAttribute, element));
			
			return Slice(length, offset, element.value);
		}
		
		return Slice.init;
	}	
	
	private struct AssociativeArrayVisitor (Key, Value)
	{
		private XMLArchive archive;
		
		static AssociativeArrayVisitor opCall (XMLArchive archive)
		{
			AssociativeArrayVisitor aai;
			aai.archive = archive;
			
			return aai;
		}
		
		int opApply(int delegate(ref Key, ref Value) dg)
		{  
			int result;
			
			foreach (node ; archive.lastElement.children)
			{
				restore(archive.lastElement) in {
					archive.lastElement = node;
					
					if (node.attributes.exist)
					{
						Key key = to!(Key)(archive.getValueOfAttribute(Attributes.keyAttribute));
						Value value = to!(Value)(node.value);
						
						result = dg(key, value);	
					}		
				};
				
				if (result)
					break;
			}
			
			return result;
		}
	}
	
	public void postProcess ()
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
}