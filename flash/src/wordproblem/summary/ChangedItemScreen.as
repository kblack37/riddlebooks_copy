package wordproblem.summary
{
    import cgs.internationalization.StringTable;
    
    import starling.animation.IAnimatable;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.MovieClip;
    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.textures.Texture;
    
    import wordproblem.engine.component.StageChangeAnimationComponent;
    import wordproblem.engine.component.TextureCollectionComponent;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.items.ItemDataSource;
    import wordproblem.levelselect.scripts.DrawItemsOnShelves;
    import wordproblem.resource.AssetManager;
    
    /**
     * Show a generic screen when an item, mostly likely the egg has changed to a new stage.
     * The item in question must have the GrowInStagesComponent
     * 
     */
    public class ChangedItemScreen extends Sprite
    {
        /**
         * We have a set of continuously playing tweens associated with each opened reward details.
         * We need to remove them immediately once the popup for that reward is dismissed.
         */
        private var m_rewardDetailsActiveTweens:Vector.<IAnimatable>;
        
        public function ChangedItemScreen(totalScreenWidth:Number, 
                                          totalScreenHeight:Number, 
                                          data:Object, 
                                          itemDataSource:ItemDataSource, 
                                          assetManager:AssetManager)
        {
            super();
            
            m_rewardDetailsActiveTweens = new Vector.<IAnimatable>();
            
            var itemId:String = data.id;
            var previousStageIndex:int = data.prevStage;
            var currentStageIndex:int = data.currentStage;
            var itemChangeText:TextField = new TextField(400, 60, StringTable.lookup("item_changing"), GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
            itemChangeText.x = (totalScreenWidth - itemChangeText.width) * 0.5;
            itemChangeText.y = totalScreenHeight * 0.15;
            addChild(itemChangeText);
            
            // Check if the item has an animation that should be played during the stage change
            var stageChangeAnimationComponent:StageChangeAnimationComponent = itemDataSource.getComponentFromEntityIdAndType(
                itemId,
                StageChangeAnimationComponent.TYPE_ID
            ) as StageChangeAnimationComponent;
            var textureCollectionComponent:TextureCollectionComponent = itemDataSource.getComponentFromEntityIdAndType(
                itemId, 
                TextureCollectionComponent.TYPE_ID
            ) as TextureCollectionComponent;
            if (stageChangeAnimationComponent != null)
            {
                var spriteSheetDataObject:Object = stageChangeAnimationComponent.animationObjectCollection[previousStageIndex];
                var rewardMovieClip:MovieClip = DrawItemsOnShelves.createSpriteSheetAnimatedView(spriteSheetDataObject, assetManager, 30, true);
               // m_itemTextureNamesUsedBuffer[spriteSheetDataObject.textureName] = true;
                
                // Need to take into account cropping if applicable, hidden dependency of the texture collection class
                // assume that transition animations use the same sprite sheet as the texture used to draw the item on the shelf
                var previousDataObject:Object = textureCollectionComponent.textureCollection[previousStageIndex];
                var offset:Number = 0;
                if (previousDataObject.hasOwnProperty("crop"))
                {
                    // HACK: Need to halve to take into account the pivotX
                    offset = previousDataObject.crop.x * -0.5;
                }
                
                rewardMovieClip.loop = false;
                rewardMovieClip.x = 400 + offset;
                rewardMovieClip.y = 265;
                rewardMovieClip.pause();
                addChild(rewardMovieClip);
                
                rewardMovieClip.play();
                addRewardDetailTween(rewardMovieClip);
            }
            else
            {
                var previousTextureName:String =  textureCollectionComponent.textureCollection[previousStageIndex].textureName;
                var previousTexture:Texture = assetManager.getTexture(previousTextureName);
                //m_itemTextureNamesUsedBuffer[previousTextureName] = false;
                var currentTextureName:String = textureCollectionComponent.textureCollection[currentStageIndex].textureName;
                var currentTexture:Texture = assetManager.getTexture(currentTextureName);
                //m_itemTextureNamesUsedBuffer[currentTextureName] = false;
                
                var previousStageImage:Image = new Image(previousTexture);
                previousStageImage.pivotX = previousTexture.width * 0.5;
                previousStageImage.pivotY = previousTexture.height * 0.5;
                previousStageImage.x = 400;
                previousStageImage.y = totalScreenHeight * 0.5;
                addChild(previousStageImage);
                
                var removePreviousImage:Tween = new Tween(previousStageImage, 0.5);
                removePreviousImage.animate("alpha", 0.0);
                removePreviousImage.animate("scaleX", 5.0);
                removePreviousImage.animate("scaleY", 5.0);
                removePreviousImage.delay = 0.2;
                removePreviousImage.onComplete = onRemoveComplete;
                addRewardDetailTween(removePreviousImage);
                
                var newStageImage:Image = new Image(currentTexture);
                newStageImage.pivotX = currentTexture.width * 0.5;
                newStageImage.pivotY = currentTexture.height * 0.5;
                newStageImage.x = 400;
                newStageImage.y = totalScreenHeight * 0.5;
                newStageImage.alpha = 0.0;
                newStageImage.scaleX = newStageImage.scaleY = 2.0;
                
                // The previous stage starts losing color and turns white before fading out
                // and being replaced by the new item image
                function onRemoveComplete():void
                {
                    var showNewImage:Tween = new Tween(newStageImage, 0.5);
                    showNewImage.animate("alpha", 1.0);
                    showNewImage.animate("scaleX", 1.0);
                    showNewImage.animate("scaleY", 1.0);
                    previousStageImage.removeFromParent();
                    addChild(newStageImage);
                    addRewardDetailTween(showNewImage);
                }
            }
            
            // Change the item to not hidden, marks user has seen it transform
            if (data.hasOwnProperty("hidden") && data.hidden)
            {
                data.hidden = false;
                data.dirty = true;
            }
        }
        
        override public function dispose():void
        {
            super.dispose();
            while (m_rewardDetailsActiveTweens.length > 0)
            {
                Starling.juggler.remove(m_rewardDetailsActiveTweens.pop());
            }
        }
        
        private function addRewardDetailTween(tween:IAnimatable):void
        {
            m_rewardDetailsActiveTweens.push(tween);
            Starling.juggler.add(tween);
        }
    }
}