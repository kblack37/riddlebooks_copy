package wordproblem.hints;

import wordproblem.hints.HintScript;

import starling.display.DisplayObject;
import starling.display.Sprite;
import starling.text.TextField;

import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.TextParserUtil;

class BasicTextInViewerHint extends HintScript
{
    private var m_title : String;
    private var m_mainContent : String;
    
    /**
     * In the help viewer screen, these types of hints
     */
    public function new(title : String,
            mainContent : String,
            unlocked : Bool,
            id : String = null,
            isActive : Bool = true)
    {
        super(unlocked, id, isActive);
        
        m_title = title;
        m_mainContent = mainContent;
    }
    
    override public function getDescription(width : Float, height : Float) : DisplayObject
    {
        var container : Sprite = new Sprite();
        var titleTextfield : TextField = new TextField(width, 70, m_title, GameFonts.DEFAULT_FONT_NAME, 24);
        titleTextfield.y = -13;
        container.addChild(titleTextfield);
        
        var descriptionTextfield : TextField = new TextField(width, height, m_mainContent, GameFonts.DEFAULT_FONT_NAME, 18);
        container.addChild(descriptionTextfield);
        return container;
    }
    
    override public function canShow() : Bool
    {
        return false;
    }
}
