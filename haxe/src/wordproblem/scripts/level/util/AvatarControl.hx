package wordproblem.scripts.level.util;


import flash.geom.Rectangle;

import cgs.overworld.core.engine.avatar.AvatarCreator;
import cgs.overworld.core.engine.avatar.container.AvatarSpriteContainer;

import dragonbox.common.dispose.IDisposable;

import starling.display.Image;
import starling.textures.Texture;

import wordproblem.engine.constants.Direction;
import wordproblem.resource.FlashResourceUtil;

/**
 * This class wraps together all the data necessary to manage creation of special
 * avatar graphics within a level.
 */
class AvatarControl implements IDisposable
{
    private var m_avatarCreator : AvatarCreator;
    
    private var m_playerCostumes : Dynamic;
    
    public var shirtItemIds : Dynamic;
    public var headItemIds : Dynamic;
    
    public function new()
    {
        m_avatarCreator = new AvatarCreator();
        
        m_playerCostumes = {
                    ninja : {
                        hatId : 120,
                        shirtId : 109,

                    },
                    fairy : {
                        hatId : 110,
                        shirtId : 106,

                    },
                    superhero : {
                        hatId : 123,
                        shirtId : 103,

                    },
                    zombie : {
                        hatId : 143,
                        shirtId : 158,

                    },
                    mummy : {
                        hatId : 130,
                        shirtId : 152,

                    },
                    none : {
                        hatId : 0,
                        shirtId : 0,

                    },

                };
        
        shirtItemIds = {
                    ninjaSashBlack : 108,
                    ninjaSashWhite : 109,
                    jerseyGreen : 41,
                    jerseyBlue : 42,
                    superSuitGreen : 101,
                    superSuitRed : 102,
                    butterflyBlue : 107,
                    zombieShirt : 158,

                };
        
        headItemIds = {
                    defaultMaleHair : 14,
                    defaultFemaleHair : 56,
                    hatFairyBlue : 110,
                    hatFairyOrange : 111,
                    zombieHead : 143,
                    superheroMask : 123,

                };
    }
    
    public function getHatIdForCostumeId(costumeId : String) : Int
    {
        return Reflect.field(m_playerCostumes, costumeId).hatId;
    }
    
    public function getShirtIdForCostumeId(costumeId : String) : Int
    {
        return Reflect.field(m_playerCostumes, costumeId).shirtId;
    }
    
    /**
     * Clean up all the temp textures used for this character
     */
    public function dispose() : Void
    {
    }
    
    /**
     * (Warning need to remember to dispose the texture of old avatars no longer being used)
     */
    public function createAvatarImage(species : Int,
            earType : Int,
            color : Int,
            hatId : Int,
            shirtId : Int,
            expressionId : Int,
            animationCycle : Int,
            frameInAnimation : Int,
            avatarHeight : Float,
            canvasViewport : Rectangle,
            direction : Int) : Image
    {
        var avatar : AvatarSpriteContainer = try cast(m_avatarCreator.createAvatarFromParameters(
                avatarHeight,
                species,
                earType,
                color,
                shirtId,
                hatId
                ), AvatarSpriteContainer) catch(e:Dynamic) null;
        
        if (direction == Direction.NORTH) 
        {
            avatar.cycleFrameLeft();
        }
        else if (direction == Direction.SOUTH) 
        {
            avatar.cycleFrameRight();
        }
        else if (direction == Direction.WEST) 
        {
            avatar.cycleFrameRight();
            avatar.cycleFrameRight();
        }
        avatar.setAvatarBehavior(expressionId, animationCycle, 0, frameInAnimation);
        
        var avatarTexture : Texture = FlashResourceUtil.avatarDisplayToStarlingTexture(
                avatar,
                canvasViewport
                );
        return new Image(avatarTexture);
    }
}
