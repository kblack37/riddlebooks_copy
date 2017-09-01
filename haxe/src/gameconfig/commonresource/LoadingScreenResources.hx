package gameconfig.commonresource;


import wordproblem.resource.bundles.ResourceBundle;

/**
 * These are the common resources needed to get the common loading screen for the game
 * displayable. It is important these are loaded first because it will allow us to show a
 * graphic while other resources are loaded later.
 */
class LoadingScreenResources extends ResourceBundle
{
    @:meta(Embed(source="/../assets/ui/login/background.jpg"))
    public static var login_background : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/win/star_small_white.png"))
    public static var star_small_white : Class<Dynamic>;
	
	public function new() {
		super();
	}
}
