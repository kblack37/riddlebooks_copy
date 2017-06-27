package wordproblem.player
{
    

    /**
     * To implement the feature where the player can change to color of several of the buttons
     * to one of their choosing, several unrelated different scripts and ui pieces will
     * need to read what button color had been selected.
     * 
     * This object is passed to and shared amongst all these disparate pieces
     */
    public class ButtonColorData
    {
        private var m_activeColor:uint;
        
        public function ButtonColorData()
        {
        }
        
        public function setActiveUpColor(value:uint):void
        {
            m_activeColor = value;
        }
        
        public function getUpButtonColor():uint
        {
            return m_activeColor;
        }
    }
}