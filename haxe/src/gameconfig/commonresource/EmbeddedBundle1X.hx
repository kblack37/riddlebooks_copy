package gameconfig.commonresource;

import wordproblem.resource.bundles.ResourceBundle;

/**
 * This mainly consists of the assets required to for the play through of a level
 */
class EmbeddedBundle1X extends ResourceBundle
{
	private static var m_assetNameToPathMap : Map<String, String> = [
	/*
    Assets for particles
    */
    "particle_atlas" => "assets/particles/particle_atlas.png",
    "particle_atlas_xml" => "assets/particles/particle_atlas_xml",
    //@:meta(Embed(source="/../assets/particles/particle_atlas.xml",mimeType="application/octet-stream"))
    
    /*
    Default card images
    */
    "wildcard" => "assets/card/wildcard.png",
    "blank_card" => "assets/card/blank_card.png",
    "halo" => "assets/card/halo.png",
    
    /*
    Embed bgs for levels
    */
    //@:meta(Embed(source = "/../assets/level_images/FantasyBackground.jpg"))
	"FantasyBackground" => "assets/level_images/FantasyBackground.jpg",
    "level_button_star" => "assets/ui/level_select/level_button_star.png",

    /*
    New dynamically assigned background images for the cards
    */
    "card_background_circle" => "assets/card/card_background_circle.png",
    "card_background_circle_neg" => "assets/card/card_background_circle_neg.png",
    "card_background_diamond" => "assets/card/card_background_diamond.png",
    "card_background_diamond_neg" => "assets/card/card_background_diamond_neg.png",
    "card_background_square" => "assets/card/card_background_square.png",
    "card_background_square_neg" => "assets/card/card_background_square_neg.png",
    
    /*
     * New card images for word entities
     */
    "card_archers" => "assets/card/fantasy/card_archers.png",
    "card_chalices" => "assets/card/fantasy/card_chalices.png",
    "card_goldbars" => "assets/card/fantasy/card_goldbars.png",
    "card_goldcoins" => "assets/card/fantasy/card_goldcoins.png",
    "card_days" => "assets/card/fantasy/card_days.png",
    "card_hours" => "assets/card/fantasy/card_hours.png",
    "card_knights" => "assets/card/fantasy/card_knights.png",
    "card_maps" => "assets/card/fantasy/card_maps.png",
    "card_pearls" => "assets/card/fantasy/card_pearls.png",
    "card_points" => "assets/card/fantasy/card_points.png",
    "card_swordsmen" => "assets/card/fantasy/card_swordsmen.png",
    "card_spellbooks" => "assets/card/fantasy/card_spellbooks.png",
    "card_silvercoins" => "assets/card/fantasy/card_silvercoins.png",
    "card_villages" => "assets/card/fantasy/card_villages.png",
    "card_rings" => "assets/card/fantasy/card_rings.png",
    "card_sapphires" => "assets/card/fantasy/card_sapphires.png",
    "card_archers_neg" => "assets/card/fantasy/card_archers_neg.png",
    "card_chalices_neg" => "assets/card/fantasy/card_chalices_neg.png",
    "card_goldbars_neg" => "assets/card/fantasy/card_goldbars_neg.png",
    "card_goldcoins_neg" => "assets/card/fantasy/card_goldcoins_neg.png",
    "card_days_neg" => "assets/card/fantasy/card_days_neg.png",
    "card_hours_neg" => "assets/card/fantasy/card_hours_neg.png",
    "card_knights_neg" => "assets/card/fantasy/card_knights_neg.png",
    "card_maps_neg" => "assets/card/fantasy/card_maps_neg.png",
    "card_pearls_neg" => "assets/card/fantasy/card_pearls_neg.png",
    "card_points_neg" => "assets/card/fantasy/card_points_neg.png",
    "card_swordsmen_neg" => "assets/card/fantasy/card_swordsmen_neg.png",
    "card_spellbooks_neg" => "assets/card/fantasy/card_spellbooks_neg.png",
    "card_silvercoins_neg" => "assets/card/fantasy/card_silvercoins_neg.png",
    "card_villages_neg" => "assets/card/fantasy/card_villages_neg.png",
    "card_rings_neg" => "assets/card/fantasy/card_rings_neg.png",
    "card_sapphires_neg" => "assets/card/fantasy/card_sapphires_neg.png",
    "card_credits" => "assets/card/sci_fi/card_credits.png",
    "card_O2tanks" => "assets/card/sci_fi/card_O2tanks.png",
    "card_astronauts" => "assets/card/sci_fi/card_astronauts.png",
    "card_aliens" => "assets/card/sci_fi/card_aliens.png",
    "card_asteroids" => "assets/card/sci_fi/card_asteroids.png",
    "card_galaxies" => "assets/card/sci_fi/card_galaxies.png",
    "card_minerals" => "assets/card/sci_fi/card_minerals.png",
    "card_monsters" => "assets/card/sci_fi/card_monsters.png",
    "card_moons" => "assets/card/sci_fi/card_moons.png",
    "card_planets" => "assets/card/sci_fi/card_planets.png",
    "card_robots" => "assets/card/sci_fi/card_robots.png",
    "card_spaceships" => "assets/card/sci_fi/card_spaceships.png",
    "card_spacestations" => "assets/card/sci_fi/card_spacestations.png",
    "card_stars" => "assets/card/sci_fi/card_stars.png",
    "card_torpedoes" => "assets/card/sci_fi/card_torpedoes.png",
    "card_mineFields" => "assets/card/sci_fi/card_mineFields.png",
    "card_astronauts_neg" => "assets/card/sci_fi/card_astronauts_neg.png",
    "card_aliens_neg" => "assets/card/sci_fi/card_aliens_neg.png",
    "card_asteroids_neg" => "assets/card/sci_fi/card_asteroids_neg.png",
    "card_galaxies_neg" => "assets/card/sci_fi/card_galaxies_neg.png",
    "card_minerals_neg" => "assets/card/sci_fi/card_minerals_neg.png",
    "card_monsters_neg" => "assets/card/sci_fi/card_monsters_neg.png",
    "card_moons_neg" => "assets/card/sci_fi/card_moons_neg.png",
    "card_planets_neg" => "assets/card/sci_fi/card_planets_neg.png",
    "card_robots_neg" => "assets/card/sci_fi/card_robots_neg.png",
    "card_spaceships_neg" => "assets/card/sci_fi/card_spaceships_neg.png",
    "card_spacestations_neg" => "assets/card/sci_fi/card_spacestations_neg.png",
    "card_stars_neg" => "assets/card/sci_fi/card_stars_neg.png",
    "card_credits_neg" => "assets/card/sci_fi/card_credits_neg.png",
    "card_O2tanks_neg" => "assets/card/sci_fi/card_O2tanks_neg.png",
    "card_torpedoes_neg" => "assets/card/sci_fi/card_torpedoes_neg.png",
    "card_minefields_neg" => "assets/card/sci_fi/card_minefields_neg.png",
    "card_briefcase" => "assets/card/variables/card_briefcase.png",
    "card_briefcase_neg" => "assets/card/variables/card_briefcase_neg.png",
    "card_cake" => "assets/card/variables/card_cake.png",
    "card_cake_neg" => "assets/card/variables/card_cake_neg.png",
    "card_detective" => "assets/card/variables/card_detective.png",
    "card_detective_neg" => "assets/card/variables/card_detective_neg.png",
    "card_heist" => "assets/card/variables/card_heist.png",
    "card_heist_neg" => "assets/card/variables/card_heist_neg.png",
    "card_ruler" => "assets/card/variables/card_ruler.png",
    "card_ruler_neg" => "assets/card/variables/card_ruler_neg.png",
    "card_scale" => "assets/card/variables/card_scale.png",
    "card_scale_neg" => "assets/card/variables/card_scale_neg.png",
    "card_wizard" => "assets/card/variables/card_wizard.png",
    "card_wizard_neg" => "assets/card/variables/card_wizard_neg.png",
	
	/*
    Assets specifically for the bar model
    */
    "button_check_bar_model_down" => "assets/ui/button_check_bar_model_down.png",
    "button_check_bar_model_over" => "assets/ui/button_check_bar_model_over.png",
    "button_check_bar_model_up" => "assets/ui/button_check_bar_model_up.png",
    "bracket_middle" => "assets/ui/bar_model/bracket_middle.png",
    "bracket_left_edge" => "assets/ui/bar_model/bracket_left_edge.png",
    "bracket_right_edge" => "assets/ui/bar_model/bracket_right_edge.png",
    "bracket_full" => "assets/ui/bar_model/bracket_full.png",
    "comparison_left" => "assets/ui/bar_model/comparison_left.png",
    "comparison_right" => "assets/ui/bar_model/comparison_right.png",
    "comparison_full" => "assets/ui/bar_model/comparison_full.png",
    "dotted_line_corner" => "assets/ui/bar_model/dotted_line_corner.png",
    "dotted_line_segment" => "assets/ui/bar_model/dotted_line_segment.png",
    "ring" => "assets/ui/bar_model/ring.png",
	
	/*
	 * Expression assets
	 */
	"plus" => "assets/operators/plus.png",
    "subtract" => "assets/operators/subtract.png",
    "parentheses_right" => "assets/operators/parentheses_right.png",
    "parentheses_left" => "assets/operators/parentheses_left.png",
    "multiply_dot" => "assets/operators/multiply_dot.png",
    "multiply_x" => "assets/operators/multiply_x.png",
    "equal" => "assets/operators/equal.png",
    "divide_obelus" => "assets/operators/divide_obelus.png",
    "divide_bar" => "assets/operators/divide_bar.png",
    
    // Still images for the characters
    "cookie_happy_still" => "assets/characters/cookie/cookie_happy_still.png",
    "cookie_sad_still" => "assets/characters/cookie/cookie_sad_still.png",
    "cookie_neutral_still" => "assets/characters/cookie/cookie_neutral_still.png",
    "taco_happy_still" => "assets/characters/taco/taco_happy_still.png",
    "taco_sad_still" => "assets/characters/taco/taco_sad_still.png",
    "taco_neutral_still" => "assets/characters/taco/taco_neutral_still.png",
    
    /*
    These are for the player to 'unwrap' prizes earned, seen in the summary screen
    */
    "present_bottom_blue" => "assets/items/non_animated_items/presents/present_bottom_blue.png",
    "present_top_blue" => "assets/items/non_animated_items/presents/present_top_blue.png",
    "present_bottom_pink" => "assets/items/non_animated_items/presents/present_bottom_pink.png",
    "present_top_pink" => "assets/items/non_animated_items/presents/present_top_pink.png",
    "present_bottom_purple" => "assets/items/non_animated_items/presents/present_bottom_purple.png",
    "present_top_purple" => "assets/items/non_animated_items/presents/present_top_purple.png",
    "present_bottom_yellow" => "assets/items/non_animated_items/presents/present_bottom_yellow.png",
    "present_top_yellow" => "assets/items/non_animated_items/presents/present_top_yellow.png",
    "button_undo" => "assets/ui/button_undo.png",
    "button_undo_click" => "assets/ui/button_undo_click.png",
    "button_undo_mouseover" => "assets/ui/button_undo_mouseover.png",
    "button_hint_blue" => "assets/ui/button_hint_blue.png",
    "button_hint_orange" => "assets/ui/button_hint_orange.png",
    "button_reset" => "assets/ui/button_reset.png",
    "button_reset_click" => "assets/ui/button_reset_click.png",
    "light" => "assets/ui/light.png",
    "button_equals" => "assets/ui/button_equals.png",
    "button_equals_click" => "assets/ui/button_equals_click.png",
    "button_equals_locked" => "assets/ui/button_equals_locked.png",
    "button_equals_mouseover" => "assets/ui/button_equals_mouseover.png",
    "button_sidebar_maximize" => "assets/ui/button_sidebar_maximize.png",
    "button_sidebar_maximize_click" => "assets/ui/button_sidebar_maximize_click.png",
    "button_sidebar_maximize_mouseover" => "assets/ui/button_sidebar_maximize_mouseover.png",
    "button_sidebar_minimize" => "assets/ui/button_sidebar_minimize.png",
    "button_sidebar_minimize_click" => "assets/ui/button_sidebar_minimize_click.png",
    "button_sidebar_minimize_mouseover" => "assets/ui/button_sidebar_minimize_mouseover.png",
    "arrow_rotate" => "assets/ui/arrow_rotate.png",
    "arrow_short" => "assets/ui/arrow_short.png",
    "home_icon" => "assets/ui/home_icon.png",
    "gear_yellow_icon" => "assets/ui/gear_yellow_icon.png",
    "arrow_yellow_icon" => "assets/ui/arrow_yellow_icon.png",
    "achievements_icon" => "assets/ui/achievements_icon.png",
    "addition_icon" => "assets/ui/addition_icon.png",
    "division_icon" => "assets/ui/division_icon.png",
    "split_icon" => "assets/ui/split_icon.png",
    "cards_icon" => "assets/ui/cards_icon.png",
    "busy_icon" => "assets/ui/busy_icon.png",
    "cgs_logo" => "assets/ui/cgs_logo.png",
    "glow_yellow" => "assets/ui/glow_yellow.png",
    "balloon_grey" => "assets/props/balloon_grey.png",
    "box" => "assets/props/box.png",
    "coin" => "assets/props/coin.png",
    "flowers_pink" => "assets/props/flowers_pink.png",
    "mushroom_table" => "assets/props/mushroom_table.png",
    "green_tree" => "assets/props/green_tree.png",
    "teleporter" => "assets/props/teleporter.png",
    "cannon" => "assets/props/cannon.png",
    "treasure_chest_open" => "assets/props/treasure_chest_open.png",
    "treasure_chest_closed" => "assets/props/treasure_chest_closed.png",
    "button_green_up" => "assets/ui/button_green_up.png",
    "button_green_over" => "assets/ui/button_green_over.png",
    "button_outline_white" => "assets/ui/button_outline_white.png",
    "summary_background" => "assets/ui/win/summary_background.png",
    "ui_background" => "assets/ui/ui_background.png",
    "ui_background_wood" => "assets/ui/ui_background_wood.png",
    "chalk_outline" => "assets/ui/chalk_outline.png",
    "box_closed" => "assets/ui/box_closed.png",
    "box_open" => "assets/ui/box_open.png",
    "correct" => "assets/ui/correct.png",
    "wrong" => "assets/ui/wrong.png",
    "question_mark" => "assets/ui/question_mark.png",
    "help_icon" => "assets/ui/help_icon.png",
    "exclaimation_icon" => "assets/ui/exclaimation_icon.png",
    "thought_bubble" => "assets/ui/thought_bubble.png",
    "thought_bubble_small" => "assets/ui/thought_bubble_small.png",
    "background_with_ui" => "assets/ui/login/background_with_ui.jpg",
    "button_white" => "assets/ui/button_white.png",
    "callout_arrow_top_white" => "assets/ui/callout_arrow_top_white.png",
    "star_large" => "assets/ui/win/star_large.png",
    "star_small_white" => "assets/ui/win/star_small_white.png",
    "burst_purple" => "assets/ui/win/burst_purple.png",
    "term_area_left" => "assets/ui/term_area_left.png",
    "term_area_right" => "assets/ui/term_area_right.png",
    "term_area_left_wood" => "assets/ui/term_area_left_wood.png",
    "term_area_right_wood" => "assets/ui/term_area_right_wood.png",
    "custom_cursor" => "assets/ui/custom_cursor.png",
    
    /*
    Scroller assets
    */
    "scrollbar_button" => "assets/ui/scroll/scrollbar_button.png",
    "scrollbar_button_click" => "assets/ui/scroll/scrollbar_button_click.png",
    "scrollbar_button_mouseover" => "assets/ui/scroll/scrollbar_button_mouseover.png",
    "scrollbar_down" => "assets/ui/scroll/scrollbar_down.png",
    "scrollbar_down_click" => "assets/ui/scroll/scrollbar_down_click.png",
    "scrollbar_down_mouseover" => "assets/ui/scroll/scrollbar_down_mouseover.png",
    "scrollbar_track" => "assets/ui/scroll/scrollbar_track.png",
    "scrollbar_up" => "assets/ui/scroll/scrollbar_up.png",
    "scrollbar_up_click" => "assets/ui/scroll/scrollbar_up_click.png",
    "scrollbar_up_mouseover" => "assets/ui/scroll/scrollbar_up_mouseover.png",
    
    /*
    XP bar assets
    */
    "xp_bar_back" => "assets/ui/xp/xp_bar_back.png",
    "xp_bar_fill" => "assets/ui/xp/xp_bar_fill.png",
    
    /*
    Character sprite sheets
    */
    "cookie_still_spritesheet" => "assets/characters/cookie/cookie_still_spritesheet.png",
	"cookie_still_spritesheet_xml" => "assets/characters/cookie/cookie_still_spritesheet.xml",
    //@:meta(Embed(source="/../assets/characters/cookie/cookie_still_spritesheet.xml",mimeType="application/octet-stream"))
    "cookie_idle_spritesheet" => "assets/characters/cookie/cookie_idle_spritesheet.png",
	"cookie_idle_spritesheet_xml" => "assets/characters/cookie/cookie_idle_spritesheet.xml",
    //@:meta(Embed(source="/../assets/characters/cookie/cookie_idle_spritesheet.xml",mimeType="application/octet-stream"))
    "taco_still_spritesheet" => "assets/characters/taco/taco_still_spritesheet.png",
	"taco_still_spritesheet_xml" => "assets/characters/taco/taco_still_spritesheet.xml",
    //@:meta(Embed(source="/../assets/characters/taco/taco_still_spritesheet.xml",mimeType="application/octet-stream"))
    "taco_idle_spritesheet" => "assets/characters/taco/taco_idle_spritesheet.png",
	"taco_idle_spritesheet_xml" => "assets/characters/taco/taco_idle_spritesheet.xml"
    //@:meta(Embed(source="/../assets/characters/taco/taco_idle_spritesheet.xml",mimeType="application/octet-stream"))
	];
	
	/*
	 * Check if a given name of an asset has a mapping to its filepath
	 */
	public static function pathMappingExists(assetName : String) : Bool {
		return m_assetNameToPathMap.exists(assetName);
	}
	
	/*
	 * Return the filepath associated with the given asset name. Returns
	 * null if no such mapping exists
	 */
	public static function getPathMapping(assetName : String) : String {
		return m_assetNameToPathMap.get(assetName);
	}
    
    
    public function new()
    {
        super();
    }
}
