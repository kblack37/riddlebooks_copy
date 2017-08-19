package wordproblem.hints;

import openfl.text.TextFormat;
import wordproblem.hints.HintScript;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.text.TextField;

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
        var titleTextfield : TextField = new TextField();
		titleTextfield.width = width;
		titleTextfield.height = 70;
		titleTextfield.text = m_title;
		titleTextfield.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24));
        titleTextfield.y = -13;
        container.addChild(titleTextfield);
        
        var descriptionTextfield : TextField = new TextField();
		descriptionTextfield.width = width;
		descriptionTextfield.height = height;
		descriptionTextfield.text = m_mainContent;
		descriptionTextfield.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18));
        container.addChild(descriptionTextfield);
        return container;
    }
    
    override public function canShow() : Bool
    {
        return false;
    }
}
