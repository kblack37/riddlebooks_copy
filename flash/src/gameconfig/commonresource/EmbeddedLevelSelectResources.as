package gameconfig.commonresource
{
    import wordproblem.resource.bundles.ResourceBundle;

    /**
     * These are assets that are not critical to have any particular level play.
     * 
     * For example images for the end level summary screen or for the level select screen.
     * 
     * These are separated so that an app like the replay tool does not need to embed these since
     * that just needs the assets to draw a playable level.
     */
    public class EmbeddedLevelSelectResources extends ResourceBundle
    {
        /*
        Embed assets for level select screen
        */
        [Embed(source="/../assets/ui/level_select/library_bg.jpg")]
        public static const library_bg:Class;
        [Embed(source="/../assets/ui/level_select/library_bg_blue.jpg")]
        public static const library_bg_blue:Class;
        [Embed(source="/../assets/ui/level_select/library_bg_purple.jpg")]
        public static const library_bg_purple:Class;
        [Embed(source="/../assets/ui/level_select/library_bg_yellow.jpg")]
        public static const library_bg_yellow:Class;
        [Embed(source="/../assets/ui/level_select/library_bg_orange.jpg")]
        public static const library_bg_orange:Class;
        [Embed(source="/../assets/ui/level_select/library_bg_green.jpg")]
        public static const library_bg_green:Class;
        [Embed(source="/../assets/ui/level_select/library_bg_teal.jpg")]
        public static const library_bg_teal:Class;
        
        [Embed(source="/../assets/ui/level_select/level_select_bg_scifi.jpg")]
        public static const level_select_bg_scifi:Class;
        [Embed(source="/../assets/ui/level_select/level_select_bg_fantasy.jpg")]
        public static const level_select_bg_fantasy:Class;
        [Embed(source="/../assets/ui/level_select/level_select_bg_mystery.jpg")]
        public static const level_select_bg_mystery:Class;
        [Embed(source="/../assets/ui/level_select/level_select_bg_other.jpg")]
        public static const level_select_bg_other:Class;
        [Embed(source="/../assets/ui/level_select/fantasy_button_up.png")]
        public static const fantasy_button_up:Class;
        [Embed(source="/../assets/ui/level_select/locked_button_up.png")]
        public static const locked_button_up:Class;
        [Embed(source="/../assets/ui/level_select/level_button_lock.png")]
        public static const level_button_lock:Class;
        
        /*
        Embed creature images
        */
        
        // Icon when reward is given
        [Embed(source="/../assets/items/creatures/purple_egg/ped_1S.png")]
        public static const ped_1S:Class;
        [Embed(source="/../assets/items/creatures/yellow_egg/eyc_1S.png")]
        public static const eyc_1S:Class;
        [Embed(source="/../assets/items/creatures/blue_egg/blue_egg_1S.png")]
        public static const blue_egg_1S:Class;
        
        /*
        Reward Items that are animated
        */
        [Embed(source="/../assets/items/animated_items/box/box_spritesheet.png")]
        public static const box_spritesheet:Class;
        [Embed(source="/../assets/items/animated_items/box/box_spritesheet.xml", mimeType="application/octet-stream")]
        public static const box_spritesheet_xml:Class;
        [Embed(source="/../assets/items/animated_items/box/box_still.png")]
        public static const box_still:Class;
        [Embed(source="/../assets/items/animated_items/fish_bowl/fish_bowl_spritesheet.png")]
        public static const fish_bowl_spritesheet:Class;
        [Embed(source="/../assets/items/animated_items/fish_bowl/fish_bowl_spritesheet.xml", mimeType="application/octet-stream")]
        public static const fish_bowl_spritesheet_xml:Class;
        [Embed(source="/../assets/items/animated_items/fish_bowl/fish_bowl_icon.png")]
        public static const fish_bowl_icon:Class;
        
        /*
        Reward Items that are not animated
        */
        [Embed(source="/../assets/items/non_animated_items/item_camera.png")]
        public static const item_camera:Class;
        [Embed(source="/../assets/items/non_animated_items/item_camera_hidden.png")]
        public static const item_camera_hidden:Class;
        [Embed(source="/../assets/items/non_animated_items/item_camera_level_select.png")]
        public static const item_camera_level_select:Class;
        [Embed(source="/../assets/items/non_animated_items/item_camera_level_select_hidden.png")]
        public static const item_camera_level_select_hidden:Class;
        
        [Embed(source="/../assets/items/non_animated_items/item_crown.png")]
        public static const item_crown:Class;
        [Embed(source="/../assets/items/non_animated_items/item_crown_hidden.png")]
        public static const item_crown_hidden:Class;
        [Embed(source="/../assets/items/non_animated_items/item_crown_level_select.png")]
        public static const item_crown_level_select:Class;
        [Embed(source="/../assets/items/non_animated_items/item_crown_level_select_hidden.png")]
        public static const item_crown_level_select_hidden:Class;
        
        [Embed(source="/../assets/items/non_animated_items/item_detectivehat.png")]
        public static const item_detectivehat:Class;
        [Embed(source="/../assets/items/non_animated_items/item_detectivehat_hidden.png")]
        public static const item_detectivehat_hidden:Class;
        [Embed(source="/../assets/items/non_animated_items/item_detectivehat_level_select.png")]
        public static const item_detectivehat_level_select:Class;
        [Embed(source="/../assets/items/non_animated_items/item_detectivehat_level_select_hidden.png")]
        public static const item_detectivehat_level_select_hidden:Class;
        
        [Embed(source="/../assets/items/non_animated_items/item_glass.png")]
        public static const item_glass:Class;
        [Embed(source="/../assets/items/non_animated_items/item_glass_hidden.png")]
        public static const item_glass_hidden:Class;
        [Embed(source="/../assets/items/non_animated_items/item_glass_level_select.png")]
        public static const item_glass_level_select:Class;
        [Embed(source="/../assets/items/non_animated_items/item_glass_level_select_hidden.png")]
        public static const item_glass_level_select_hidden:Class;
        
        [Embed(source="/../assets/items/non_animated_items/item_planet.png")]
        public static const item_planet:Class;
        [Embed(source="/../assets/items/non_animated_items/item_planet_hidden.png")]
        public static const item_planet_hidden:Class;
        [Embed(source="/../assets/items/non_animated_items/item_planet_level_select.png")]
        public static const item_planet_level_select:Class;
        [Embed(source="/../assets/items/non_animated_items/item_planet_level_select_hidden.png")]
        public static const item_planet_level_select_hidden:Class;
        
        [Embed(source="/../assets/items/non_animated_items/item_potions.png")]
        public static const item_potions:Class;
        [Embed(source="/../assets/items/non_animated_items/item_potions_hidden.png")]
        public static const item_potions_hidden:Class;
        [Embed(source="/../assets/items/non_animated_items/item_potions_level_select.png")]
        public static const item_potions_level_select:Class;
        [Embed(source="/../assets/items/non_animated_items/item_potions_level_select_hidden.png")]
        public static const item_potions_level_select_hidden:Class;
        
        [Embed(source="/../assets/items/non_animated_items/item_robot.png")]
        public static const item_robot:Class;
        [Embed(source="/../assets/items/non_animated_items/item_robot_hidden.png")]
        public static const item_robot_hidden:Class;
        [Embed(source="/../assets/items/non_animated_items/item_robot_level_select.png")]
        public static const item_robot_level_select:Class;
        [Embed(source="/../assets/items/non_animated_items/item_robot_level_select_hidden.png")]
        public static const item_robot_level_select_hidden:Class;
        
        [Embed(source="/../assets/items/non_animated_items/item_rocket.png")]
        public static const item_rocket:Class;
        [Embed(source="/../assets/items/non_animated_items/item_rocket_hidden.png")]
        public static const item_rocket_hidden:Class;
        [Embed(source="/../assets/items/non_animated_items/item_rocket_level_select.png")]
        public static const item_rocket_level_select:Class;
        [Embed(source="/../assets/items/non_animated_items/item_rocket_level_select_hidden.png")]
        public static const item_rocket_level_select_hidden:Class;
        
        [Embed(source="/../assets/items/non_animated_items/item_wizardhat.png")]
        public static const item_wizardhat:Class;
        [Embed(source="/../assets/items/non_animated_items/item_wizardhat_hidden.png")]
        public static const item_wizardhat_hidden:Class;
        [Embed(source="/../assets/items/non_animated_items/item_wizardhat_level_select.png")]
        public static const item_wizardhat_level_select:Class;
        [Embed(source="/../assets/items/non_animated_items/item_wizardhat_level_select_hidden.png")]
        public static const item_wizardhat_level_select_hidden:Class;
        
        [Embed(source="/../assets/items/non_animated_items/item_stuffed_animal.png")]
        public static const item_stuffed_animal:Class;
        
        /*
        Reward items for player collections
        */
        
        [Embed(source="/../assets/items/collections/animals/alligator.png")]
        public static const alligator:Class;
        [Embed(source="/../assets/items/collections/animals/bear.png")]
        public static const bear:Class;
        [Embed(source="/../assets/items/collections/animals/bird_blue.png")]
        public static const bird_blue:Class;
        [Embed(source="/../assets/items/collections/animals/bird_brown.png")]
        public static const bird_brown:Class;
        [Embed(source="/../assets/items/collections/animals/buffalo.png")]
        public static const buffalo:Class;
        [Embed(source="/../assets/items/collections/animals/bunny.png")]
        public static const bunny:Class;
        [Embed(source="/../assets/items/collections/animals/butterfly.png")]
        public static const butterfly:Class;
        [Embed(source="/../assets/items/collections/animals/cat.png")]
        public static const cat:Class;
        [Embed(source="/../assets/items/collections/animals/caterpillar.png")]
        public static const caterpillar:Class;
        [Embed(source="/../assets/items/collections/animals/cow.png")]
        public static const cow:Class;
        [Embed(source="/../assets/items/collections/animals/dinosaur.png")]
        public static const dinosaur:Class;
        [Embed(source="/../assets/items/collections/animals/dove.png")]
        public static const dove:Class;
        [Embed(source="/../assets/items/collections/animals/duck.png")]
        public static const duck:Class;
        [Embed(source="/../assets/items/collections/animals/eagle.png")]
        public static const eagle:Class;
        [Embed(source="/../assets/items/collections/animals/elephant.png")]
        public static const elephant:Class;
        [Embed(source="/../assets/items/collections/animals/fish.png")]
        public static const fish:Class;
        [Embed(source="/../assets/items/collections/animals/frog.png")]
        public static const frog:Class;
        [Embed(source="/../assets/items/collections/animals/giraffe.png")]
        public static const giraffe:Class;
        [Embed(source="/../assets/items/collections/animals/gorilla.png")]
        public static const gorilla:Class;
        [Embed(source="/../assets/items/collections/animals/hamster.png")]
        public static const hamster:Class;
        [Embed(source="/../assets/items/collections/animals/hawk.png")]
        public static const hawk:Class;
        [Embed(source="/../assets/items/collections/animals/hedgehog.png")]
        public static const hedgehog:Class;
        [Embed(source="/../assets/items/collections/animals/jellyfish.png")]
        public static const jellyfish:Class;
        [Embed(source="/../assets/items/collections/animals/koala.png")]
        public static const koala:Class;
        [Embed(source="/../assets/items/collections/animals/lemur.png")]
        public static const lemur:Class;
        [Embed(source="/../assets/items/collections/animals/lion.png")]
        public static const lion:Class;
        [Embed(source="/../assets/items/collections/animals/lion_cub.png")]
        public static const lion_cub:Class;
        [Embed(source="/../assets/items/collections/animals/lizard.png")]
        public static const lizard:Class;
        [Embed(source="/../assets/items/collections/animals/lizard_spotted.png")]
        public static const lizard_spotted:Class;
        [Embed(source="/../assets/items/collections/animals/mammoth.png")]
        public static const mammoth:Class;
        [Embed(source="/../assets/items/collections/animals/monkey.png")]
        public static const monkey:Class;
        [Embed(source="/../assets/items/collections/animals/mouse.png")]
        public static const mouse:Class;
        [Embed(source="/../assets/items/collections/animals/peacock.png")]
        public static const peacock:Class;
        [Embed(source="/../assets/items/collections/animals/penguin.png")]
        public static const penguin:Class;
        [Embed(source="/../assets/items/collections/animals/puppy.png")]
        public static const puppy:Class;
        [Embed(source="/../assets/items/collections/animals/red_panda.png")]
        public static const red_panda:Class;
        [Embed(source="/../assets/items/collections/animals/snail.png")]
        public static const snail:Class;
        [Embed(source="/../assets/items/collections/animals/snake.png")]
        public static const snake:Class;
        [Embed(source="/../assets/items/collections/animals/spider.png")]
        public static const spider:Class;
        [Embed(source="/../assets/items/collections/animals/tiger.png")]
        public static const tiger:Class;
        [Embed(source="/../assets/items/collections/animals/turtle.png")]
        public static const turtle:Class;
        [Embed(source="/../assets/items/collections/animals/vulture.png")]
        public static const vulture:Class;
        [Embed(source="/../assets/items/collections/animals/wolf.png")]
        public static const wolf:Class;
        [Embed(source="/../assets/items/collections/animals/zebra.png")]
        public static const zebra:Class;
        
        [Embed(source="/../assets/items/collections/aliens/arctria.png")]
        public static const arctria:Class;
        [Embed(source="/../assets/items/collections/aliens/boofly.png")]
        public static const boofly:Class;
        [Embed(source="/../assets/items/collections/aliens/cawwie.png")]
        public static const cawwie:Class;
        [Embed(source="/../assets/items/collections/aliens/copper.png")]
        public static const copper:Class;
        [Embed(source="/../assets/items/collections/aliens/cyry.png")]
        public static const cyry:Class;
        [Embed(source="/../assets/items/collections/aliens/dripple.png")]
        public static const dripple:Class;
        [Embed(source="/../assets/items/collections/aliens/eecka.png")]
        public static const eecka:Class;
        [Embed(source="/../assets/items/collections/aliens/flarn.png")]
        public static const flarn:Class;
        [Embed(source="/../assets/items/collections/aliens/flobi.png")]
        public static const flobi:Class;
        [Embed(source="/../assets/items/collections/aliens/galeta.png")]
        public static const galeta:Class;
        [Embed(source="/../assets/items/collections/aliens/goo.png")]
        public static const goo:Class;
        [Embed(source="/../assets/items/collections/aliens/jellioops.png")]
        public static const jellioops:Class;
        [Embed(source="/../assets/items/collections/aliens/kerdoo.png")]
        public static const kerdoo:Class;
        [Embed(source="/../assets/items/collections/aliens/kisley.png")]
        public static const kisley:Class;
        [Embed(source="/../assets/items/collections/aliens/rawrgon.png")]
        public static const rawrgon:Class;
        [Embed(source="/../assets/items/collections/aliens/sleesh.png")]
        public static const sleesh:Class;
        [Embed(source="/../assets/items/collections/aliens/sponky.png")]
        public static const sponky:Class;
        [Embed(source="/../assets/items/collections/aliens/spugsy.png")]
        public static const spugsy:Class;
        [Embed(source="/../assets/items/collections/aliens/thort.png")]
        public static const thort:Class;
        [Embed(source="/../assets/items/collections/aliens/voya.png")]
        public static const voya:Class;
        [Embed(source="/../assets/items/collections/aliens/wippo.png")]
        public static const wippo:Class;
        [Embed(source="/../assets/items/collections/aliens/zuzu.png")]
        public static const zuzu:Class;
        
        [Embed(source="/../assets/items/collections/food/apple.png")]
        public static const apple:Class;
        [Embed(source="/../assets/items/collections/food/banana.png")]
        public static const banana:Class;
        [Embed(source="/../assets/items/collections/food/birthday_cake.png")]
        public static const birthday_cake:Class;
        [Embed(source="/../assets/items/collections/food/broccoli.png")]
        public static const broccoli:Class;
        [Embed(source="/../assets/items/collections/food/candy.png")]
        public static const candy:Class;
        [Embed(source="/../assets/items/collections/food/cheese.png")]
        public static const cheese:Class;
        [Embed(source="/../assets/items/collections/food/cookie.png")]
        public static const cookie:Class;
        [Embed(source="/../assets/items/collections/food/cotton_candy.png")]
        public static const cotton_candy:Class;
        [Embed(source="/../assets/items/collections/food/cupcake.png")]
        public static const cupcake:Class;
        [Embed(source="/../assets/items/collections/food/dog_biscuit.png")]
        public static const dog_biscuit:Class;
        [Embed(source="/../assets/items/collections/food/mushroom.png")]
        public static const mushroom:Class;
        [Embed(source="/../assets/items/collections/food/popcorn.png")]
        public static const popcorn:Class;
        [Embed(source="/../assets/items/collections/food/pretzel.png")]
        public static const pretzel:Class;
        [Embed(source="/../assets/items/collections/food/pumpkin.png")]
        public static const pumpkin:Class;
        [Embed(source="/../assets/items/collections/food/steak.png")]
        public static const steak:Class;
        [Embed(source="/../assets/items/collections/food/watermelon.png")]
        public static const watermelon:Class;
        
        [Embed(source="/../assets/items/collections/medieval/adventurer.png")]
        public static const adventurer:Class;
        [Embed(source="/../assets/items/collections/medieval/drawing_castle_night.png")]
        public static const drawing_castle_night:Class;
        [Embed(source="/../assets/items/collections/medieval/drawing_medieval_forest.png")]
        public static const drawing_medieval_forest:Class;
        [Embed(source="/../assets/items/collections/medieval/drawing_medieval_treasure.png")]
        public static const drawing_medieval_treasure:Class;
        [Embed(source="/../assets/items/collections/medieval/drawing_tomes.png")]
        public static const drawing_tomes:Class;
        [Embed(source="/../assets/items/collections/medieval/knight.png")]
        public static const knight:Class;
        [Embed(source="/../assets/items/collections/medieval/princess.png")]
        public static const princess:Class;
        [Embed(source="/../assets/items/collections/medieval/sword.png")]
        public static const sword:Class;
        
        [Embed(source="/../assets/items/collections/misc/bush.png")]
        public static const bush:Class;
        [Embed(source="/../assets/items/collections/misc/dog_toy.png")]
        public static const dog_toy:Class;
        [Embed(source="/../assets/items/collections/misc/feather.png")]
        public static const feather:Class;
        [Embed(source="/../assets/items/collections/misc/locket.png")]
        public static const locket:Class;
        [Embed(source="/../assets/items/collections/misc/ribbons.png")]
        public static const ribbons:Class;
        [Embed(source="/../assets/items/collections/misc/rope.png")]
        public static const rope:Class;
        [Embed(source="/../assets/items/collections/misc/tree.png")]
        public static const tree:Class;
        
        [Embed(source="/../assets/items/collections/mythic_creatures/dragon_green.png")]
        public static const dragon_green:Class;
        [Embed(source="/../assets/items/collections/mythic_creatures/dragon_red.png")]
        public static const dragon_red:Class;
        [Embed(source="/../assets/items/collections/mythic_creatures/elf.png")]
        public static const elf:Class;
        [Embed(source="/../assets/items/collections/mythic_creatures/fairy.png")]
        public static const fairy:Class;
        [Embed(source="/../assets/items/collections/mythic_creatures/monster.png")]
        public static const monster:Class;
        [Embed(source="/../assets/items/collections/mythic_creatures/pegasus.png")]
        public static const pegasus:Class;
        [Embed(source="/../assets/items/collections/mythic_creatures/sea_sprite.png")]
        public static const sea_sprite:Class;
        [Embed(source="/../assets/items/collections/mythic_creatures/troll.png")]
        public static const troll:Class;
        [Embed(source="/../assets/items/collections/mythic_creatures/troll_forest.png")]
        public static const troll_forest:Class;
        [Embed(source="/../assets/items/collections/mythic_creatures/troll_mountain.png")]
        public static const troll_mountain:Class;
        [Embed(source="/../assets/items/collections/mythic_creatures/unicorn.png")]
        public static const unicorn:Class;
        
        [Embed(source="/../assets/items/collections/space/alien.png")]
        public static const alien:Class;
        [Embed(source="/../assets/items/collections/space/martian.png")]
        public static const martian:Class;
        [Embed(source="/../assets/items/collections/space/moon.png")]
        public static const moon:Class;
        [Embed(source="/../assets/items/collections/space/moon_craft.png")]
        public static const moon_craft:Class;
        [Embed(source="/../assets/items/collections/space/pedrie.png")]
        public static const pedrie:Class;
        [Embed(source="/../assets/items/collections/space/plutonian.png")]
        public static const plutonian:Class;
        [Embed(source="/../assets/items/collections/space/rock.png")]
        public static const rock:Class;
        [Embed(source="/../assets/items/collections/space/space_ship.png")]
        public static const space_ship:Class;
        
        // Custom mouse cursors
        [Embed(source="/../assets/items/collections/cursors/blue_fire_cursor.png")]
        public static const blue_fire_cursor:Class;
        [Embed(source="/../assets/items/collections/cursors/frog_cursor.png")]
        public static const frog_cursor:Class;
        [Embed(source="/../assets/items/collections/cursors/leaf_cursor.png")]
        public static const leaf_cursor:Class;
        [Embed(source="/../assets/items/collections/cursors/shovel_cursor.png")]
        public static const shovel_cursor:Class;
        [Embed(source="/../assets/items/collections/cursors/spaceship_cursor.png")]
        public static const spaceship_cursor:Class;
        [Embed(source="/../assets/items/collections/cursors/swirl_cursor.png")]
        public static const swirl_cursor:Class;
        [Embed(source="/../assets/items/collections/cursors/yellow_fire_cursor.png")]
        public static const yellow_fire_cursor:Class;
        
        
        public function EmbeddedLevelSelectResources()
        {
            super();
        }
    }
}