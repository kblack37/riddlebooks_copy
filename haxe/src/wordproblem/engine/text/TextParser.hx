package wordproblem.engine.text;

import flash.errors.Error;
import haxe.xml.Fast;

import dragonbox.common.util.XString;

import wordproblem.engine.text.model.DivNode;
import wordproblem.engine.text.model.DocumentNode;
import wordproblem.engine.text.model.ImageNode;
import wordproblem.engine.text.model.ParagraphNode;
import wordproblem.engine.text.model.SpanNode;
import wordproblem.engine.text.model.TextNode;

/**
 * The text parser creates a DOM-like tree structure formatted xml.
 * It converts the xml tags and css style attributes into nodes.
 */
class TextParser
{
    // IMPORTANT: These are the exact names of the tags available
    public static inline var TAG_PARAGRAPH : String = "p";
    
    /**
     * An important note about pages, they are only specified as a shorthand way for the application to
     * know the user want to break up content into separate screens. The application will simply treat it
     * as a larger div after parsing.
     */
    public static inline var TAG_PAGE : String = "page";
    public static inline var TAG_IMAGE : String = "img";
    public static inline var TAG_DIV : String = "div";
    public static inline var TAG_SPAN : String = "span";
    
    /**
     * List of all possible attributes that be specified to style a part of the text
     */
    private var m_nodeAttributes : Array<String>;
    
    public function new()
    {
        m_nodeAttributes = new Array<String>();
        m_nodeAttributes.push(
                "layout");
        m_nodeAttributes.push(
                "width");
        m_nodeAttributes.push(
                "height");
        m_nodeAttributes.push(
                "x");
        m_nodeAttributes.push(
                "y");
        m_nodeAttributes.push(
                "padding");
        m_nodeAttributes.push(
                "paddingTop");
        m_nodeAttributes.push(
                "paddingBottom");
        m_nodeAttributes.push(
                "paddingLeft");
        m_nodeAttributes.push(
                "paddingRight");
        m_nodeAttributes.push(
                "float");
        m_nodeAttributes.push(
                "backgroundColor");
        m_nodeAttributes.push(
                "backgroundImage");
        m_nodeAttributes.push(
                "background9Slice");
        m_nodeAttributes.push(
                "selectable");
        m_nodeAttributes.push(
                "visible");
        m_nodeAttributes.push(
                "lineHeight");
        m_nodeAttributes.push(
                "fontSize");
        m_nodeAttributes.push(
                "fontName");
        m_nodeAttributes.push(
                "color");
    }
    
    /**
     * Assume that the document is made up of several different pages
     * 
     * 
     * @param content
     *      XML object that has as its root tag the wrapper around all pages of text content
     */
    public function parseDocument(content : Fast,
            maxWidth : Float) : DocumentNode
    {
		var documentNodeRoot : DocumentNode = _parseDocument(content.x);
        
        // Set the initial width of each page if not already specified
        // The default value should be the width of the wrapping container
        if (documentNodeRoot.getShouldInheritProperty("width")) 
        {
            documentNodeRoot.width = maxWidth;
        }
        
        return documentNodeRoot;
    }
    
    /**
     * Applying css like styling information to the level configuration.
     * If a selector does not directly apply to a node, it should inherit any
     * applicable properties from its parent
     * 
     * @param pageRoot
     *      The root node representing the content to style,
     * @param cssObject
     *      JSON formatted string representing styling infomation. Must be valid json.
     *      The formats allowed is {"selectorName":{props},...} or
     *      {"ORDER":["selectorName",...], "selectorName":{props},...}
     *      The second format guarantees ordering of how selectors are applied is consistent
     *      ORDER is a reserved keyword, a selector cannot use it
     */
    public function applyStyleAndLayout(pageRoot : DocumentNode,
            cssObject : Dynamic) : Void
    {
        // Do some post processing of the node structure
        // Children nodes should inherit various properties from their
        // ancestors if they have not been explicitly set in the child.
        var selectorNameList : Array<Dynamic> = [];
        var stylesObject : Dynamic = cssObject;
        if (Reflect.hasField(cssObject, "ORDER")) 
        {
            selectorNameList = Reflect.field(cssObject, "ORDER");
        }
        else 
        {
            // NOTE: This is non-deterministic when it comes to ordering of selectors
            // Use brute force loop through every possible selector and see if it matches the current
            // node being examined.
            for (selectorKey in Reflect.fields(cssObject))
            {
                selectorNameList.push(selectorKey);
            }
        }
		
		// Set up default properties at the root and cascade them at the start to ensure  
		// text can render without any other information being provided
        // Need to now inherit properties that were not explicitly set
        _inheritStylesFromParent(null, pageRoot, { });
        
        // Once all the attributes have been parsed out we need to walk
        // the document tree check if a node matches with a selector and
        // apply styles if it does.
        var outNodeList : Array<DocumentNode> = new Array<DocumentNode>();
        _flattenToList(pageRoot, outNodeList);
        
        // Loop through all selectors and check which ones apply to the set of nodes
        var i : Int = 0;
        var selectorName : String = null;
        for (i in 0...selectorNameList.length){
            selectorName = selectorNameList[i];
            
            var j : Int = 0;
            var node : DocumentNode = null;
            var numNodes : Int = outNodeList.length;
            for (j in 0...numNodes){
                node = outNodeList[j];
                
                // For every node check if it matches one of the selector in the css object
                if (node.getMatchesSelector(selectorName)) 
                {
                    var selectorContents : Dynamic = Reflect.field(cssObject, selectorName);
                    this.checkAndApplyPropertyToNode(node, selectorContents);
                    
                    // Cascade certain properties to the children of this node
                    // for example if a div changes the font color, children text nodes should
                    // take in that new font color
                    _inheritStylesFromParent(null, node, selectorContents);
                }
            }
        }
    }
    
