package wordproblem.scripts.level.util
{
    import flash.geom.Rectangle;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.textures.Texture;
    
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
    public class TextReplacementControl
    {
        /**
         * The keys of this object are the target document ids,
         * The value is another object whose keys are the 'decision' values and whose values
         * are the actual xml content to replace the document ids with.
         */
        private var m_documentIdToReplaceableContentMap:Object;
        
        private var m_gameEngine:IGameEngine;
        private var m_assetManager:AssetManager;
        private var m_playerStatsAndSaveData:PlayerStatsAndSaveData;
        private var m_textParser:TextParser;
        
        /**
         * Temp buffer to store fetching of document views.
         */
        private var m_outDocumentViewBuffer:Vector.<DocumentView>;
        
        public function TextReplacementControl(gameEngine:IGameEngine,
                                               assetManager:AssetManager,
                                               playerStatsAndSaveData:PlayerStatsAndSaveData, 
                                               textParser:TextParser)
        {
            m_documentIdToReplaceableContentMap = {};
            m_gameEngine = gameEngine;
            m_assetManager = assetManager;
            m_playerStatsAndSaveData = playerStatsAndSaveData;
            m_textParser = textParser;
            m_outDocumentViewBuffer = new Vector.<DocumentView>();
        }
        
        /**
         * Apply a tint to an existing image in the text area
         */
        public function colorImagesWithDocumentId(documentId:String, color:uint):void
        {
            m_outDocumentViewBuffer.length = 0;
            
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            textArea.getDocumentViewsAtPageIndexById(documentId, m_outDocumentViewBuffer);
            
            var i:int;
            for (i = 0; i < m_outDocumentViewBuffer.length; i++)
            {
                var documentView:DocumentView = m_outDocumentViewBuffer[i];
                if (documentView is ImageView)
                {
                    ((documentView as ImageView).getChildAt(0) as Image).color = color;
                }
            }
        }
        
        /**
         * The tutorials will have several areas in the text with blank spaces filled in later with
         * the player's choices
         */
        public function addUnderlineToBlankSpacePlaceholders(textArea:TextAreaWidget):void
        {
            // Find all blank space area that haven't been filled,
            // paste on top an image of an underline with image of an underline
            var blankSpaceAreas:Vector.<DocumentView> = textArea.getDocumentViewsByClass("blank_space");
            for each (var blankSpace:DocumentView in blankSpaceAreas)
            {
                // Need to be aware of situation where the content spills over multiple lines as each part on different lines is
                // a separate view. Need to apply the underline to each part that is on a separate line
                
                // Need to figure out that a view spans multiple lines.
                // Get all terminal views in order. We need to generate the bounds of content
                // per each line.
                var terminalViewsInLine:Vector.<Vector.<DocumentView>> = new Vector.<Vector.<DocumentView>>();
                var terminalViews:Vector.<DocumentView> = new Vector.<DocumentView>();
                blankSpace.getDocumentViewLeaves(terminalViews);
                var i:int;
                var numTerminalViews:int = terminalViews.length;
                var currentLine:int = -1;
                for (i = 0; i < numTerminalViews; i++)
                {
                    var terminalView:DocumentView = terminalViews[i];
                    var line:int = terminalView.lineNumber;
                    
                    // At a new line (numbering doesn't matter we just need to know it is
                    // different than the last) add a new list
                    if (currentLine != line)
                    {
                        terminalViewsInLine.push(new Vector.<DocumentView>());
                    }
                    
                    // Always add to last entry in the list
                    terminalViewsInLine[terminalViewsInLine.length - 1].push(terminalView);
                }
                
                // Per line, figure out the dimensions of the bound box containing all the terminal
                // views in that line. These dimensions will allow us to create and position the underline
                var boundsBuffer:Rectangle = new Rectangle();
                for (i = 0; i < terminalViewsInLine.length; i++)
                {
                    terminalViews = terminalViewsInLine[i];
                    var j:int;
                    var boundsForLine:Rectangle = new Rectangle();
                    for (j = 0; j < terminalViews.length; j++)
                    {
                        terminalView = terminalViews[j];
                        
                        // If view is not part of the stage, then add node that is not visible to
                        // the parent so we can temporarily get the bounds
                        var tempAddNonVisibleViews:Boolean = false;
                        if (terminalView.stage == null)
                        {
                            tempAddNonVisibleViews = true;
                            var tracker:DocumentView = terminalView;
                            while (tracker != null && tracker != blankSpace)
                            {
                                if (!tracker.node.getIsVisible())
                                {
                                    tracker.parentView.addChild(tracker);
                                }
                                
                                tracker = tracker.parentView;
                            }
                        }
                        
                        
                        terminalView.getBounds(blankSpace, boundsBuffer);
                        
                        // Unadd the non visible views
                        if (tempAddNonVisibleViews)
                        {
                            tracker = terminalView;
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
                    
                    var underlineThickness:Number = boundsForLine.height * 0.1;
                    var underlineWidth:Number = boundsForLine.width * 0.9;
                    var underline:Quad = new Quad(underlineWidth, underlineThickness, 0x000000);
                    
                    underline.x = boundsForLine.left;
                    underline.y = boundsForLine.bottom - underlineThickness;
                    blankSpace.addChild(underline);
                }
            }
        }
        
        /**
         * A level might have areas of the text that should be replaced
         */
        public function getReplacementXMLContentForDecisionValue(documentId:String, decisionKey:String):XML
        {
            // Get back the choice the player made for an option
            var decisionValue:String = m_playerStatsAndSaveData.getPlayerDecision(decisionKey) as String;
            var contentMap:Object = m_documentIdToReplaceableContentMap[documentId];
            return contentMap[decisionValue];
        }
        
        /**
         * Add a brand new option for a particular document id and choice
         */
        public function addDocumentIdContentChoices(documentId:String, choiceId:String, content:XML):void
        {
            if (!m_documentIdToReplaceableContentMap.hasOwnProperty(documentId))
            {
                m_documentIdToReplaceableContentMap[documentId] = {};
            }
            
            var choicesForId:Object = m_documentIdToReplaceableContentMap[documentId];
            choicesForId[choiceId] = content;
        }
        
        /**
         * Get back the xml
         */
        public function getContentForDocumentIdAndChoice(documentId:String, choiceId:String):XML
        {
            var choicesForId:Object = m_documentIdToReplaceableContentMap[documentId];
            return choicesForId[choiceId];
        }
        
        public function drawDisposableTextureAtDocId(textureName:String,
                                                     texureControl:TemporaryTextureControl,
                                                     textArea:TextAreaWidget, 
                                                     docId:String, 
                                                     pageIndex:int, 
                                                     maxWidth:Number=-1, 
                                                     maxHeight:Number=-1):void
        {
            // Figure out the texture of the item to use and draw a copy to paste on the page
            var image:DisplayObject = null;
            if (textureName != null)
            {
                var texture:Texture = texureControl.getDisposableTexture(textureName);
                image = new Image(texture);
                
                var scaleFactor:Number = 1.0;
                if (maxWidth > 0)
                {
                    scaleFactor = maxWidth / texture.width;
                }
                else if (maxHeight > 0)
                {
                    scaleFactor = maxHeight / texture.height;
                }
                image.scaleX = image.scaleY = scaleFactor;
                
                addImageAtDocumentId(image, textArea, docId, pageIndex);
            }
            else
            {
                var containerViews:Vector.<DocumentView> = textArea.getDocumentViewsAtPageIndexById(docId, null, pageIndex);
                containerViews[0].removeChildren(0, -1, true);
            }
                
        }
        
        public function addImageAtDocumentId(image:DisplayObject, textArea:TextAreaWidget, docId:String, pageIndex:int):void
        {
            var containerViews:Vector.<DocumentView> = textArea.getDocumentViewsAtPageIndexById(docId, null, pageIndex);
            containerViews[0].removeChildren(0, -1, true);
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
        public function replaceContentAtDocumentIdsAtPageIndex(documentIdsToReplace:Vector.<String>, 
                                                               contentToReplaceWith:Vector.<XML>, 
                                                               pageIndex:int = -1):void
        {
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            var documentViewsToReplace:Vector.<DocumentView> = new Vector.<DocumentView>();
            var i:int;
            var numDocumentIds:int = documentIdsToReplace.length;
            for (i = 0; i < numDocumentIds; i++)
            {
                textArea.getDocumentViewsAtPageIndexById(documentIdsToReplace[i], documentViewsToReplace, pageIndex);   
            }
            
            // We are assuming a one-to-one mapping from document id to content to replace
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
        public function replaceContentForClassesAtPageIndex(textArea:TextAreaWidget, 
                                                            className:String, 
                                                            selectedValue:String, 
                                                            pageIndex:int=-1):void
        {
            var viewsMatchingClass:Vector.<DocumentView> = textArea.getDocumentViewsByClass(className, null, pageIndex);
            
            if (viewsMatchingClass.length > 0)
            {
                var contentToReplaceWith:Vector.<XML> = new Vector.<XML>();
                var i:int;
                for (i = 0; i < viewsMatchingClass.length; i++)
                {
                    var view:DocumentView = viewsMatchingClass[i];
                    var options:String = view.node.getText();
                    
                    // Remove leading spaces (this gets injected during parsing in order to space out the words correctly)
                    if (options.length > 0 && options.charAt(0) == " ")
                    {
                        options = options.replace(" ", "");
                    }
                    var pairs:Array = options.split("&");
                    var j:int;
                    var replacementContentText:String = "";
                    for (j = 0; j < pairs.length; j++)
                    {
                        var keyValuePair:Array = pairs[j].split("=");
                        if (selectedValue == keyValuePair[0])
                        {
                            replacementContentText = keyValuePair[1];
                            break;
                        }
                    }
                    
                    var replacementContent:XML = <span></span>;
                    replacementContent.appendChild(replacementContentText);
                    contentToReplaceWith.push(replacementContent);
                }
                
                replaceContentAtGivenViews(textArea, viewsMatchingClass, contentToReplaceWith, pageIndex);
            }
        }
        
        private function replaceContentAtGivenViews(textArea:TextAreaWidget,
                                                    documentViewsToReplace:Vector.<DocumentView>, 
                                                    contentToReplaceWith:Vector.<XML>, 
                                                    pageIndex:int):void
        {
            if (pageIndex < 0)
            {
                pageIndex = textArea.getCurrentPageIndex();
            }
            
            var targetPageRootNode:DocumentNode = textArea.getPageViews()[pageIndex].node;
            var i:int
            for (i = 0; i < documentViewsToReplace.length; i++)
            {
                // Parse new content and then attach the new nodes to the existing document model
                var documentViewToReplace:DocumentView = documentViewsToReplace[i];
                var originalViewToReplaceWidth:Number = documentViewToReplace.width;
                
                var documentNode:DocumentNode = m_textParser.parseDocument(contentToReplaceWith[i], originalViewToReplaceWidth);
                documentViewToReplace.node.children.length = 0;
                documentViewToReplace.node.children.push(documentNode);
            }
            
            // Re-apply default text stylings
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
}