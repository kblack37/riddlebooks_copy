package wordproblem.engine.text.view;


import flash.text.TextFormat;

import wordproblem.engine.text.model.DocumentNode;

/**
 * Dummy place holder for the text, it exists only because drawing and positioning text content requires
 * multiple passes and we need to maintain a cheap reference to the text content and style information
 * that is packaged in DocumentView subclass. Cannot use a TextView because if the text content is very
 * long, a Starling textfield will require too much texture space.
 */
class DummyTextView extends DocumentView
{
    private var m_textFormat : TextFormat;
    
    public function new(node : DocumentNode, textFormat : TextFormat)
    {
        super(node);
        
        m_textFormat = textFormat;
    }
    
    public function getTextFormat() : TextFormat
    {
        return m_textFormat;
    }
}
