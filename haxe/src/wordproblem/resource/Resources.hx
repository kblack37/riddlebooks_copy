package wordproblem.resource;


class Resources
{
    /*
    Keys to fetch resources from the asset manager
    */
    public static inline var PARTICLE_ATLAS : String = "particle_atlas";
    
    /*
    Particle keys must match the names in the atlas xml 
    */
    /** Fetch the entire super-texture containing all particles */
    public static inline var PARTICLE_ALL : String = "all";
    public static inline var PARTICLE_CIRCLE : String = "circle";
    public static inline var PARTICLE_STAR : String = "star";
    public static inline var PARTICLE_DIAMOND : String = "diamond";
    public static inline var PARTICLE_BUBBLE : String = "bubble";
    
    public static inline var CARD_BLANK : String = "card_blank";
    
    public static inline var HALO : String = "halo";

    public function new()
    {
    }
}
