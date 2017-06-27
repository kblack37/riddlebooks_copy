package wordproblem.hints
{
    import starling.display.DisplayObject;
    import starling.display.Sprite;
    import starling.text.TextField;
    
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.text.TextParserUtil;

    public class BasicTextInViewerHint extends HintScript
    {
        private var m_title:String;
        private var m_mainContent:String;
        
        /**
         * In the help viewer screen, these types of hints
         */
        public function BasicTextInViewerHint(title:String, 
                                              mainContent:String, 
                                              unlocked:Boolean, 
                                              id:String=null, 
                                              isActive:Boolean=true)
        {
            super(unlocked, id, isActive);
            
            m_title = title;
            m_mainContent = mainContent;
        }
        
        override public function getDescription(width:Number, height:Number):DisplayObject
        {
            var container:Sprite = new Sprite();
            var titleTextfield:TextField = new TextField(width, 70, m_title, GameFonts.DEFAULT_FONT_NAME, 24);
            titleTextfield.y = -13;
            container.addChild(titleTextfield);
            
            var descriptionTextfield:TextField = new TextField(width, height, m_mainContent, GameFonts.DEFAULT_FONT_NAME, 18);
            container.addChild(descriptionTextfield);
            return container;
        }
        
        override public function canShow():Boolean
        {
            return false;
        }
    }
}