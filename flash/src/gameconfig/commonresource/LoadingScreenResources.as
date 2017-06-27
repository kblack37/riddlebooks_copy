package gameconfig.commonresource
{
    import wordproblem.resource.bundles.ResourceBundle;
    
    /**
     * These are the common resources needed to get the common loading screen for the game
     * displayable. It is important these are loaded first because it will allow us to show a
     * graphic while other resources are loaded later.
     */
    public class LoadingScreenResources extends ResourceBundle
    {
        [Embed(source="/../assets/ui/login/background.jpg")]
        public static const login_background:Class;
		
		[Embed(source="/../assets/ui/win/star_small_white.png")]
		public static const star_small_white:Class;
        
        public function LoadingScreenResources()
        {
            super();
        }
    }
}