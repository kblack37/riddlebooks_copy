package dragonbox.common.particlesystem.emitter
{
    import flash.utils.getQualifiedClassName;
    
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
    public class Emitter implements IDisposable
    {
        /**
         * Keep track of all possible particles (including dead ones
         * that will get recycled)
         */
        private var m_particles:Vector.<Particle>;
        
        /**
         * The index within the particle list that indicates the start
         * of particles that are dead and should no longer be processed
         */
        private var m_deadParticleIndex:int;
        
        /**
         * Group of initial values to set particles with
         */
        private var m_initializers:Vector.<Initializer>;
        
        /**
         * Group of modifiers to apply to particles with
         */
        private var m_actions:Vector.<Action>;
        
        /**
         * Group of modifiers to apply to the emitter
         */
        private var m_activities:Vector.<Activity>;
        
        /**
         * The clock for the emitter determines how many new particles are emitted
         * at a given frame.
         */
        private var m_clock:Clock;
        
        private var m_x:Number;
        private var m_y:Number;
        
        public function Emitter()
        {
            m_particles = new Vector.<Particle>();
            m_initializers = new Vector.<Initializer>();
            m_actions = new Vector.<Action>();
            m_activities = new Vector.<Activity>();
            
            m_x = 0.0;
            m_y = 0.0;
        }
        
        public function start():void
        {
            const particlesToCreate:uint = m_clock.start(this);
            var i:int;
            for (i = 0; i < particlesToCreate; i++)
            {
                createParticle();
            }
            
            // Initialize all activities
            const numActivities:uint = m_activities.length;
            for (i = 0; i < numActivities; i++)
            {
                m_activities[i].initialize(this);
            }
        }
        
        public function reset():void
        {
            m_deadParticleIndex = 0;
        }
        
        public function dispose():void
        {
        }
        
        public function getParticles():Vector.<Particle>
        {
            return m_particles;
        }
        
        /**
         * Get the maximum index of live particles that should be rendered
         */
        public function getParticleLimit():int
        {
            return m_deadParticleIndex;
        }
        
        public function addAction(action:Action):void
        {
            m_actions.push(action);   
        }
        
        public function removeActions():void
        {
            m_actions.length = 0;
        }
        
        public function addInitializer(initializer:Initializer):void
        {
            m_initializers.push(initializer);
        }
        
        public function removeAllInitializers():void
        {
            m_initializers.length = 0;
        }
        
        public function addActivity(activity:Activity):void
        {
            m_activities.push(activity);
        }
        
        public function removeAllActivities():void
        {
            m_activities.length = 0;
        }
        
        public function get x():Number
        {
            return m_x;
        }
        
        public function set x(value:Number):void
        {
            m_x = value;
        }
        
        public function get y():Number
        {
            return m_y;
        }
        
        public function set y(value:Number):void
        {
            m_y = value;
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
        public function getInitializer(initializerClass:Class):Initializer
        {
            const classNameToSearch:String = getQualifiedClassName(initializerClass);
            
            var initializer:Initializer = null;
            var i:int = 0;
            var classNameOfInitializer:String
            for (i = 0; i < m_initializers.length; i++)
            {
                classNameOfInitializer = getQualifiedClassName(m_initializers[i]); 
                if (classNameOfInitializer == classNameToSearch)
                {
                    initializer = m_initializers[i];
                    break;
                }
            }
            
            return initializer;
        }
        
        public function setClock(clock:Clock):void
        {
            m_clock = clock;
        }
        
        /**
         * At the start and end of this function the condition that the list of particles
         * is clearly divided into alive and dead must hold true.
         */
        public function update(secondsElapsed:Number):void
        {
            // Check if we need to create a new set of particles based
            // on this emitter's clock
            const particlesToCreate:uint = m_clock.update(this, secondsElapsed);
            var i:int;
            for (i = 0; i < particlesToCreate; i++)
            {
                createParticle();
            }
            
            // Apply activities to this emitter
            const numActivities:uint = m_activities.length;
            for (i = 0; i < numActivities; i++)
            {
                m_activities[i].update(this, secondsElapsed);
            }
            
            var particle:Particle;
            for (i = 0; i < m_deadParticleIndex; i++)
            {
                particle = m_particles[i];
                
                // Apply the list of actions to each of the particles
                const numActions:int = m_actions.length;
                var j:int;
                for (j = 0; j < numActions; j++)
                {
                    const action:Action = m_actions[j];
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
                    const lastAliveIndex:int = m_deadParticleIndex - 1;
                    const lastAliveParticle:Particle = m_particles[lastAliveIndex];
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
        private function createParticle():void
        {
            var particle:Particle;
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
            
            const numInitializers:int = m_initializers.length;
            var i:int;
            for (i = 0; i < numInitializers; i++)
            {
                const initializer:Initializer = m_initializers[i];
                initializer.initialize(this, particle);
            }
        }
        
        /**
         * The emitter might have properties that should be passed to particles.
         */
        private function initializeParticle(particle:Particle):void
        {
            particle.xPosition = this.m_x;
            particle.yPosition = this.m_y;
        }
    }
}