package gameconfig.commonresource
{
    import wordproblem.resource.bundles.ResourceBundle;

    /**
     * This mainly consists of the assets required to for the play through of a level
     */
    public class EmbeddedBundle1X extends ResourceBundle
    {
        /*
        Assets for particles
        */
        [Embed(source="/../assets/particles/particle_atlas.png")]
        public static const particle_atlas:Class;
        [Embed(source="/../assets/particles/particle_atlas.xml", mimeType="application/octet-stream")]
        public static const particle_atlas_xml:Class;
        
        /*
        Default card images
        */
        [Embed(source="/../assets/card/wildcard.png")]
        public static const wildcard:Class;
        [Embed(source="/../assets/card/blank_card.png")]
        public static const card_blank:Class;
        [Embed(source="/../assets/card/halo.png")]
        public static const halo:Class;
        
        /*
        Embed bgs for levels
        */
        [Embed(source="/../assets/level_images/FantasyBackground.jpg")]
        public static const FantasyBackground:Class;
        
        [Embed(source="/../assets/ui/level_select/level_button_star.png")]
        public static const level_button_star:Class;
        
        /*
        New dynamically assigned background images for the cards
        */
        [Embed(source="/../assets/card/card_background_circle.png")]
        public static const card_background_circle:Class;
        [Embed(source="/../assets/card/card_background_circle_neg.png")]
        public static const card_background_circle_neg:Class;
        [Embed(source="/../assets/card/card_background_diamond.png")]
        public static const card_background_diamond:Class;
        [Embed(source="/../assets/card/card_background_diamond_neg.png")]
        public static const card_background_diamond_neg:Class;
        [Embed(source="/../assets/card/card_background_square.png")]
        public static const card_background_square:Class;
        [Embed(source="/../assets/card/card_background_square_neg.png")]
        public static const card_background_square_neg:Class;
        
        /*
         * New card images for word entities
         */
        [Embed(source="/../assets/card/fantasy/card_archers.png")]
        public static const card_archers:Class;
        [Embed(source="/../assets/card/fantasy/card_chalices.png")]
        public static const card_chalices:Class;
        [Embed(source="/../assets/card/fantasy/card_goldbars.png")]
        public static const card_goldbars:Class;
        [Embed(source="/../assets/card/fantasy/card_goldcoins.png")]
        public static const card_goldcoins:Class;
        [Embed(source="/../assets/card/fantasy/card_days.png")]
        public static const card_days:Class;
        [Embed(source="/../assets/card/fantasy/card_hours.png")]
        public static const card_hours:Class;
        [Embed(source="/../assets/card/fantasy/card_knights.png")]
        public static const card_knights:Class;
        [Embed(source="/../assets/card/fantasy/card_maps.png")]
        public static const card_maps:Class;
        [Embed(source="/../assets/card/fantasy/card_pearls.png")]
        public static const card_pearls:Class;
        [Embed(source="/../assets/card/fantasy/card_points.png")]
        public static const card_points:Class;
        [Embed(source="/../assets/card/fantasy/card_swordsmen.png")]
        public static const card_swordsmen:Class;
        [Embed(source="/../assets/card/fantasy/card_spellbooks.png")]
        public static const card_spellbooks:Class;
        [Embed(source="/../assets/card/fantasy/card_silvercoins.png")]
        public static const card_silvercoins:Class;
        [Embed(source="/../assets/card/fantasy/card_villages.png")]
        public static const card_villages:Class;
        [Embed(source="/../assets/card/fantasy/card_rings.png")]
        public static const card_rings:Class;
        [Embed(source="/../assets/card/fantasy/card_sapphires.png")]
        public static const card_sapphires:Class;
        
        [Embed(source="/../assets/card/fantasy/card_archers_neg.png")]
        public static const card_archers_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_chalices_neg.png")]
        public static const card_chalices_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_goldbars_neg.png")]
        public static const card_goldbars_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_goldcoins_neg.png")]
        public static const card_goldcoins_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_days_neg.png")]
        public static const card_days_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_hours_neg.png")]
        public static const card_hours_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_knights_neg.png")]
        public static const card_knights_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_maps_neg.png")]
        public static const card_maps_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_pearls_neg.png")]
        public static const card_pearls_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_points_neg.png")]
        public static const card_points_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_swordsmen_neg.png")]
        public static const card_swordsmen_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_spellbooks_neg.png")]
        public static const card_spellbooks_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_silvercoins_neg.png")]
        public static const card_silvercoins_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_villages_neg.png")]
        public static const card_villages_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_rings_neg.png")]
        public static const card_rings_neg:Class;
        [Embed(source="/../assets/card/fantasy/card_sapphires_neg.png")]
        public static const card_sapphires_neg:Class;
        
        [Embed(source="/../assets/card/sci_fi/card_credits.png")]
        public static const card_credits:Class;
        [Embed(source="/../assets/card/sci_fi/card_O2tanks.png")]
        public static const card_O2tanks:Class;
        [Embed(source="/../assets/card/sci_fi/card_astronauts.png")]
        public static const card_astronauts:Class;
        [Embed(source="/../assets/card/sci_fi/card_aliens.png")]
        public static const card_aliens:Class;
        [Embed(source="/../assets/card/sci_fi/card_asteroids.png")]
        public static const card_asteroids:Class;
        [Embed(source="/../assets/card/sci_fi/card_galaxies.png")]
        public static const card_galaxies:Class;
        [Embed(source="/../assets/card/sci_fi/card_minerals.png")]
        public static const card_minerals:Class;
        [Embed(source="/../assets/card/sci_fi/card_monsters.png")]
        public static const card_monsters:Class;
        [Embed(source="/../assets/card/sci_fi/card_moons.png")]
        public static const card_moons:Class;
        [Embed(source="/../assets/card/sci_fi/card_planets.png")]
        public static const card_planets:Class;
        [Embed(source="/../assets/card/sci_fi/card_robots.png")]
        public static const card_robots:Class;
        [Embed(source="/../assets/card/sci_fi/card_spaceships.png")]
        public static const card_spaceships:Class;
        [Embed(source="/../assets/card/sci_fi/card_spacestations.png")]
        public static const card_spacestations:Class;
        [Embed(source="/../assets/card/sci_fi/card_stars.png")]
        public static const card_stars:Class;
        [Embed(source="/../assets/card/sci_fi/card_torpedoes.png")]
        public static const card_torpedoes:Class;
        [Embed(source="/../assets/card/sci_fi/card_mineFields.png")]
        public static const card_minefields:Class;
        
        [Embed(source="/../assets/card/sci_fi/card_astronauts_neg.png")]
        public static const card_astronauts_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_aliens_neg.png")]
        public static const card_aliens_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_asteroids_neg.png")]
        public static const card_asteroids_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_galaxies_neg.png")]
        public static const card_galaxies_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_minerals_neg.png")]
        public static const card_minerals_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_monsters_neg.png")]
        public static const card_monsters_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_moons_neg.png")]
        public static const card_moons_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_planets_neg.png")]
        public static const card_planets_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_robots_neg.png")]
        public static const card_robots_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_spaceships_neg.png")]
        public static const card_spaceships_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_spacestations_neg.png")]
        public static const card_spacestations_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_stars_neg.png")]
        public static const card_stars_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_credits_neg.png")]
        public static const card_credits_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_O2tanks_neg.png")]
        public static const card_O2tanks_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_torpedoes_neg.png")]
        public static const card_torpedoes_neg:Class;
        [Embed(source="/../assets/card/sci_fi/card_minefields_neg.png")]
        public static const card_minefields_neg:Class;
        
        [Embed(source="/../assets/card/variables/card_briefcase.png")]
        public static const card_briefcase:Class;
        [Embed(source="/../assets/card/variables/card_briefcase_neg.png")]
        public static const card_briefcase_neg:Class;
        [Embed(source="/../assets/card/variables/card_cake.png")]
        public static const card_cake:Class;
        [Embed(source="/../assets/card/variables/card_cake_neg.png")]
        public static const card_cake_neg:Class;
        [Embed(source="/../assets/card/variables/card_detective.png")]
        public static const card_detective:Class;
        [Embed(source="/../assets/card/variables/card_detective_neg.png")]
        public static const card_detective_neg:Class;
        [Embed(source="/../assets/card/variables/card_heist.png")]
        public static const card_heist:Class;
        [Embed(source="/../assets/card/variables/card_heist_neg.png")]
        public static const card_heist_neg:Class;
        [Embed(source="/../assets/card/variables/card_ruler.png")]
        public static const card_ruler:Class;
        [Embed(source="/../assets/card/variables/card_ruler_neg.png")]
        public static const card_ruler_neg:Class;
        [Embed(source="/../assets/card/variables/card_scale.png")]
        public static const card_scale:Class;
        [Embed(source="/../assets/card/variables/card_scale_neg.png")]
        public static const card_scale_neg:Class;
        [Embed(source="/../assets/card/variables/card_wizard.png")]
        public static const card_wizard:Class;
        [Embed(source="/../assets/card/variables/card_wizard_neg.png")]
        public static const card_wizard_neg:Class;
        
        // Still images for the characters
        [Embed(source="/../assets/characters/cookie/cookie_happy_still.png")]
        public static const cookie_happy_still:Class;
        [Embed(source="/../assets/characters/cookie/cookie_sad_still.png")]
        public static const cookie_sad_still:Class;
        [Embed(source="/../assets/characters/cookie/cookie_neutral_still.png")]
        public static const cookie_neutral_still:Class;
        [Embed(source="/../assets/characters/taco/taco_happy_still.png")]
        public static const taco_happy_still:Class;
        [Embed(source="/../assets/characters/taco/taco_sad_still.png")]
        public static const taco_sad_still:Class;
        [Embed(source="/../assets/characters/taco/taco_neutral_still.png")]
        public static const taco_neutral_still:Class;
        
        /*
        These are for the player to 'unwrap' prizes earned, seen in the summary screen
        */
        [Embed(source="/../assets/items/non_animated_items/presents/present_bottom_blue.png")]
        public static const present_bottom_blue:Class;
        [Embed(source="/../assets/items/non_animated_items/presents/present_top_blue.png")]
        public static const present_top_blue:Class;
        [Embed(source="/../assets/items/non_animated_items/presents/present_bottom_pink.png")]
        public static const present_bottom_pink:Class;
        [Embed(source="/../assets/items/non_animated_items/presents/present_top_pink.png")]
        public static const present_top_pink:Class;
        [Embed(source="/../assets/items/non_animated_items/presents/present_bottom_purple.png")]
        public static const present_bottom_purple:Class;
        [Embed(source="/../assets/items/non_animated_items/presents/present_top_purple.png")]
        public static const present_top_purple:Class;
        [Embed(source="/../assets/items/non_animated_items/presents/present_bottom_yellow.png")]
        public static const present_bottom_yellow:Class;
        [Embed(source="/../assets/items/non_animated_items/presents/present_top_yellow.png")]
        public static const present_top_yellow:Class;
        
        [Embed(source="/../assets/ui/button_undo.png")]
        public static const button_undo:Class;
        [Embed(source="/../assets/ui/button_undo_click.png")]
        public static const button_undo_click:Class;
        [Embed(source="/../assets/ui/button_undo_mouseover.png")]
        public static const button_undo_mouseover:Class;
        
        [Embed(source="/../assets/ui/button_hint_blue.png")]
        public static const button_hint_blue:Class;
        [Embed(source="/../assets/ui/button_hint_orange.png")]
        public static const button_hint_orange:Class;
        [Embed(source="/../assets/ui/button_reset.png")]
        public static const button_reset:Class;
        [Embed(source="/../assets/ui/button_reset_click.png")]
        public static const button_reset_click:Class;
        
        [Embed(source="/../assets/ui/light.png")]
        public static const light:Class;
        [Embed(source="/../assets/ui/button_equals.png")]
        public static const button_equals:Class;
        [Embed(source="/../assets/ui/button_equals_click.png")]
        public static const button_equals_click:Class;
        [Embed(source="/../assets/ui/button_equals_locked.png")]
        public static const button_equals_locked:Class;
        [Embed(source="/../assets/ui/button_equals_mouseover.png")]
        public static const button_equals_mouseover:Class;
        [Embed(source="/../assets/ui/button_sidebar_maximize.png")]
        public static const button_sidebar_maximize:Class;
        [Embed(source="/../assets/ui/button_sidebar_maximize_click.png")]
        public static const button_sidebar_maximize_click:Class;
        [Embed(source="/../assets/ui/button_sidebar_maximize_mouseover.png")]
        public static const button_sidebar_maximize_mouseover:Class;
        [Embed(source="/../assets/ui/button_sidebar_minimize.png")]
        public static const button_sidebar_minimize:Class;
        [Embed(source="/../assets/ui/button_sidebar_minimize_click.png")]
        public static const button_sidebar_minimize_click:Class;
        [Embed(source="/../assets/ui/button_sidebar_minimize_mouseover.png")]
        public static const button_sidebar_minimize_mouseover:Class;
        [Embed(source="/../assets/ui/arrow_rotate.png")]
        public static const arrow_rotate:Class;
        [Embed(source="/../assets/ui/arrow_short.png")]
        public static const arrow_short:Class;
        [Embed(source="/../assets/ui/home_icon.png")]
        public static const home_icon:Class;
        [Embed(source="/../assets/ui/gear_yellow_icon.png")]
        public static const gear_yellow_icon:Class;
        [Embed(source="/../assets/ui/arrow_yellow_icon.png")]
        public static const arrow_yellow_icon:Class;
        [Embed(source="/../assets/ui/achievements_icon.png")]
        public static const achievements_icon:Class;
        [Embed(source="/../assets/ui/addition_icon.png")]
        public static const addition_icon:Class;
        [Embed(source="/../assets/ui/division_icon.png")]
        public static const division_icon:Class;
        [Embed(source="/../assets/ui/split_icon.png")]
        public static const split_icon:Class;
        [Embed(source="/../assets/ui/cards_icon.png")]
        public static const cards_icon:Class;
        [Embed(source="/../assets/ui/busy_icon.png")]
        public static const busy_icon:Class;
        [Embed(source="/../assets/ui/cgs_logo.png")]
        public static const cgs_logo:Class;
        [Embed(source="/../assets/ui/glow_yellow.png")]
        public static const glow_yellow:Class;
        
        [Embed(source="/../assets/props/balloon_grey.png")]
        public static const balloon_grey:Class;
        [Embed(source="/../assets/props/box.png")]
        public static const box:Class;
        [Embed(source="/../assets/props/coin.png")]
        public static const coin:Class;
        [Embed(source="/../assets/props/flowers_pink.png")]
        public static const flowers_pink:Class;
        [Embed(source="/../assets/props/mushroom_table.png")]
        public static const mushroom_table:Class;
        [Embed(source="/../assets/props/green_tree.png")]
        public static const green_tree:Class;
        [Embed(source="/../assets/props/teleporter.png")]
        public static const teleporter:Class;
        [Embed(source="/../assets/props/cannon.png")]
        public static const cannon:Class;
        [Embed(source="/../assets/props/treasure_chest_open.png")]
        public static const treasure_chest_open:Class;
        [Embed(source="/../assets/props/treasure_chest_closed.png")]
        public static const treasure_chest_closed:Class;
        
        [Embed(source="/../assets/ui/button_green_up.png")]
        public static const button_green_up:Class;
        [Embed(source="/../assets/ui/button_green_over.png")]
        public static const button_green_over:Class;
        [Embed(source="/../assets/ui/button_outline_white.png")]
        public static const button_outline_white:Class;
        [Embed(source="/../assets/ui/win/summary_background.png")]
        public static const summary_background:Class;
        [Embed(source="/../assets/ui/ui_background.png")]
        public static const ui_background:Class;
        [Embed(source="/../assets/ui/ui_background_wood.png")]
        public static const ui_background_wood:Class;
        [Embed(source="/../assets/ui/chalk_outline.png")]
        public static const chalk_outline:Class;
        
        [Embed(source="/../assets/ui/box_closed.png")]
        public static const box_closed:Class;
        [Embed(source="/../assets/ui/box_open.png")]
        public static const box_open:Class;
        [Embed(source="/../assets/ui/correct.png")]
        public static const correct:Class;
        [Embed(source="/../assets/ui/wrong.png")]
        public static const wrong:Class;
        [Embed(source="/../assets/ui/question_mark.png")]
        public static const question_mark:Class;
        [Embed(source="/../assets/ui/help_icon.png")]
        public static const help_icon:Class;
        [Embed(source="/../assets/ui/exclaimation_icon.png")]
        public static const exclaimation_icon:Class;
        [Embed(source="/../assets/ui/thought_bubble.png")]
        public static const thought_bubble:Class;
        [Embed(source="/../assets/ui/thought_bubble_small.png")]
        public static const thought_bubble_small:Class;
        
        [Embed(source="/../assets/ui/login/background_with_ui.jpg")]
        public static const login_background_with_ui:Class;
        
        [Embed(source="/../assets/ui/button_white.png")]
        public static const button_white:Class;
        [Embed(source="/../assets/ui/callout_arrow_top_white.png")]
        public static const callout_arrow_top_white:Class;
            
        [Embed(source="/../assets/ui/win/star_large.png")]
        public static const star_large:Class;
        [Embed(source="/../assets/ui/win/star_small_white.png")]
        public static const star_small_white:Class;
        [Embed(source="/../assets/ui/win/burst_purple.png")]
        public static const burst_purple:Class;  
        
        [Embed(source="/../assets/ui/term_area_left.png")]
        public static const term_area_left:Class;
        [Embed(source="/../assets/ui/term_area_right.png")]
        public static const term_area_right:Class;
        [Embed(source="/../assets/ui/term_area_left_wood.png")]
        public static const term_area_left_wood:Class;
        [Embed(source="/../assets/ui/term_area_right_wood.png")]
        public static const term_area_right_wood:Class;
        
        [Embed(source="/../assets/ui/custom_cursor.png")]
        public static const custom_cursor:Class;
        
        /*
        Scroller assets
        */
        [Embed(source="/../assets/ui/scroll/scrollbar_button.png")]
        public static const scrollbar_button:Class;
        [Embed(source="/../assets/ui/scroll/scrollbar_button_click.png")]
        public static const scrollbar_button_click:Class;
        [Embed(source="/../assets/ui/scroll/scrollbar_button_mouseover.png")]
        public static const scrollbar_button_mouseover:Class;
        [Embed(source="/../assets/ui/scroll/scrollbar_down.png")]
        public static const scrollbar_down:Class;
        [Embed(source="/../assets/ui/scroll/scrollbar_down_click.png")]
        public static const scrollbar_down_click:Class;
        [Embed(source="/../assets/ui/scroll/scrollbar_down_mouseover.png")]
        public static const scrollbar_down_mouseover:Class;
        [Embed(source="/../assets/ui/scroll/scrollbar_track.png")]
        public static const scrollbar_track:Class;
        [Embed(source="/../assets/ui/scroll/scrollbar_up.png")]
        public static const scrollbar_up:Class;
        [Embed(source="/../assets/ui/scroll/scrollbar_up_click.png")]
        public static const scrollbar_up_click:Class;
        [Embed(source="/../assets/ui/scroll/scrollbar_up_mouseover.png")]
        public static const scrollbar_up_mouseover:Class;
        
        /*
        XP bar assets
        */
        [Embed(source="/../assets/ui/xp/xp_bar_back.png")]
        public static const xp_bar_back:Class;
        [Embed(source="/../assets/ui/xp/xp_bar_fill.png")]
        public static const xp_bar_fill:Class;
        
        /*
        Character sprite sheets
        */
        [Embed(source="/../assets/characters/cookie/cookie_still_spritesheet.png")]
        public static const cookie_still_spritesheet:Class;
        [Embed(source="/../assets/characters/cookie/cookie_still_spritesheet.xml", mimeType="application/octet-stream")]
        public static const cookie_still_spritesheet_xml:Class;
        [Embed(source="/../assets/characters/cookie/cookie_idle_spritesheet.png")]
        public static const cookie_idle_spritesheet:Class;
        [Embed(source="/../assets/characters/cookie/cookie_idle_spritesheet.xml", mimeType="application/octet-stream")]
        public static const cookie_idle_spritesheet_xml:Class;
        
        [Embed(source="/../assets/characters/taco/taco_still_spritesheet.png")]
        public static const taco_still_spritesheet:Class;
        [Embed(source="/../assets/characters/taco/taco_still_spritesheet.xml", mimeType="application/octet-stream")]
        public static const taco_still_spritesheet_xml:Class;
        [Embed(source="/../assets/characters/taco/taco_idle_spritesheet.png")]
        public static const taco_idle_spritesheet:Class;
        [Embed(source="/../assets/characters/taco/taco_idle_spritesheet.xml", mimeType="application/octet-stream")]
        public static const taco_idle_spritesheet_xml:Class;
        
        public function EmbeddedBundle1X()
        {
            super();
        }
    }
}