    /**
     * Get a list of images to load into the asset manager.
     * We assume that all embedded resources should have already been dumped into the asset manager.
     * Since they are already compiled into the code and there does not seem to be a way to
     * release them
     */
    public function getImagesToLoad(node : DocumentNode, outImages : Array<String>) : Void
    {
		var imageNotAdded : Bool = true;
        if (Std.is(node, ImageNode)) 
        {
            var imageNode : ImageNode = try cast(node, ImageNode) catch(e:Dynamic) null;
            var imageSource : String = imageNode.src.name;
            
            // Do not add duplicate images
            for (i in 0...outImages.length){
                if (outImages[i] == imageSource) 
                {
                    imageNotAdded = false;
                    break;
                }
            }
            
            if (imageNotAdded && imageNode.src.type == "url") 
            {
                outImages.push(imageSource);
            }
        }
        
        if (node.backgroundImage != null) 
        {
            imageNotAdded = true;
            for (i in 0...outImages.length){
                if (outImages[i] == node.backgroundImage.name) 
                {
                    imageNotAdded = false;
                    break;
                }
            }
            
            if (imageNotAdded && node.backgroundImage.type == "url") 
            {
                outImages.push(node.backgroundImage);
            }
        }
        
        var nodeChildren : Array<DocumentNode> = node.children;
        if (nodeChildren != null) 
        {
            for (i in 0...nodeChildren.length){
                var nodeChild : DocumentNode = nodeChildren[i];
                getImagesToLoad(nodeChild, outImages);
            }
        }
    }
    
    /**
     * We have a set of style properties that should be able to cascade in inheritance
     * i.e. something like fontName gets set at a root node, the fontName immediately gets set to every child node
     *
     * Note this requires the root node to have proper default that cascade at the initial pass
     * 
     * @param propertiesToInherit
     *      Define properties to avoid this problem
     *      DIV has colorA, fontA and Child has colorB and fontB, if DIV later changes to colorC the child should just inherit color and not font
     */
    private function _inheritStylesFromParent(parentNode : DocumentNode,
            node : DocumentNode,
            propertiesToInherit : Dynamic) : Void
    {
        if (parentNode != null) 
        {
            // Font style is inherited for all nodes except text and images
            // (During view creation text nodes already inherit from parent nodes which is why they
            // don't need to carry around duplicate information)
            // Check which style properties were not set and use parent values for
            // each one
            // DO NOT inherit from parent if the property of the node was explicitly already set
            // by a selector earlier in this frame or in the xml.
            if (Reflect.hasField(propertiesToInherit, "fontName")) 
            {
                node.fontName = parentNode.fontName;
            }
            
            if (Reflect.hasField(propertiesToInherit, "fontSize")) 
            {
                node.fontSize = parentNode.fontSize;
            }
            
            if (Reflect.hasField(propertiesToInherit, "color")) 
            {
                node.fontColor = parentNode.fontColor;
            }
			
			// Whether or not a node is selectable should be inherited from it's parent  
            // if it was not explicitly defined in the level data
            if (node.getShouldInheritProperty("selectable")) 
            {
                node.setSelectable(parentNode.getSelectable());
            }
			
			// Dimension data is inherited for all nodes except spans, text, and images  
			// Check which dimension properties were not set and either inherit them
            // or mark a tag indicating how they should be laid out by default.
            var isTextNode : Bool = Std.is(node, TextNode);
            var isSpan : Bool = Std.is(node, SpanNode);
            var isImageNode : Bool = Std.is(node, ImageNode);
            if (!isTextNode && !isSpan && !isImageNode) 
            {
                if (node.getShouldInheritProperty("width")) 
                {
                    node.width = parentNode.width;
                }
            }  
			
			// If the layout for a node is not set, it should inherit from its closest parent div.  
            if (Std.is(node, DivNode)) 
            {
                var divNode : DivNode = try cast(node, DivNode) catch(e:Dynamic) null;
                if (!divNode.layoutDefined) 
                {
                    divNode.setLayout((try cast(parentNode, DivNode) catch(e:Dynamic) null).getLayout());
                }
            }
        }  
		
		// Evaluate each child recursively  
        var nodeChildren : Array<DocumentNode> = node.children;
        if (nodeChildren != null) 
        {
            var i : Int = 0;
            for (i in 0...nodeChildren.length){
                var nodeChild : DocumentNode = nodeChildren[i];
                _inheritStylesFromParent(node, nodeChild, propertiesToInherit);
            }
        }
    }
    
