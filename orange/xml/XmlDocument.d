/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jun 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.xml.XmlDocument;

version (Tango)
{
	import tango.text.xml.DocPrinter;
	import tango.text.xml.Document;
	import tango.io.Stdout;
	
	import orange.core.string;
}

else
{
	import std.string;
	import std.stdio;
	
	import orange.xml.PhobosXml;
	
	version = Phobos;
}

import orange.core.io;

/// Evaluates to $(D_PARAM T) if $(D_PARAM T) is a character type.

/**
 * Evaluates to $(D_PARAM T) if $(D_PARAM T) is a character type. Otherwise this
 * template will not compile.
 */
template Char (T)
{
	version (Tango)
	{
		static if (is(T == char) || is(T == wchar) || is(T == dchar))
			alias T Char;
			
		else
			static assert(false, `The given type "` ~ T.stringof ~ `" is not a vaild character type, valid types are "char", "wchar" and "dchar".`);
	}
	
	else
	{
		static if (is(T == char))
			alias T Char;
			
		else
			static assert(false, `The given type "` ~ T.stringof ~ `" is not a vaild character type, the only valid type is "char".`);
	}
}

/// This class represents an exception thrown by XmlDocument.
class XMLException : Exception
{
	version (Tango) private alias long Line;		
	else private alias size_t Line;
	
	this (string message, string file = null, Line line = 0)
	{
		super(message, file, line);
	}
}

/**
 * This class represents an XML DOM document. It provides a common interface to the XML
 * document implementations available in Phobos and Tango.
 */
final class XmlDocument (T = char)
{
	version (Tango)
	{
		/// The type of the document implementation.
		alias Document!(T) Doc;
		
		/// The type of the node implementation.
		alias Doc.Node InternalNode;

		
		/// The type of the query node implementation.
		alias XmlPath!(T).NodeSet QueryNode;
		
		///
		alias T[] tstring;
		
		/// The type of the visitor type implementation.
		alias Doc.Visitor VisitorType;
	}		
		
	else
	{
		/// The type of the document implementation.
		alias Document Doc;
		
		/// The type of the node implementation.
		alias Element InternalNode;
		
		/// The type of the query node implementation.
		alias Element QueryNode;
		
		///
		alias string tstring;
		
		/// The type of the visitor type implementation.
		alias Element[] VisitorType;
	}
	
	/// foreach support for visiting a set of nodes.
	struct VisitorProxy
	{
		private VisitorType nodes;
		
		private static VisitorProxy opCall (VisitorType nodes)
		{
			VisitorProxy vp;
			vp.nodes = nodes;
			
			return vp;
		}
		
		/**
		 * Returns true if this proxy contains any nodes.
		 * 
		 * Examples:
		 * ---
		 * VisitorProxy proxy;
		 * assert(proxy.exist == false);
		 * ---
		 * 
		 * Returns: true if this proxy contains any nodes.
		 */
		bool exist ()
		{
			version (Tango) return nodes.exist;
			else return nodes.length > 0;
		}
		
		/**
		 * Allows to iterate over the set of nodes.
		 * 
		 * Examples:
		 * ---
		 * VisitorProxy proxy
		 * foreach (node ; proxy) {}
		 * ---
		 */ 
		int opApply (int delegate (ref Node) dg)
		{
			int result;
			
			foreach (n ; nodes)
			{
				auto p = Node(n);
				result = dg(p);
				
				if (result)
					break;
			}
			
			return result;
		}
	}
	
	/// A generic document node
	struct Node
	{
	    private InternalNode node;
	    
	    version (Tango)
	    {
		    private static Node opCall (InternalNode node)
	   		{
		    	Node proxy;
	   			proxy.node = node;

	   			return proxy;
	   		}
	    }
	    
	    else
	    {
	        private bool shouldAddToDoc = true;
	        private bool isRoot = true;
	        
		    private static Node opCall (InternalNode node, bool shouldAddToDoc = false, bool isRoot = false)
	   		{
		    	Node proxy;
	   			proxy.node = node;
   				proxy.shouldAddToDoc = shouldAddToDoc;
   				proxy.isRoot = isRoot;

	   			return proxy;
	   		}
	    }
	    
	    /**
	     * Returns an invalid node.
	     * 
	     * Examples:
	     * ---
	     * auto node = Node.invalid;
	     * assert(node.isValid == false);
	     * ---
	     * 
	     * Returns: an invalid node
	     */
	    public static Node invalid ()
	    {
	    	return Node(null);
	    }

	    /// Returns the name of the node.
		tstring name ()
		{
			return node.name;
		}
		
		/// Returns the value of the node.
		tstring value ()
		{
			return node.value;
		}
		
