package gameconfig.commonresource;


import wordproblem.resource.bundles.ResourceBundle;

/**
 * These are assets that are not critical to have any particular level play.
 * 
 * For example images for the end level summary screen or for the level select screen.
 * 
 * These are separated so that an app like the replay tool does not need to embed these since
 * that just needs the assets to draw a playable level.
 */
class EmbeddedLevelSelectResources extends ResourceBundle
{
    /*
    Embed assets for level select screen
    */
    @:meta(Embed(source="/../assets/ui/level_select/library_bg.jpg"))

    public static var library_bg : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/library_bg_blue.jpg"))

    public static var library_bg_blue : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/library_bg_purple.jpg"))

    public static var library_bg_purple : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/library_bg_yellow.jpg"))

    public static var library_bg_yellow : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/library_bg_orange.jpg"))

    public static var library_bg_orange : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/library_bg_green.jpg"))

    public static var library_bg_green : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/library_bg_teal.jpg"))

    public static var library_bg_teal : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/ui/level_select/level_select_bg_scifi.jpg"))

    public static var level_select_bg_scifi : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/level_select_bg_fantasy.jpg"))

    public static var level_select_bg_fantasy : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/level_select_bg_mystery.jpg"))

    public static var level_select_bg_mystery : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/level_select_bg_other.jpg"))

    public static var level_select_bg_other : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/fantasy_button_up.png"))

    public static var fantasy_button_up : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/locked_button_up.png"))

    public static var locked_button_up : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/level_select/level_button_lock.png"))

    public static var level_button_lock : Class<Dynamic>;
    
    /*
    Embed creature images
    */
    
    // Icon when reward is given
    @:meta(Embed(source="/../assets/items/creatures/purple_egg/ped_1S.png"))

    public static var ped_1S : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/creatures/yellow_egg/eyc_1S.png"))

    public static var eyc_1S : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/creatures/blue_egg/blue_egg_1S.png"))

    public static var blue_egg_1S : Class<Dynamic>;
    
    /*
    Reward Items that are animated
    */
    @:meta(Embed(source="/../assets/items/animated_items/box/box_spritesheet.png"))

    public static var box_spritesheet : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/animated_items/box/box_spritesheet.xml",mimeType="application/octet-stream"))

    public static var box_spritesheet_xml : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/animated_items/box/box_still.png"))

    public static var box_still : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/animated_items/fish_bowl/fish_bowl_spritesheet.png"))

    public static var fish_bowl_spritesheet : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/animated_items/fish_bowl/fish_bowl_spritesheet.xml",mimeType="application/octet-stream"))

    public static var fish_bowl_spritesheet_xml : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/animated_items/fish_bowl/fish_bowl_icon.png"))

    public static var fish_bowl_icon : Class<Dynamic>;
    
    /*
    Reward Items that are not animated
    */
    @:meta(Embed(source="/../assets/items/non_animated_items/item_camera.png"))

    public static var item_camera : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_camera_hidden.png"))

    public static var item_camera_hidden : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_camera_level_select.png"))

    public static var item_camera_level_select : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_camera_level_select_hidden.png"))

    public static var item_camera_level_select_hidden : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/non_animated_items/item_crown.png"))

    public static var item_crown : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_crown_hidden.png"))

    public static var item_crown_hidden : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_crown_level_select.png"))

    public static var item_crown_level_select : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_crown_level_select_hidden.png"))

    public static var item_crown_level_select_hidden : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/non_animated_items/item_detectivehat.png"))

    public static var item_detectivehat : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_detectivehat_hidden.png"))

    public static var item_detectivehat_hidden : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_detectivehat_level_select.png"))

    public static var item_detectivehat_level_select : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_detectivehat_level_select_hidden.png"))

    public static var item_detectivehat_level_select_hidden : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/non_animated_items/item_glass.png"))

    public static var item_glass : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_glass_hidden.png"))

    public static var item_glass_hidden : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_glass_level_select.png"))

    public static var item_glass_level_select : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_glass_level_select_hidden.png"))

    public static var item_glass_level_select_hidden : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/non_animated_items/item_planet.png"))

    public static var item_planet : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_planet_hidden.png"))

