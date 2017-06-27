package dragonbox.common.particlesystem.zone
{
    import dragonbox.common.particlesystem.Particle;
    
    import flash.geom.Point;

    /**
     * A zone defines a 2d region in space.
     * 
     * It can be used to find tuples of values.
     */
    public interface IZone
    {
        /**
         * Determines whether a point is inside the zone.
         * This method is used by the initializers and actions that
         * use the zone. Usually, it need not be called directly by the user.
         * 
         * @param x The x coordinate of the location to test for.
         * @param y The y coordinate of the location to test for.
         * @return true if point is inside the zone, false if it is outside.
         */
        function contains( x:Number, y:Number ):Boolean;
        
        /**
         * Returns a random point inside the zone.
         * This method is used by the initializers and actions that
         * use the zone. Usually, it need not be called directly by the user.
         * 
         * @return a random point inside the zone.
         */
        function getLocation():Point;
        
        /**
         * Returns the size of the zone.
         * This method is used by the MultiZone class to manage the balancing between the
         * different zones.
         * 
         * @return the size of the zone.
         */
        function getArea():Number;
        
        /**
         * Manages collisions between a particle and the zone. This method handles altering the
         * particle's position and velocity in response to the collision.
         * 
         * @param particle The particle to be tested for collision with the zone.
         * @param bounce The coefficient of restitution for the collision.
         * 
         * @return Whether a collision occured.
         */
        function collideParticle( particle:Particle, bounce:Number = 1 ):Boolean;
    }
}