    private function _flattenToList(node : DocumentNode, outNodeList : Array<DocumentNode>) : Void
    {
        if (node != null) 
        {
            outNodeList.push(node);
            
            var nodeChildren : Array<DocumentNode> = node.children;
            if (nodeChildren != null) 
            {
                var numChildren : Int = nodeChildren.length;
                var i : Int = 0;
                for (i in 0...numChildren){
                    var nodeChild : DocumentNode = nodeChildren[i];
                    _flattenToList(nodeChild, outNodeList);
                }
            }
        }
    }
    
    /**
     * Recursively traverse the DOM structure created by the actionscript 3 default parser
     * and create our own structures. The structure we create is the model we will use
     * for our rendering.
     * 
     * @param content
     *      The xml chunk to traverse
     * @return
     *      A custom node representing the data in the xml chunk
     */
    private function _parseDocument(content : Xml) : DocumentNode
    {
        // Create a document node base on the tagname of the content root
        var documentNode : DocumentNode = null;
        var contentTagName : String = content.nodeType == Element ? content.nodeName : null;
        
        if (contentTagName == null) 
        {
            // Strip out new line characters and replace with string
            var textContent : String = StringTools.trim(content.nodeValue);
            documentNode = new TextNode((new EReg('\\r?\\n|\\r', "g")).replace(textContent, " "));
        } else {
        // Pages are div are mostly the same, a page is just a way to explicitly break up
        // content is separate screen but logically they both simply aggregate other tags.
			if (contentTagName == TAG_DIV || contentTagName == TAG_PAGE) 
			{
				documentNode = new DivNode();
			}
			else if (contentTagName == TAG_PARAGRAPH) 
			{
				documentNode = new ParagraphNode();
				
				if (content.exists("lineHeight")) 
				{
					(try cast(documentNode, ParagraphNode) catch(e:Dynamic) null).lineHeight = Std.parseFloat(content.get("lineHeight"));
				}
			}
			else if (contentTagName == TAG_IMAGE) 
			{
				var imageSrc : String = content.get("src");
				documentNode = new ImageNode(imageSrc);
			}
			else if (contentTagName == TAG_SPAN) 
			{
				documentNode = new SpanNode();
			}
			else 
			{
				throw new Error("Unrecognized xml tag name: " + contentTagName);
			}
			
			if (content.exists("id")) 
			{
				documentNode.id = content.get("id");
			}
			
			// Generated sentences have "ref" attributes, which are like ids.
			// But if the top paragraph element has id="question" do not overwrite it.  
			if (content.exists("ref") && documentNode.id != "question") 
			{
				documentNode.id = content.get("ref");
			}
			
			if (content.exists("class")) 
			{
				var classString : String = content.get("class");
				var classArray : Array<String> = classString.split(" ");
				documentNode.classes = classArray;
			}
			
			this.checkAndApplyPropertyToNode(documentNode, content);
			
			// Parse the children tags of the content if they exist
			// They will be the children tags of the root.
			if (contentTagName == TAG_SPAN) {
				documentNode.children.push(new TextNode(content.firstChild().nodeValue));
			} else {
				var childXMLList = content.iterator();
				for (child in childXMLList) {
					// HACK: since each node in the Haxe Xml API has a child that is of type PCData
					// and also empty except for the leading whitespace of the next line, we must
					// make sure we aren't including those as children
					if (child.nodeType == PCData && StringTools.trim(child.nodeValue) == "")
						continue;
					var childDocumentNode : DocumentNode = _parseDocument(child);
					documentNode.children.push(childDocumentNode);
				}
			}
        }
		
        return documentNode;
    }
    