    public static var item_planet_hidden : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_planet_level_select.png"))

    public static var item_planet_level_select : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_planet_level_select_hidden.png"))

    public static var item_planet_level_select_hidden : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/non_animated_items/item_potions.png"))

    public static var item_potions : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_potions_hidden.png"))

    public static var item_potions_hidden : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_potions_level_select.png"))

    public static var item_potions_level_select : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_potions_level_select_hidden.png"))

    public static var item_potions_level_select_hidden : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/non_animated_items/item_robot.png"))

    public static var item_robot : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_robot_hidden.png"))

    public static var item_robot_hidden : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_robot_level_select.png"))

    public static var item_robot_level_select : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_robot_level_select_hidden.png"))

    public static var item_robot_level_select_hidden : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/non_animated_items/item_rocket.png"))

    public static var item_rocket : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_rocket_hidden.png"))

    public static var item_rocket_hidden : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_rocket_level_select.png"))

    public static var item_rocket_level_select : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_rocket_level_select_hidden.png"))

    public static var item_rocket_level_select_hidden : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/non_animated_items/item_wizardhat.png"))

    public static var item_wizardhat : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_wizardhat_hidden.png"))

    public static var item_wizardhat_hidden : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_wizardhat_level_select.png"))

    public static var item_wizardhat_level_select : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/non_animated_items/item_wizardhat_level_select_hidden.png"))

    public static var item_wizardhat_level_select_hidden : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/non_animated_items/item_stuffed_animal.png"))

    public static var item_stuffed_animal : Class<Dynamic>;
    
    /*
    Reward items for player collections
    */
    
    @:meta(Embed(source="/../assets/items/collections/animals/alligator.png"))

    public static var alligator : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/bear.png"))

    public static var bear : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/bird_blue.png"))

    public static var bird_blue : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/bird_brown.png"))

    public static var bird_brown : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/buffalo.png"))

    public static var buffalo : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/bunny.png"))

    public static var bunny : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/butterfly.png"))

    public static var butterfly : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/cat.png"))

    public static var cat : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/caterpillar.png"))

    public static var caterpillar : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/cow.png"))

    public static var cow : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/dinosaur.png"))

    public static var dinosaur : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/dove.png"))

    public static var dove : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/duck.png"))

    public static var duck : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/eagle.png"))

    public static var eagle : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/elephant.png"))

    public static var elephant : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/fish.png"))

    public static var fish : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/frog.png"))

    public static var frog : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/giraffe.png"))

    public static var giraffe : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/gorilla.png"))

    public static var gorilla : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/hamster.png"))

    public static var hamster : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/hawk.png"))

    public static var hawk : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/hedgehog.png"))

    public static var hedgehog : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/jellyfish.png"))

    public static var jellyfish : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/koala.png"))

    public static var koala : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/lemur.png"))

    public static var lemur : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/lion.png"))

    public static var lion : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/lion_cub.png"))

    public static var lion_cub : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/lizard.png"))

    public static var lizard : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/lizard_spotted.png"))

    public static var lizard_spotted : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/mammoth.png"))

    public static var mammoth : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/monkey.png"))

    public static var monkey : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/mouse.png"))

    public static var mouse : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/peacock.png"))

    public static var peacock : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/penguin.png"))

    public static var penguin : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/puppy.png"))

    public static var puppy : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/red_panda.png"))

    public static var red_panda : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/snail.png"))

    public static var snail : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/snake.png"))

    public static var snake : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/spider.png"))

    public static var spider : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/tiger.png"))

    public static var tiger : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/turtle.png"))

    public static var turtle : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/vulture.png"))

    public static var vulture : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/wolf.png"))

    public static var wolf : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/animals/zebra.png"))

    public static var zebra : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/collections/aliens/arctria.png"))

    public static var arctria : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/boofly.png"))

    public static var boofly : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/cawwie.png"))

    public static var cawwie : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/copper.png"))

    public static var copper : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/cyry.png"))

    public static var cyry : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/dripple.png"))

    public static var dripple : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/eecka.png"))

    public static var eecka : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/flarn.png"))

    public static var flarn : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/flobi.png"))

