package wordproblem.player;




/**
 * To implement the feature where the player can change to color of several of the buttons
 * to one of their choosing, several unrelated different scripts and ui pieces will
 * need to read what button color had been selected.
 * 
 * This object is passed to and shared amongst all these disparate pieces
 */
class ButtonColorData
{
    private var m_activeColor : Int;
    
    public function new()
    {
    }
    
    public function setActiveUpColor(value : Int) : Void
    {
        m_activeColor = value;
    }
    
    public function getUpButtonColor() : Int
    {
        return m_activeColor;
    }
}
