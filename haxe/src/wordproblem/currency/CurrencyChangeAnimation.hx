package wordproblem.currency;

import wordproblem.currency.CurrencyCounter;

import starling.animation.IAnimatable;

/**
 * A simple animation where the value in the currency counter gradually changes from a start to
 * end value.
 */
class CurrencyChangeAnimation implements IAnimatable
{
    private inline var m_defaultRate : Int = 200;
    private inline var m_maxSeconds : Float = 5;
    
    private var m_currencyCounter : CurrencyCounter;
    
    private var m_keepPlaying : Bool;
    private var m_elapsedSeconds : Float;
    private var m_ratePerSecond : Float;
    private var m_start : Int;
    private var m_end : Int;
    
    public function new(currencyCounter : CurrencyCounter)
    {
        m_currencyCounter = currencyCounter;
    }
    
    /**
     * Play animation where the value of the counter changed.
     * By default, we use a fixed rate of change.
     * 
     * However we also enforce a maximum amount of time allowed to transition
     * from the start to the end.
     * 
     * Must call this before adding this to the juggler
     */
    public function start(startValue : Int, endValue : Int) : Void
    {
        var delta : Int = endValue - startValue;
        var maxAllowedTime : Float = 5;
        
        m_ratePerSecond = ((delta > 0)) ? m_defaultRate : m_defaultRate * -1;
        if (Math.abs(delta) / m_defaultRate > m_maxSeconds) 
        {
            m_ratePerSecond = delta / m_maxSeconds;
        }
        
        m_start = startValue;
        m_end = endValue;
        m_elapsedSeconds = 0;
        m_keepPlaying = true;
    }
    
    public function advanceTime(time : Float) : Void
    {
        if (m_keepPlaying) 
        {
            // Based on the number of seconds elapsed we can figure out what the new value
            // of the counter should be
            m_elapsedSeconds += time;
            var newValue : Int = Math.ceil(m_elapsedSeconds * m_ratePerSecond + m_start);
            
            // Clamp new value to the end if necessary
            if (m_ratePerSecond <= 0 && newValue < m_end ||
                m_ratePerSecond >= 0 && newValue > m_end) 
            {
                newValue = m_end;
            }
            
            m_currencyCounter.setValue(newValue);
            if (newValue == m_end) 
            {
                m_keepPlaying = false;
            }
        }
    }
}
