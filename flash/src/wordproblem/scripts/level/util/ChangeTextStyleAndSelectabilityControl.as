package wordproblem.scripts.level.util
{
    import flash.geom.Point;
    import flash.utils.Dictionary;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.text.TextParser;
    import wordproblem.engine.text.model.DocumentNode;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.widget.TextAreaWidget;

    /**
     * This just stores the function call to get the generic levels to set only
     * the portions of text flagged as a 'term' to be draggable
     * 
     * Also looks at specific levels and see if it is necessary to change various style attributes of the text.
     * 
     * For example: in early levels we want to have the text relating to card have a different style so
     * they are more easily identifiable. This type of highlighting is not desirable for later levels
     * after some checkpoint
     */
    public class ChangeTextStyleAndSelectabilityControl
    {
        private var m_gameEngine:IGameEngine;
        
        private var m_scifiStyle:Object = {".term":{color:"0xA3F981"}};
        private var m_fantasyStyle:Object = {".term":{color:"0x6C0AB1"}};
        private var m_mysteryStyle:Object = {".term":{color:"0x3F62AA"}};
        
        private var m_genreToStyleObject:Dictionary;
        
        /**
         * key: genre name
         * value: point.x = chapter, point.y = level
         */
        private var m_genreToStyleCheckPoint:Dictionary;
        
        public function ChangeTextStyleAndSelectabilityControl(gameEngine:IGameEngine)
        {
            m_gameEngine = gameEngine;
            
            m_genreToStyleObject = new Dictionary();
            m_genreToStyleObject["scifi"] = m_scifiStyle;
            m_genreToStyleObject["fantasy"] = m_fantasyStyle;
            m_genreToStyleObject["mystery"] = m_mysteryStyle;
            
            m_genreToStyleCheckPoint = new Dictionary();
            m_genreToStyleCheckPoint["scifi"] = new Point(1, 0);
            m_genreToStyleCheckPoint["fantasy"] = new Point(1, 0);
            m_genreToStyleCheckPoint["mystery"] = new Point(1, 0);
        }
        
        // TODO: If the text area gets redrawn (which happens for the non-bar model levels at the start to highlight the terms)
        // the changes get clobbered and must be re-applied
        public function setOnlyClassNameAsSelectable(classNameToBeSelectable:String="term"):void
        {
            // The code below is a HACK that assumes all levels using this script do not
            // have one off conditions regarding the selectability of terms
            // For every page, set the paragraphs to not be selectable
            // Then set the portions marked as a term as selectable
            // This should cause only those terms to be draggable
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            var paragraphElements:Vector.<DocumentView> = textArea.getDocumentViewsByElement("p");
            for each (var paragraphElement:DocumentView in paragraphElements)
            {
                paragraphElement.node.setSelectable(false, true);
            }
            
            var terms:Vector.<DocumentView> = textArea.getDocumentViewsByClass(classNameToBeSelectable);
            for each (var selectableTerm:DocumentView in terms)
            {
                selectableTerm.node.setSelectable(true, true);
            }
        }
        
        public function resetStyleForTerm():void
        {
            /*
            Get the text area, have a view factory recreate new views
            Go through all the views and rebind the view to the render components
            */
            var currentLevel:WordProblemLevelData = m_gameEngine.getCurrentLevel();
            var genreId:String = currentLevel.getGenreId();
            var levelIndex:int = currentLevel.getLevelIndex();
            var chapterIndex:int = currentLevel.getChapterIndex();
            var extraStyleToApply:Object = null;
            if (m_genreToStyleCheckPoint.hasOwnProperty(genreId))
            {
                var chapterLevelCheckpoint:Point = m_genreToStyleCheckPoint[genreId] as Point;
                if (chapterIndex < chapterLevelCheckpoint.x || (chapterIndex == chapterLevelCheckpoint.x && levelIndex < chapterLevelCheckpoint.y))
                {
                    extraStyleToApply = m_genreToStyleObject[genreId];
                }
            }
            
            // Append extra style to highlight the spans
            var currentStyleObject:Object = currentLevel.getCssStyleObject();
            
            // Make sure extra styles are ordered so they are applied last, otherwise they
            // might get overridden by the original style
            var currentStyleHasOrder:Boolean = currentStyleObject.hasOwnProperty("ORDER");
            var styleOrder:Array = (currentStyleHasOrder) ? currentStyleObject["ORDER"] : [];
            if (!currentStyleHasOrder)
            {
                for (var key:String in currentStyleObject)
                {
                    styleOrder.push(key);
                }
                
                currentStyleObject["ORDER"] = styleOrder;
            }
            
            for (key in extraStyleToApply)
            {
                currentStyleObject[key] = extraStyleToApply[key];
                styleOrder.push(key);
            }
            
            // Re-apply the styles
            var documentNodes:Vector.<DocumentNode> = currentLevel.getRootDocumentNodes();
            var textParser:TextParser = new TextParser();
            for (var i:int = 0; i < documentNodes.length; i++)
            {
                textParser.applyStyleAndLayout(documentNodes[i], currentStyleObject);
                m_gameEngine.redrawPageViewAtIndex(i, documentNodes[i]);
            }
            
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            textArea.renderText();
            textArea.showPageAtIndex(0);
        }
    }
}