    // Instead of stuffing all info into a single attribute, break it up into multiple attributes
    // For example look at the css background-image property which has optional settings as different attributes
    
    // TODO: Problem is that properties are part of xml and later as json
    // Only works is for xml we apply the @ prefix for everything
    private function checkAndApplyPropertyToNode(node : DocumentNode, properties : Dynamic) : Void
    {
		// the standard reflect notation won't work if the properties are sourced
		// from xml, so we must convert
		var attributesBlob : Dynamic = { };
		if (Std.is(properties, Xml)) {
			var castedProperties : Xml = try cast(properties, Xml) catch (e : Dynamic) null;
			for (attribute in castedProperties.attributes()) {
				Reflect.setField(attributesBlob, attribute, castedProperties.get(attribute));
			}
		} else {
			attributesBlob = properties;
		}
        for (baseAttribute in m_nodeAttributes){
            if (Reflect.hasField(attributesBlob, baseAttribute)) 
            {
                var attributeValue = Reflect.field(attributesBlob, baseAttribute);
                if (baseAttribute == "layout" && Std.is(node, DivNode)) 
                {
                    (try cast(node, DivNode) catch(e:Dynamic) null).setLayout(attributeValue);
                }
                else if (baseAttribute == "width") 
                {
                    node.width = Std.parseFloat(attributeValue);
                }
                else if (baseAttribute == "height") 
                {
                    node.height = Std.parseFloat(attributeValue);
                }
                else if (baseAttribute == "x") 
                {
                    node.x = Std.parseFloat(attributeValue);
                }
                else if (baseAttribute == "y") 
                {
                    node.y = Std.parseFloat(attributeValue);
                }
                else if (baseAttribute == "padding") 
                {
                    node.paddingBottom = Std.parseFloat(attributeValue);
                    node.paddingLeft = Std.parseFloat(attributeValue);
                    node.paddingRight = Std.parseFloat(attributeValue);
                    node.paddingTop = Std.parseFloat(attributeValue);
                }
                else if (baseAttribute == "paddingTop") 
                {
                    node.paddingTop = Std.parseFloat(attributeValue);
                }
                else if (baseAttribute == "paddingBottom") 
                {
                    node.paddingBottom = Std.parseFloat(attributeValue);
                }
                else if (baseAttribute == "paddingLeft") 
                {
                    node.paddingLeft = Std.parseFloat(attributeValue);
                }
                else if (baseAttribute == "paddingRight") 
                {
                    node.paddingRight = Std.parseFloat(attributeValue);
                }
                else if (baseAttribute == "float") 
                {
                    node.float = attributeValue;
                }
                else if (baseAttribute == "backgroundColor") 
                {
                    node.setBackgroundColor(attributeValue);
                }
                else if (baseAttribute == "backgroundImage") 
                {
                    node.backgroundImage = TextParserUtil.parseResourceSourceString(attributeValue)[0];
                }
                else if (baseAttribute == "background9Slice") 
                {
                    var sliceString : String = attributeValue;
                    var sliceValues : Array<Dynamic> = sliceString.split(" ");
                    var paddingValues : Array<Int> = new Array<Int>();
                    
                    var j : Int = 0;
                    for (j in 0...sliceValues.length){
                        paddingValues.push(Std.parseInt(sliceValues[j]));
                    }
                    
                    node.background9Slice = paddingValues;
                }
                else if (baseAttribute == "selectable") 
                {
                    node.setSelectable(XString.stringToBool(attributeValue));
                }
                else if (baseAttribute == "visible") 
                {
                    node.setIsVisible(XString.stringToBool(attributeValue));
                }
                else if (baseAttribute == "lineHeight" && Std.is(node, ParagraphNode)) 
                {
                    (try cast(node, ParagraphNode) catch(e:Dynamic) null).lineHeight = Std.parseFloat(attributeValue);
                }
                else if (baseAttribute == "color") 
                {
                    node.fontColor = Std.parseInt(attributeValue);
                }
                else if (baseAttribute == "fontSize") 
                {
                    node.fontSize = Std.parseInt(attributeValue);
                }
                else if (baseAttribute == "fontName") 
                {
                    node.fontName = attributeValue;
                }
				
                // TODO: (this might be a bit strange)
                // If a node got the value from the xml, then the only way that attribute can be
                // overridden is if a style object selector explicitly matches and modifies it.
                // That attribute should not inherit from the parent by default because it has its own values.
                // Inheritance of attributes should only apply if a value wasn't already set by something
                if (Std.is(properties, Xml)) 
                {
                    node.setShouldInheritProperty(baseAttribute, false);
                }
            }
        }
    }
}
