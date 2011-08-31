/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jun 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.xml.XMLDocument;

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
	
	import orange.xml.PhobosXML;
	
	version = Phobos;
}

import orange.core.io;

/**
 * 
 * Authors: doob
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

/**
 * 
 * Authors: doob
 */
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
 * 
 * Authors: doob
 */
final class XMLDocument (T = char)
{
	version (Tango)
	{
		///
		alias Document!(T) Doc;
		
		///
		alias Doc.Node InternalNode;

		
		///
		alias XmlPath!(T).NodeSet QueryNode;
		
		///
		alias T[] tstring;
		
		///
		alias Doc.Visitor VisitorType;
	}		
		
	else
	{
		alias Document Doc;
		
		///
		alias Element InternalNode;
		
		///
		alias Element QueryNode;
		
		///
		alias string tstring;
		
		///
		alias Element[] VisitorType;
	}
	
	/**
	 * 
	 * Authors: doob
	 */
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
		 * 
		 * Returns:
		 */
		bool exist ()
		{
			version (Tango) return nodes.exist;
			else return nodes.length > 0;
		}
		
		/**
		 * 
		 * Params:
		 *     dg = 
		 * Returns:
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
	
	/**
	 * 
	 * Authors: doob
	 */
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
	     * 
	     * Returns:
	     */
	    public static Node invalid ()
	    {
	    	return Node(null);
	    }

	    ///
		tstring name ()
		{
			return node.name;
		}
		
		///
		tstring value ()
		{
			return node.value;
		}
		
		///
		Node parent ()
		{
			return Node(node.parent);
		}
		
		///
		bool isValid ()
		{
			return node !is null;
		}
		
		///
		VisitorProxy children ()
		{
			return VisitorProxy(node.children);
		}
		
		///
		VisitorProxy attributes ()
		{
			return VisitorProxy(node.attributes);
		}
		
		///
		QueryProxy query ()
		{
			return QueryProxy(node.query);
		}
		
		/**
		 * 
		 * Params:
		 *     name = 
		 *     value = 
		 * Returns:
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
		 * 
		 * Params:
		 *     name = 
		 *     value = 
		 * Returns:
		 */
		Node attribute (tstring name, tstring value)
		{
			node.attribute(null, name, value);
			
			version (Tango) return *this;			
			else return this;
		}
		
		/**
		 * 
		 * Params:
		 *     node =
		 */
		void attach (Node node)
		{
			version (Tango) this.node.move(node.node);
			else this.node ~= node.node;
		}
	}
	
	///
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
		 * 
		 * Params:
		 *     filter = 
		 * Returns:
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
		 * 
		 * Params:
		 *     name = 
		 * Returns:
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

		///
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
		 * 
		 * Params:
		 *     query = 
		 * Returns:
		 */
		QueryProxy opIndex (tstring query)
		{
			version (Tango) return QueryProxy(node[query]);

			else
			{
				Node[] proxies;
				
				foreach (parent ; nodes_)
				{
					if (parent.name == query)
						proxies ~= parent;
					
					foreach (e ; parent.node.elements)
					{
						if (e.tag.name == query)
							proxies ~= Node(e);
					}
				}
				
				return QueryProxy(proxies);
			}
		}
		
		/**
		 * 
		 * Params:
		 *     dg = 
		 * Returns:
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
	
	///
	bool strictErrorChecking;
	
	///
	uint indentation = 4;
	
	private Doc doc;	
	version (Tango) private DocPrinter!(T) printer;
	else InternalNode currentNode;
	
	/**
	 * 
	 * Params:
	 *     strictErrorChecking =
	 */
	this (bool strictErrorChecking = true)
	{
		version (Tango) doc = new Doc;
		else doc = new Doc(new Tag("root"));
		this.strictErrorChecking = strictErrorChecking;
	}
	
	/**
	 * 
	 * Params:
	 *     encoding = 
	 * Returns:
	 */
	XMLDocument header (tstring encoding = null)
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
	
	///
	XMLDocument reset ()
	{
		version (Tango) doc.reset;
		else doc = new Doc(new Tag("root"));
		
		return this;
	}
	
	///
	Node tree ()
	{
		version (Tango) return Node(doc.tree);		
		else return Node(doc, true, true);
	}
	
	/**
	 * 
	 * Params:
	 *     xml =
	 */
	void parse (tstring xml)
	{
		version (Tango) doc.parse(xml);
		else doc = new Doc(xml);
	}
	
	///
	QueryProxy query ()
	{
		version (Tango) return QueryProxy(doc.tree.query);
		else return QueryProxy(doc);
	}
	
	///
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
	 * 
	 * Params:
	 *     name = 
	 *     value = 
	 * Returns:
	 */
	Node createNode (tstring name, tstring value = null)
	{
		version (Tango) return Node(tree.element(name, value).node.detach);
		else return Node(new Element(name, value), false, false);
	}
}