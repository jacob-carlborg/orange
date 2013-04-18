/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jun 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module orange.xml.XmlDocument;

import std.string;
import std.stdio;

import orange.xml.PhobosXml;

/// This class represents an exception thrown by XmlDocument.
class XMLException : Exception
{
	this (string message, string file = null, size_t line = 0)
	{
		super(message, file, line);
	}
}

/**
 * This class represents an XML DOM document. It provides a common interface to the XML
 * document implementations available in Phobos and Tango.
 */
final class XmlDocument
{
	/// The type of the document implementation.
	alias Document Doc;

	/// The type of the node implementation.
	alias Element InternalNode;

	/// The type of the query node implementation.
	alias Element QueryNode;

	/// The type of the visitor type implementation.
	alias Element[] VisitorType;

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
			return nodes.length > 0;
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
		string name ()
		{
			return node.name;
		}

		/// Returns the value of the node.
		string value ()
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
		Node element (string name, string value = null)
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

		/**
		 * Creates a new attribute and attaches it to the receiver.
		 *
		 * Params:
		 *     name = the name of the attribute
		 *     value = the value of the attribute
		 *
		 * Returns: the newly created attribute
		 */
		Node attribute (string name, string value)
		{
			node.attribute(null, name, value);

			return this;
		}

		/**
		 * Attach an already existing node to the receiver.
		 *
		 * Params:
		 *     node = the node to attach.
		 */
		void attach (Node node)
		{
			if (this.node !is node.node.parent)
			{
				node.node.parent = this.node;
				this.node ~= node.node;
			}
		}
	}

	/// This an XPath query handle used to perform queries on a set of elements.
	struct QueryProxy
	{
		private Node[] nodes_;

		private static QueryProxy opCall (QueryNode node)
		{
			QueryProxy qp;

			qp.nodes_ = [Node(node)];

			return qp;
		}

		private static QueryProxy opCall (Node[] nodes)
		{
			QueryProxy qp;
			qp.nodes_ = nodes;

			return qp;
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

		/**
		 * Return a set containing all attributes of the nodes within this set, which match
		 * the given name.
		 *
		 * Params:
		 *     name = the name of the attribute to filter on
		 *
		 * Returns: a set of elements that passed the filter test
		 */
		QueryProxy attribute (string name = null)
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

		/// Returns an array of all the nodes stored in the receiver.
		Node[] nodes ()
		{
			return nodes_;
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
		QueryProxy opIndex (string name)
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
			auto visitor = nodes_;

			int result;

			foreach (n ; visitor)
				if (dg(n))
					break;

			return result;
		}
	}

	/// Set this to true if there should be strict errro checking.
	bool strictErrorChecking;

	/// The number of spaces used for indentation used when printing the document.
	uint indentation = 4;

	private Doc doc;
	InternalNode currentNode;

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
		doc = new Doc(new Tag("root"));
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
	XmlDocument header (string encoding = null)
	{
		string newEncoding = encoding.length > 0 ? encoding : "UTF-8";
		string header = `<?xml version="1.0" encoding="` ~ newEncoding ~ `"?>`;
		doc.prolog = header;

		return this;
	}

	/// Rests the reciver. Allows to parse new content.
	XmlDocument reset ()
	{
		doc = new Doc(new Tag("root"));

		return this;
	}

	/// Return the root document node, from which all other nodes are descended.
	Node tree ()
	{
		return Node(doc, true, true);
	}

	/**
	 * Parses the given string of XML.
	 *
	 * Params:
	 *     xml = the XML to parse
	 */
	void parse (string xml)
	{
		auto tmp = new Doc(xml);
		doc = new Doc(new Tag("root"));
		doc.elements ~= tmp;
	}

	/// Return an xpath handle to query this document. This starts at the document root.
	QueryProxy query ()
	{
		return QueryProxy(doc);
	}

	/// Pretty prints the document.
	override string toString ()
	{
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
	Node createNode (string name, string value = null)
	{
		return Node(new Element(name, value), false, false);
	}
}