    public static var flobi : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/galeta.png"))

    public static var galeta : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/goo.png"))

    public static var goo : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/jellioops.png"))

    public static var jellioops : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/kerdoo.png"))

    public static var kerdoo : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/kisley.png"))

    public static var kisley : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/rawrgon.png"))

    public static var rawrgon : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/sleesh.png"))

    public static var sleesh : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/sponky.png"))

    public static var sponky : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/spugsy.png"))

    public static var spugsy : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/thort.png"))

    public static var thort : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/voya.png"))

    public static var voya : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/wippo.png"))

    public static var wippo : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/aliens/zuzu.png"))

    public static var zuzu : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/collections/food/apple.png"))

    public static var apple : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/banana.png"))

    public static var banana : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/birthday_cake.png"))

    public static var birthday_cake : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/broccoli.png"))

    public static var broccoli : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/candy.png"))

    public static var candy : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/cheese.png"))

    public static var cheese : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/cookie.png"))

    public static var cookie : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/cotton_candy.png"))

    public static var cotton_candy : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/cupcake.png"))

    public static var cupcake : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/dog_biscuit.png"))

    public static var dog_biscuit : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/mushroom.png"))

    public static var mushroom : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/popcorn.png"))

    public static var popcorn : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/pretzel.png"))

    public static var pretzel : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/pumpkin.png"))

    public static var pumpkin : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/steak.png"))

    public static var steak : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/food/watermelon.png"))

    public static var watermelon : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/collections/medieval/adventurer.png"))

    public static var adventurer : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/medieval/drawing_castle_night.png"))

    public static var drawing_castle_night : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/medieval/drawing_medieval_forest.png"))

    public static var drawing_medieval_forest : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/medieval/drawing_medieval_treasure.png"))

    public static var drawing_medieval_treasure : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/medieval/drawing_tomes.png"))

    public static var drawing_tomes : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/medieval/knight.png"))

    public static var knight : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/medieval/princess.png"))

    public static var princess : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/medieval/sword.png"))

    public static var sword : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/collections/misc/bush.png"))

    public static var bush : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/misc/dog_toy.png"))

    public static var dog_toy : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/misc/feather.png"))

    public static var feather : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/misc/locket.png"))

    public static var locket : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/misc/ribbons.png"))

    public static var ribbons : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/misc/rope.png"))

    public static var rope : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/misc/tree.png"))

    public static var tree : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/dragon_green.png"))

    public static var dragon_green : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/dragon_red.png"))

    public static var dragon_red : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/elf.png"))

    public static var elf : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/fairy.png"))

    public static var fairy : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/monster.png"))

    public static var monster : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/pegasus.png"))

    public static var pegasus : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/sea_sprite.png"))

    public static var sea_sprite : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/troll.png"))

    public static var troll : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/troll_forest.png"))

    public static var troll_forest : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/troll_mountain.png"))

    public static var troll_mountain : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/mythic_creatures/unicorn.png"))

    public static var unicorn : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/collections/space/alien.png"))

    public static var alien : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/space/martian.png"))

    public static var martian : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/space/moon.png"))

    public static var moon : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/space/moon_craft.png"))

    public static var moon_craft : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/space/pedrie.png"))

    public static var pedrie : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/space/plutonian.png"))

    public static var plutonian : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/space/rock.png"))

    public static var rock : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/space/space_ship.png"))

    public static var space_ship : Class<Dynamic>;
    
    // Custom mouse cursors
    @:meta(Embed(source="/../assets/items/collections/cursors/blue_fire_cursor.png"))

    public static var blue_fire_cursor : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/cursors/frog_cursor.png"))

    public static var frog_cursor : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/cursors/leaf_cursor.png"))

    public static var leaf_cursor : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/cursors/shovel_cursor.png"))

    public static var shovel_cursor : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/cursors/spaceship_cursor.png"))

    public static var spaceship_cursor : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/cursors/swirl_cursor.png"))

    public static var swirl_cursor : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/collections/cursors/yellow_fire_cursor.png"))

    public static var yellow_fire_cursor : Class<Dynamic>;
    
    
    public function new()
    {
        super();
    }
}