		/// Returns the parent node.
		Node parent ()
		{
			return Node(node.parent);
		}
		
		/**
		 * Returns true if the receiver is valid.
		 * 
		 * auto node = Node.invalid;
		 * assert(node.isValid == false);
		 * 
		 * Returns: true if the receiver is valid.
		 * 
		 * See_Also: invalid
		 */
		bool isValid ()
		{
			return node !is null;
		}
		
		/// Returns a foreach iterator for node children.
		VisitorProxy children ()
		{
			return VisitorProxy(node.children);
		}
		
		/// Returns a foreach iterator for node attributes.
		VisitorProxy attributes ()
		{
			version (Tango)
				return VisitorProxy(node.attributes);

			else
				return VisitorProxy(cast(VisitorType) node.attributes);
		}
		
		/// Return an XPath handle to query the receiver.
		QueryProxy query ()
		{
			return QueryProxy(node.query);
		}
		
		/**
		 * Creates a new element and attaches it to the receiver.
		 * 
		 * Params:
		 *     name = the name of the element
		 *     value = the value of the element
		 *     
		 * Returns: the newly create element.
		 */
		Node element (tstring name, tstring value = null)
		{
			version (Tango) return Node(node.element(null, name, value));
			
			else
			{
				auto element = new Element(name, value);
				
				if (isRoot)
				{
					node.tag = element.tag;
					node ~= new Text(value);
					
					return Node(node, true, false);
				}					
					
				else
				{
					if (shouldAddToDoc)
					{
						shouldAddToDoc = false;
						node ~= element;
					}
					
					else
						node ~= element;
					
					return Node(element, shouldAddToDoc, false);
				}
			}
		}
		
		/**
		 * Creates a new attribute and attaches it to the receiver.
		 * 
		 * Params:
		 *     name = the name of the attribute
		 *     value = the value of the attribute
		 *     
		 * Returns: the newly created attribute
		 */
		Node attribute (tstring name, tstring value)
		{
			node.attribute(null, name, value);
			
			version (Tango) return *this;			
			else return this;
		}
		
		/**
		 * Attach an already existing node to the receiver.
		 * 
		 * Params:
		 *     node = the node to attach.
		 */
		void attach (Node node)
		{
			version (Tango) this.node.move(node.node);
			else this.node ~= node.node;
		}
	}
	
	/// This an XPath query handle used to perform queries on a set of elements.
	struct QueryProxy
	{
		version (Tango)
		{
			private QueryNode node;
			private bool delegate (Node) currentFilter;
		}
		
		version (Phobos) private Node[] nodes_;

		private static QueryProxy opCall (QueryNode node)
		{
			QueryProxy qp;
			
			version (Tango)	qp.node = node;			
			else qp.nodes_ = [Node(node)];

			return qp;
		}
		
		version (Phobos)
		{
			private static QueryProxy opCall (Node[] nodes)
			{
				QueryProxy qp;
				qp.nodes_ = nodes;
				
				return qp;
			}
		}
		
		version (Tango)
		{
			private bool internalFilter (InternalNode node)
			{
				return currentFilter(Node(node));
			}
		}
		
		/**
		 * Returns a set containing all attribute nodes of the nodes within this set which pass
		 * the given filtering test.
		 * 
		 * Params:
		 *     filter = the filter to be applied on the attributes. Should return true when there
		 *     			is a match for an attribute.
		 *     
		 * Returns: the set of nodes that passed the filter test
		 */
		QueryProxy attribute (bool delegate (Node) filter)
		{
			version (Tango)
			{
				this.currentFilter = filter;
				return QueryProxy(node.attribute(&internalFilter));
			}
			
			else
			{
				Node[] nodes;
				
				foreach (node ; nodes_)
				{
					foreach (attr ; node.attributes.nodes)
					{
						auto n = Node(attr);
						
						if (filter && filter(n))
							nodes ~= n;			
					}
				}
				
				return QueryProxy(nodes);
			}
		}
		
		/**
		 * Return a set containing all attributes of the nodes within this set, which match
		 * the given name.
		 * 
		 * Params:
		 *     name = the name of the attribute to filter on
		 *     
		 * Returns: a set of elements that passed the filter test
		 */
		QueryProxy attribute (tstring name = null)
		{
			version (Tango) return QueryProxy(node.attribute(name));
			
			else
			{
				bool filter (Node node)
				{
					return node.name == name;
				}
				
				bool always (Node node)
				{
					return true;
				}
				
				if (name.length > 0)
					return attribute(&filter);
				
				return attribute(&always);
			}
		}

