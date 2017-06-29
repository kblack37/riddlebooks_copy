package wordproblem.summary;


import starling.animation.IAnimatable;
import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.engine.component.NameComponent;
import wordproblem.engine.component.RewardIconComponent;
import wordproblem.engine.text.GameFonts;
import wordproblem.items.ItemDataSource;
import wordproblem.resource.AssetManager;

class NewItemScreen extends Sprite
{
    /**
     * We have a set of continuously playing tweens associated with each opened reward details.
     * We need to remove them immediately once the popup for that reward is dismissed.
     */
    private var m_rewardDetailsActiveTweens : Array<IAnimatable>;
    
    private var m_itemTextureName : String;
    private var m_assetManager : AssetManager;
    
    public function new(totalScreenWidth : Float,
            totalScreenHeight : Float,
            data : Dynamic,
            itemDataSource : ItemDataSource,
            assetManager : AssetManager)
    {
        super();
        
        m_rewardDetailsActiveTweens = new Array<IAnimatable>();
        m_assetManager = assetManager;
        
        var itemId : String = data.id;
        
        // Create tween of the burst rotating as a background element
        var burstPurpleTexture : Texture = assetManager.getTexture("burst_purple");
        var targetScale : Float = 450 / burstPurpleTexture.width;
        var burstPurpleImage : Image = new Image(burstPurpleTexture);
        burstPurpleImage.pivotX = burstPurpleTexture.width * 0.5;
        burstPurpleImage.pivotY = burstPurpleTexture.height * 0.5;
        burstPurpleImage.x = totalScreenWidth * 0.5;
        burstPurpleImage.y = totalScreenHeight * 0.5;
        addChild(burstPurpleImage);
        
        var burstPurpleScale : Tween = new Tween(burstPurpleImage, 0.5);
        burstPurpleScale.scaleTo(targetScale);
        addRewardDetailTween(burstPurpleScale);
        
        var burstPurpleTween : Tween = new Tween(burstPurpleImage, 20);
        burstPurpleTween.animate("rotation", -Math.PI * 2);
        burstPurpleTween.repeatCount = 0;
        addRewardDetailTween(burstPurpleTween);
        
        var rewardIconComponent : RewardIconComponent = try cast(itemDataSource.getComponentFromEntityIdAndType(itemId, RewardIconComponent.TYPE_ID), RewardIconComponent) catch(e:Dynamic) null;
        m_itemTextureName = rewardIconComponent.textureName;
        
        if (data.hidden) 
        {
            var presentContainer : Sprite = NewItemButton.createPresentContainer(data.presentColor, assetManager);
            presentContainer.pivotX = presentContainer.width * 0.5;
            presentContainer.pivotY = presentContainer.height * 0.5;
            presentContainer.x = totalScreenWidth * 0.5;
            presentContainer.y = totalScreenHeight * 0.5;
            addChild(presentContainer);
            
            // Squash the present vertically, then horizontally.
            // When it reshapes the lid flies off and the prize is revealed
            var squishDuration : Float = 0.3;
            var squishVerticalTween : Tween = new Tween(presentContainer, squishDuration);
            squishVerticalTween.delay = 0.4;
            squishVerticalTween.animate("scaleX", 0.6);
            squishVerticalTween.animate("scaleY", 1.4);
            squishVerticalTween.onComplete = function() : Void
                    {
                        var squishHorizontalTween : Tween = new Tween(presentContainer, squishDuration);
                        squishHorizontalTween.animate("scaleX", 1.4);
                        squishHorizontalTween.animate("scaleY", 0.6);
                        squishHorizontalTween.onComplete = function() : Void
                                {
                                    var squishNormalTween : Tween = new Tween(presentContainer, 0.1);
                                    squishNormalTween.animate("scaleX", 1.0);
                                    squishNormalTween.animate("scaleY", 1.0);
                                    squishNormalTween.onComplete = function() : Void
                                            {
                                                // At this the top part of the present should fly off
                                                // Change pivot so it rotates from the center
                                                var presentTop : DisplayObject = presentContainer.getChildAt(1);
                                                presentTop.pivotX = presentTop.width * 0.5;
                                                presentTop.pivotY = presentTop.height * 0.5;
                                                presentTop.x += presentTop.pivotX;
                                                presentTop.y += presentTop.pivotY;
                                                var presentTopMoveTween : Tween = new Tween(presentTop, 0.6);
                                                presentTopMoveTween.animate("rotation", Math.PI * 2);
                                                presentTopMoveTween.animate("alpha", 0.0);
                                                presentTopMoveTween.animate("scaleX", 0.5);
                                                presentTopMoveTween.animate("scaleY", 0.5);
                                                presentTopMoveTween.animate("y", presentTop.y - 200);
                                                presentTopMoveTween.animate("x", presentTop.x - 100);
                                                presentTopMoveTween.onComplete = function() : Void
                                                        {
                                                            presentContainer.removeFromParent(true);
                                                        };
                                                addRewardDetailTween(presentTopMoveTween);
                                                
                                                // Fade out the bottom part of the present
                                                var presentBottom : DisplayObject = presentContainer.getChildAt(0);
                                                var presentBottomFadeTween : Tween = new Tween(presentBottom, 0.6);
                                                presentBottomFadeTween.animate("alpha", 0.0);
                                                addRewardDetailTween(presentBottomFadeTween);
                                                
                                                // Finally reveal the item rewarded
                                                showItem();
                                                
                                                // Set the reward model data to now show the item with
                                                data.hidden = false;
                                                data.dirty = true;
                                            };
                                    addRewardDetailTween(squishNormalTween);
                                };
                        addRewardDetailTween(squishHorizontalTween);
                    };
            addRewardDetailTween(squishVerticalTween);
        }
        else 
        {
            showItem();
        }
        
        var newPrizeText : TextField = new TextField(300, 60, "New Prize!", GameFonts.DEFAULT_FONT_NAME, 48, 0xFFFFFF);
        newPrizeText.x = (totalScreenWidth - newPrizeText.width) * 0.5;
        newPrizeText.y = totalScreenHeight * 0.15;
        addChild(newPrizeText);
        
        // Item appears near the middle of the screen
        function showItem() : Void
        {
            // From the id of the item, get the name of the item and create an image
            var rewardIconTexture : Texture = assetManager.getTextureWithReferenceCount(m_itemTextureName);
            var itemImage : Image = new Image(rewardIconTexture);
            itemImage.pivotX = rewardIconTexture.width * 0.5;
            itemImage.pivotY = rewardIconTexture.height * 0.5;
            itemImage.x = totalScreenWidth * 0.5;
            itemImage.y = totalScreenHeight * 0.5;
            addChild(itemImage);
            
            var itemImagePopIn : Tween = new Tween(itemImage, 0.4, Transitions.EASE_IN_OUT);
            itemImage.scaleX = itemImage.scaleY = 0.0;
            itemImage.alpha = 0.5;
            var desiredScale : Float = 200 / rewardIconTexture.height;
            itemImagePopIn.animate("scaleX", desiredScale);
            itemImagePopIn.animate("scaleY", desiredScale);
            itemImagePopIn.animate("alpha", 1.0);
            itemImagePopIn.onComplete = function() : Void
                    {
                        // Have reward gently float up and down
                        var upDownTween : Tween = new Tween(itemImage, 1.0);
                        upDownTween.animate("y", itemImage.y - 10);
                        upDownTween.repeatCount = 0;
                        upDownTween.reverse = true;
                        addRewardDetailTween(upDownTween);
                    };
            addRewardDetailTween(itemImagePopIn);
            
            var nameComponent : NameComponent = try cast(itemDataSource.getComponentFromEntityIdAndType(itemId, NameComponent.TYPE_ID), NameComponent) catch(e:Dynamic) null;
            var prizeDescriptionText : TextField = new TextField(400, 60, nameComponent.name, GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
            prizeDescriptionText.pivotX = prizeDescriptionText.width * 0.5;
            prizeDescriptionText.x = 400;
            prizeDescriptionText.y = itemImage.y + 110;  // Need to make sure the description floats about the dismiss button, else it is hidden  
            prizeDescriptionText.alpha = 0.0;
            addChild(prizeDescriptionText);
            var textTween : Tween = new Tween(prizeDescriptionText, 0.7);
            textTween.animate("alpha", 1.0);
            addRewardDetailTween(textTween);
        };
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        while (m_rewardDetailsActiveTweens.length > 0)
        {
            Starling.juggler.remove(m_rewardDetailsActiveTweens.pop());
        }
        
        super.removeChildren(0, -1, true);
        
        // Delete the texture of the item
        m_assetManager.releaseTextureWithReferenceCount(m_itemTextureName);
    }
    
    private function addRewardDetailTween(tween : Tween) : Void
    {
        m_rewardDetailsActiveTweens.push(tween);
        Starling.juggler.add(tween);
    }
}
