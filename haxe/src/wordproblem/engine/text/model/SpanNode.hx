package wordproblem.engine.text.model;


import wordproblem.engine.text.TextParser;

class SpanNode extends DocumentNode
{
    public function new()
    {
        super(TextParser.TAG_SPAN);
    }
    
    /** Return the problem text in this document
     *   
     */
    override public function getText() : String
    {
        var txt : String = " ";
        
        for (i in 0...children.length){
            txt += children[i].getText();
        }
        return txt + " ";
    }
}