		/// Returns an array of all the nodes stored in the receiver.
		Node[] nodes ()
		{
			version (Tango)
			{
				auto proxies = new Node[node.nodes.length];
				
				foreach (i, node ; node.nodes)
					proxies[i] = Node(node);
				
				return proxies;
			}
			
			else return nodes_;
		}

		/**
		 * Returns a set containing all child elements of the nodes within this set, which
		 * match the given name.
		 * 
		 * Params:
		 *     name = the name to filter on.
		 *      
		 * Returns: a set of elements that passed the filter test
		 */
		QueryProxy opIndex (tstring name)
		{
			version (Tango) return QueryProxy(node[name]);

			else
			{
				Node[] proxies;
				
				foreach (parent ; nodes_)
				{
					foreach (e ; parent.node.elements)
					{
						if (e.tag.name == name)
							proxies ~= Node(e);
					}
				}
				
				return QueryProxy(proxies);
			}
		}
		
		/**
		 * Iterates over the set of nodes. 
		 * 
		 * Examples:
		 * ---
		 * foreach (node ; nodes) {}
		 * ---
		 */
		int opApply (int delegate (ref Node) dg)
		{
			version (Tango) auto visitor = node;
			else auto visitor = nodes_;
			
			int result;
			
			foreach (n ; visitor)
			{
				version (Tango)
				{
					auto p = Node(n);
					result = dg(p);
				}
				
				else result = dg(n);
				
				if (result)
					break;
			}
			
			return result;
		}
	}
	
	/// Set this to true if there should be strict errro checking.
	bool strictErrorChecking;
	
	/// The number of spaces used for indentation used when printing the document.
	uint indentation = 4;
	
	private Doc doc;	
	version (Tango) private DocPrinter!(T) printer;
	else InternalNode currentNode;
	
	/**
	 * Creates a new instance of this class
	 * 
	 * Examples:
	 * ---
	 * auto doc = new XmlDocument!();
	 * ---
	 * 
	 * Params:
	 *     strictErrorChecking = true if strict errro checking should be enabled
	 */
	this (bool strictErrorChecking = true)
	{
		version (Tango) doc = new Doc;
		else doc = new Doc(new Tag("root"));
		this.strictErrorChecking = strictErrorChecking;
	}
	
	/**
	 * Attaches a header to the document.
	 * 
	 * Examples:
	 * ---
	 * auto doc = new XmlDocument!();
	 * doc.header("UTF-8");
	 * // <?xml version="1.0" encoding="UTF-8"?>
	 * ---
	 * 
	 * Params:
	 *     encoding = the encoding that should be put in the header
	 *      
	 * Returns: the receiver
	 */
	XmlDocument header (tstring encoding = null)
	{
		version (Tango) doc.header(encoding);
		
		else
		{			
			tstring newEncoding = encoding.length > 0 ? encoding : "UTF-8";
			tstring header = `<?xml version="1.0" encoding="` ~ newEncoding ~ `"?>`;
			doc.prolog = header;
		}
		
		return this;
	}
	
	/// Rests the reciver. Allows to parse new content.
	XmlDocument reset ()
	{
		version (Tango) doc.reset;
		else doc = new Doc(new Tag("root"));
		
		return this;
	}
	
	/// Return the root document node, from which all other nodes are descended.
	Node tree ()
	{
		version (Tango) return Node(doc.tree);		
		else return Node(doc, true, true);
	}
	
	/**
	 * Parses the given string of XML.
	 * 
	 * Params:
	 *     xml = the XML to parse
	 */
	void parse (tstring xml)
	{
		version (Tango) doc.parse(xml);

		else
		{
			auto tmp = new Doc(xml);
			doc = new Doc(new Tag("root"));
			doc.elements ~= tmp;
		}
	}
	
	/// Return an xpath handle to query this document. This starts at the document root.
	QueryProxy query ()
	{
		version (Tango) return QueryProxy(doc.tree.query);
		else return QueryProxy(doc);
	}
	
	/// Pretty prints the document.
	string toString ()
	{
		version (Tango)
		{
			if (!printer)
				printer = new DocPrinter!(T);

			printer.indent = indentation;
			return printer.print(doc);
		}
		
		else
			return doc.prolog ~ "\n" ~ join(doc.pretty(indentation), "\n");
	}
	
	/**
	 * Attaches a new node to the docuement.
	 * 
	 * Params:
	 *     name = the name of the node
	 *     value = the vale of the node
	 *     
	 * Returns: returns the newly created node
	 */
	Node createNode (tstring name, tstring value = null)
	{
		version (Tango) return Node(tree.element(name, value).node.detach);
		else return Node(new Element(name, value), false, false);
	}
}