package wordproblem.scripts.level.util;


import dragonbox.common.util.XColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import haxe.xml.Fast;

import openfl.display.DisplayObject;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.model.DocumentNode;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.text.view.ImageView;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;

/**
 * This class handles the replacement + redrawing of the text area widget's content.
 */
class TextReplacementControl
{
    /**
     * The keys of this object are the target document ids,
     * The value is another object whose keys are the 'decision' values and whose values
     * are the actual xml content to replace the document ids with.
     */
    private var m_documentIdToReplaceableContentMap : Dynamic;
    
    private var m_gameEngine : IGameEngine;
    private var m_assetManager : AssetManager;
    private var m_playerStatsAndSaveData : PlayerStatsAndSaveData;
    private var m_textParser : TextParser;
    
    /**
     * Temp buffer to store fetching of document views.
     */
    private var m_outDocumentViewBuffer : Array<DocumentView>;
    
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            textParser : TextParser)
    {
        m_documentIdToReplaceableContentMap = { };
        m_gameEngine = gameEngine;
        m_assetManager = assetManager;
        m_playerStatsAndSaveData = playerStatsAndSaveData;
        m_textParser = textParser;
        m_outDocumentViewBuffer = new Array<DocumentView>();
    }
    
    /**
     * Apply a tint to an existing image in the text area
     */
    public function colorImagesWithDocumentId(documentId : String, color : Int) : Void
    {
		m_outDocumentViewBuffer = new Array<DocumentView>();
        
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        textArea.getDocumentViewsAtPageIndexById(documentId, m_outDocumentViewBuffer);
        
        var i : Int = 0;
        for (i in 0...m_outDocumentViewBuffer.length){
            var documentView : DocumentView = m_outDocumentViewBuffer[i];
            if (Std.is(documentView, ImageView)) 
            {
                (try cast((try cast(documentView, ImageView) catch (e:Dynamic) null).getChildAt(0), Bitmap) catch (e:Dynamic) null).transform.colorTransform.concat(XColor.rgbToColorTransform(color));
            }
        }
    }
    
    /**
     * The tutorials will have several areas in the text with blank spaces filled in later with
     * the player's choices
     */
    public function addUnderlineToBlankSpacePlaceholders(textArea : TextAreaWidget) : Void
    {
        // Find all blank space area that haven't been filled,
        // paste on top an image of an underline with image of an underline
        var blankSpaceAreas : Array<DocumentView> = textArea.getDocumentViewsByClass("blank_space");
        for (blankSpace in blankSpaceAreas)
        {
            // Need to be aware of situation where the content spills over multiple lines as each part on different lines is
            // a separate view. Need to apply the underline to each part that is on a separate line
            
            // Need to figure out that a view spans multiple lines.
            // Get all terminal views in order. We need to generate the bounds of content
            // per each line.
            var terminalViewsInLine : Array<Array<DocumentView>> = new Array<Array<DocumentView>>();
            var terminalViews : Array<DocumentView> = new Array<DocumentView>();
            blankSpace.getDocumentViewLeaves(terminalViews);
            var i : Int = 0;
            var numTerminalViews : Int = terminalViews.length;
            var currentLine : Int = -1;
            for (i in 0...numTerminalViews){
                var terminalView : DocumentView = terminalViews[i];
                var line : Int = terminalView.lineNumber;
                
                // At a new line (numbering doesn't matter we just need to know it is
                // different than the last) add a new list
                if (currentLine != line) 
                {
                    terminalViewsInLine.push(new Array<DocumentView>());
                }  // Always add to last entry in the list  
                
                
                
                terminalViewsInLine[terminalViewsInLine.length - 1].push(terminalView);
            }  // views in that line. These dimensions will allow us to create and position the underline    // Per line, figure out the dimensions of the bound box containing all the terminal  
            
            
            
            
            
            var boundsBuffer : Rectangle = new Rectangle();
            for (i in 0...terminalViewsInLine.length){
                terminalViews = terminalViewsInLine[i];
                var j : Int = 0;
                var boundsForLine : Rectangle = new Rectangle();
                for (j in 0...terminalViews.length){
                    var terminalView = terminalViews[j];
                    
                    // If view is not part of the stage, then add node that is not visible to
                    // the parent so we can temporarily get the bounds
                    var tempAddNonVisibleViews : Bool = false;
                    if (terminalView.stage == null) 
                    {
                        tempAddNonVisibleViews = true;
                        var tracker : DocumentView = terminalView;
                        while (tracker != null && tracker != blankSpace)
                        {
                            if (!tracker.node.getIsVisible()) 
                            {
                                tracker.parentView.addChild(tracker);
                            }
                            
                            tracker = tracker.parentView;
                        }
                    }
                    
                    
                    boundsBuffer = terminalView.getBounds(blankSpace);
                    
                    // Unadd the non visible views
                    if (tempAddNonVisibleViews) 
                    {
                        var tracker = terminalView;
                        while (tracker != null && tracker != blankSpace)
                        {
                            if (!tracker.node.getIsVisible()) 
                            {
                                tracker.parentView.removeChild(tracker);
                            }
                            tracker = tracker.parentView;
                        }
                    }
                    
                    if (boundsForLine.width == 0) 
                    {
                        boundsForLine = boundsBuffer.clone();
                    }
                    else 
                    {
                        boundsForLine.union(boundsBuffer);
                    }
                }
                
                var underlineThickness : Float = boundsForLine.height * 0.1;
                var underlineWidth : Float = boundsForLine.width * 0.9;
				var underline : Bitmap = new Bitmap(new BitmapData(Std.int(underlineWidth), Std.int(underlineThickness), false, 0xFF000000));
                
                underline.x = boundsForLine.left;
                underline.y = boundsForLine.bottom - underlineThickness;
                blankSpace.addChild(underline);
            }
        }
    }
    
    /**
     * A level might have areas of the text that should be replaced
     */
    public function getReplacementXMLContentForDecisionValue(documentId : String, decisionKey : String) : Xml
    {
        // Get back the choice the player made for an option
        var decisionValue : String = try cast(m_playerStatsAndSaveData.getPlayerDecision(decisionKey), String) catch(e:Dynamic) null;
        var contentMap : Dynamic = Reflect.field(m_documentIdToReplaceableContentMap, documentId);
        return Reflect.field(contentMap, decisionValue);
    }
    
    /**
     * Add a brand new option for a particular document id and choice
     */
    public function addDocumentIdContentChoices(documentId : String, choiceId : String, content : Xml) : Void
    {
        if (!m_documentIdToReplaceableContentMap.exists(documentId)) 
        {
            Reflect.setField(m_documentIdToReplaceableContentMap, documentId, { });
        }
        
        var choicesForId : Dynamic = Reflect.field(m_documentIdToReplaceableContentMap, documentId);
        Reflect.setField(choicesForId, choiceId, content);
    }
    
    /**
     * Get back the xml
     */
    public function getContentForDocumentIdAndChoice(documentId : String, choiceId : String) : Xml
    {
        var choicesForId : Dynamic = Reflect.field(m_documentIdToReplaceableContentMap, documentId);
        return Reflect.field(choicesForId, choiceId);
    }
    
    public function drawDisposableTextureAtDocId(textureName : String,
            texureControl : TemporaryTextureControl,
            textArea : TextAreaWidget,
            docId : String,
            pageIndex : Int,
            maxWidth : Float = -1,
            maxHeight : Float = -1) : Void
    {
        // Figure out the texture of the item to use and draw a copy to paste on the page
        var image : DisplayObject = null;
        if (textureName != null) 
        {
            var bitmapData : BitmapData = texureControl.getDisposableTexture(textureName);
            image = new Bitmap(bitmapData);
            
            var scaleFactor : Float = 1.0;
            if (maxWidth > 0) 
            {
                scaleFactor = maxWidth / bitmapData.width;
            }
            else if (maxHeight > 0) 
            {
                scaleFactor = maxHeight / bitmapData.height;
            }
            image.scaleX = image.scaleY = scaleFactor;
            
            addImageAtDocumentId(image, textArea, docId, pageIndex);
        }
        else 
        {
            var containerViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById(docId, null, pageIndex);
            containerViews[0].removeChildren(0, -1);
        }
    }
    
    public function addImageAtDocumentId(image : DisplayObject, textArea : TextAreaWidget, docId : String, pageIndex : Int) : Void
    {
        var containerViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById(docId, null, pageIndex);
        containerViews[0].removeChildren(0, -1);
        containerViews[0].addChild(image);
    }
    
    /**
     * Replace all content at a specific part of the document at a specific page.
     * 
     * Warning this discards all old views belonging to the page
     * 
     * @param pageIndex
     *      If -1, look at the active page in the text area
     */
    public function replaceContentAtDocumentIdsAtPageIndex(documentIdsToReplace : Array<String>,
            contentToReplaceWith : Array<Xml>,
            pageIndex : Int = -1) : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var documentViewsToReplace : Array<DocumentView> = new Array<DocumentView>();
        var i : Int = 0;
        var numDocumentIds : Int = documentIdsToReplace.length;
        for (i in 0...numDocumentIds){
            textArea.getDocumentViewsAtPageIndexById(documentIdsToReplace[i], documentViewsToReplace, pageIndex);
        }  // We are assuming a one-to-one mapping from document id to content to replace  
        
        
        
        if (documentViewsToReplace.length > 0) 
        {
            replaceContentAtGivenViews(textArea, documentViewsToReplace, contentToReplaceWith, pageIndex);
        }
    }
    
    /**
     * Based on some user configured value <v>, parts of the text should be modified.
     * The parts should all be tagged with a class name <c>. The original text of this part
     * should look like a query string key1=value1&key2=value2...
     * <v> should match one of the keys, and the end result is that the tagged part should only
     * have the value matching the selected key.
     */
    public function replaceContentForClassesAtPageIndex(textArea : TextAreaWidget,
            className : String,
            selectedValue : String,
            pageIndex : Int = -1) : Void
    {
        var viewsMatchingClass : Array<DocumentView> = textArea.getDocumentViewsByClass(className, null, pageIndex);
        
        if (viewsMatchingClass.length > 0) 
        {
            var contentToReplaceWith : Array<Xml> = new Array<Xml>();
            var i : Int = 0;
            for (i in 0...viewsMatchingClass.length){
                var view : DocumentView = viewsMatchingClass[i];
                var options : String = view.node.getText();
                
                // Remove leading spaces (this gets injected during parsing in order to space out the words correctly)
                if (options.length > 0 && options.charAt(0) == " ") 
                {
                    options = StringTools.replace(options, " ", "");
                }
                var pairs : Array<Dynamic> = options.split("&");
                var j : Int = 0;
                var replacementContentText : String = "";
                for (j in 0...pairs.length){
                    var keyValuePair : Array<Dynamic> = pairs[j].split("=");
                    if (selectedValue == keyValuePair[0]) 
                    {
                        replacementContentText = keyValuePair[1];
                        break;
                    }
                }
                
                var replacementContent : Xml = Xml.parse("<span></span>");
				replacementContent.addChild(Xml.parse(replacementContentText));
                //replacementContent.node.appendChild.innerData(replacementContentText);
                contentToReplaceWith.push(replacementContent);
            }
            
            replaceContentAtGivenViews(textArea, viewsMatchingClass, contentToReplaceWith, pageIndex);
        }
    }
    
    private function replaceContentAtGivenViews(textArea : TextAreaWidget,
            documentViewsToReplace : Array<DocumentView>,
            contentToReplaceWith : Array<Xml>,
            pageIndex : Int) : Void
    {
        if (pageIndex < 0) 
        {
            pageIndex = textArea.getCurrentPageIndex();
        }
        
        var targetPageRootNode : DocumentNode = textArea.getPageViews()[pageIndex].node;
        var i : Int = 0;
        for (i in 0...documentViewsToReplace.length){
            // Parse new content and then attach the new nodes to the existing document model
            var documentViewToReplace : DocumentView = documentViewsToReplace[i];
            var originalViewToReplaceWidth : Float = documentViewToReplace.width;
            
            var documentNode : DocumentNode = m_textParser.parseDocument(new Fast(contentToReplaceWith[i]), originalViewToReplaceWidth);
			documentViewToReplace.node.children = new Array<DocumentNode>();
            documentViewToReplace.node.children.push(documentNode);
        }  // Re-apply default text stylings  
        
        
        
        m_textParser.applyStyleAndLayout(targetPageRootNode, m_gameEngine.getCurrentLevel().getCssStyleObject());
        
        // Refresh the drawing of the current page
        m_gameEngine.redrawPageViewAtIndex(pageIndex, targetPageRootNode);
        
        // Only redisplay if the page to redraw IS the currently shown page
        if (textArea.getCurrentPageIndex() == pageIndex) 
        {
            textArea.showPageAtIndex(pageIndex);
        }
    }
}
