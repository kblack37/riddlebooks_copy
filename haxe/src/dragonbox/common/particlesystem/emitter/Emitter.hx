package dragonbox.common.particlesystem.emitter;




import dragonbox.common.dispose.IDisposable;
import dragonbox.common.particlesystem.Particle;
import dragonbox.common.particlesystem.action.Action;
import dragonbox.common.particlesystem.activities.Activity;
import dragonbox.common.particlesystem.clock.Clock;
import dragonbox.common.particlesystem.initializer.Initializer;

/**
 * The emitter class forms the model for some groups of particles. It manages all the particles
 * and over time applies changes to those particles. Initializers set starting particle values, actions
 * modify the values over a small timestep, activities modify emitter properties over a timestep, and
 * a clock determines when new particles are spawned.
 * 
 * NOTE: 
 * In order for an emitter to render at all, a TextureInitializer needs to be
 * added.
 * 
 * Once disposed it is no longer usable. However, you can reset the emitter and add new actions/initializers
 * to change its behavior.
 */
class Emitter implements IDisposable
{
    public var x(get, set) : Float;
    public var y(get, set) : Float;

    /**
     * Keep track of all possible particles (including dead ones
     * that will get recycled)
     */
    private var m_particles : Array<Particle>;
    
    /**
     * The index within the particle list that indicates the start
     * of particles that are dead and should no longer be processed
     */
    private var m_deadParticleIndex : Int;
    
    /**
     * Group of initial values to set particles with
     */
    private var m_initializers : Array<Initializer>;
    
    /**
     * Group of modifiers to apply to particles with
     */
    private var m_actions : Array<Action>;
    
    /**
     * Group of modifiers to apply to the emitter
     */
    private var m_activities : Array<Activity>;
    
    /**
     * The clock for the emitter determines how many new particles are emitted
     * at a given frame.
     */
    private var m_clock : Clock;
    
    private var m_x : Float;
    private var m_y : Float;
    
    public function new()
    {
        m_particles = new Array<Particle>();
        m_initializers = new Array<Initializer>();
        m_actions = new Array<Action>();
        m_activities = new Array<Activity>();
        
        m_x = 0.0;
        m_y = 0.0;
    }
    
    public function start() : Void
    {
        var particlesToCreate : Int = m_clock.start(this);
        var i : Int;
        for (i in 0...particlesToCreate){
            createParticle();
        }  // Initialize all activities  
        
        
        
        var numActivities : Int = m_activities.length;
        for (i in 0...numActivities){
            m_activities[i].initialize(this);
        }
    }
    
    public function reset() : Void
    {
        m_deadParticleIndex = 0;
    }
    
    public function dispose() : Void
    {
    }
    
    public function getParticles() : Array<Particle>
    {
        return m_particles;
    }
    
    /**
     * Get the maximum index of live particles that should be rendered
     */
    public function getParticleLimit() : Int
    {
        return m_deadParticleIndex;
    }
    
    public function addAction(action : Action) : Void
    {
        m_actions.push(action);
    }
    
    public function removeActions() : Void
    {
		m_actions = new Array<Action>();
    }
    
    public function addInitializer(initializer : Initializer) : Void
    {
        m_initializers.push(initializer);
    }
    
    public function removeAllInitializers() : Void
    {
        m_initializers = new Array<Initializer>();
    }
    
    public function addActivity(activity : Activity) : Void
    {
        m_activities.push(activity);
    }
    
    public function removeAllActivities() : Void
    {
        m_activities = new Array<Activity>();
    }
    
    private function get_x() : Float
    {
        return m_x;
    }
    
    private function set_x(value : Float) : Float
    {
        m_x = value;
        return value;
    }
    
    private function get_y() : Float
    {
        return m_y;
    }
    
    private function set_y(value : Float) : Float
    {
        m_y = value;
        return value;
    }
    
    /**
     * Get an initializer from the emitter. Only returns the first found initializer
     * of a type.
     * 
     * @param initializerClass
     *      Class object for the initializer to fetch
     * @return
     *      null if no initializer was found
     */
    public function getInitializer(initializerClass : Class<Dynamic>) : Initializer
    {
        var classNameToSearch : String = Type.getClassName(initializerClass);
        
        var initializer : Initializer = null;
        var i : Int = 0;
        var classNameOfInitializer : String;
        for (i in 0...m_initializers.length){
            classNameOfInitializer = Type.getClassName(Type.getClass(m_initializers[i]));
            if (classNameOfInitializer == classNameToSearch) 
            {
                initializer = m_initializers[i];
                break;
            }
        }
        
        return initializer;
    }
    
    public function setClock(clock : Clock) : Void
    {
        m_clock = clock;
    }
    
    /**
     * At the start and end of this function the condition that the list of particles
     * is clearly divided into alive and dead must hold true.
     */
    public function update(secondsElapsed : Float) : Void
    {
        // Check if we need to create a new set of particles based
        // on this emitter's clock
        var particlesToCreate : Int = m_clock.update(this, secondsElapsed);
        var i : Int;
        for (i in 0...particlesToCreate){
            createParticle();
        }  // Apply activities to this emitter  
        
        
        
        var numActivities : Int = m_activities.length;
        for (i in 0...numActivities){
            m_activities[i].update(this, secondsElapsed);
        }
        
        var particle : Particle;
		var i = 0;
		while (i < m_deadParticleIndex) {
            particle = m_particles[i];
            
            // Apply the list of actions to each of the particles
            var numActions : Int = m_actions.length;
            var j : Int;
            for (j in 0...numActions){
                var action : Action = m_actions[j];
                action.update(this, particle, secondsElapsed);
            }
			
			// Go through each particle after all operators have been applied and see if it is dead.  
            // If so we need to reorganize the particle list swapping out the dead ones
			// to the inactive half of the vector
			// Conditions for particle death include entering/exiting some bounding zone or
			// exceeding some lifetime limit
            if (particle.isDead) 
            {
                // The last alive particle is just to the left of the current dead
                // index. We swap the positions of the last alive particle
                var lastAliveIndex : Int = m_deadParticleIndex - 1;
                var lastAliveParticle : Particle = m_particles[lastAliveIndex];
                m_particles[i] = lastAliveParticle;
                m_particles[lastAliveIndex] = particle;
                m_deadParticleIndex--;
                i--;
                
                particle.reset();
            }
        }
    }
    
    /**
     * Create a new active particle.
     * 
     * This either creates a brand new object or recycles a previously dead one.
     */
    private function createParticle() : Void
    {
        var particle : Particle;
        if (m_particles.length <= m_deadParticleIndex) 
        {
            particle = new Particle();
            m_particles.push(particle);
        }
        else 
        {
            particle = m_particles[m_deadParticleIndex];
        }
        m_deadParticleIndex++;
        
        // Based on the orientation and position of this emitter
        // adjust some of the initial parameters of the particle
        this.initializeParticle(particle);
        
        var numInitializers : Int = m_initializers.length;
        var i : Int;
        for (i in 0...numInitializers){
            var initializer : Initializer = m_initializers[i];
            initializer.initialize(this, particle);
        }
    }
    
    /**
     * The emitter might have properties that should be passed to particles.
     */
    private function initializeParticle(particle : Particle) : Void
    {
        particle.xPosition = this.m_x;
        particle.yPosition = this.m_y;
    }
}
