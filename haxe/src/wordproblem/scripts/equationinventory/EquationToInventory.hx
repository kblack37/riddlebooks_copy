package wordproblem.scripts.equationinventory;


import flash.geom.Rectangle;
import starling.textures.Texture;
import wordproblem.engine.events.DataEvent;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentFactory;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.expression.widget.ExpressionTreeWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * A script to animate an two expressions joining together into an equation and then moving
 * into the inventory button. This should get triggered after each successful model.
 * 
 * For now this also handles directly adding an equation to a player's inventory after each successful model
 */
class EquationToInventory extends BaseGameScript
{
    private inline var m_moveExpressionsDuration : Float = 0.5;
    private inline var m_moveEquationDuration : Float = 0.5;
    
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager)
    {
        super(gameEngine, null, assetManager);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, onModeled);
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, onModeled);
    }
    
    private function onModeled(event : Dynamic) : Void
    {
        // Remember the equations that was modeled. The script needs to immediately add it later if we that
        // equation to go into the inventory.
		var args = (try cast(event, DataEvent) catch (e : Dynamic) null).getData();
        var modeledId : Int = args.id;
        var modeledExpression : String = args.equation;
        
        this.createItemEntity({
                    entityId : Std.string(modeledId),
                    components : [
                    {
                        typeId : ExpressionComponent.TYPE_ID,
                        data : {
                            equationString : modeledExpression
                        },
                    }, 
                    {
                        typeId : RenderableComponent.TYPE_ID,
                        data : { },
                    }],
                }
                );
        
        // Bail out of the animation if the inventory area is not present
        var inventoryArea : DisplayObject = m_gameEngine.getUiEntity("inventoryArea");
        if (inventoryArea != null && inventoryArea.parent != null) 
        {
            this.animateEquation();
        }  
		
		// Clear the modeling term area immediately of all contents  
        m_gameEngine.setTermAreaContent("leftTermArea rightTermArea", null);
    }
    
    /**
     * Create an entity to be added into the player's inventory set.
     * 
     * We distinguish items possessed by the player and items present in the gameworld.
     * 
     * (Formatting and field names for this need to be well documented)
     * 
     * @param data
     *      A json formatted object for the entity to create. Properties include
     *      id: String
     *      components: Array of component types bound to the item
     */
    private function createItemEntity(data : Dynamic) : Void
    {
        // TODO: There is a bug where the ordering of this in the script sequence matters, this
        // is probably because clearing the item component manager is somehow occuring after the
        // script sequence has started.
        var componentFactory : ComponentFactory = new ComponentFactory(m_compiler);
        
        var entityId : String = data.entityId;
        var components : Array<Dynamic> = data.components;
        var numComponents : Int = components.length;
        var i : Int = 0;
        var componentObject : Dynamic = null;
        for (i in 0...numComponents){
            componentObject = components[i];
            
            var componentToCreate : Component = componentFactory.createComponent(entityId, componentObject);
            if (componentToCreate != null) 
            {
                m_gameEngine.getItemComponentManager().addComponentToEntity(componentToCreate);
            }
        }
    }
    
    public function animateEquation() : Void
    {
        // Create a layer where the entire animation should take place
        // Need to be careful about not using the stage
        // Identify the locations of each term area and the equals buttons to initially layout the animating
        // objects
        // The expressions on the left and right side should pop out of the term areas and meet by the equals
        // button, once there they are joined together to form a new equation.
        // Finally the new equation moves down to the inventory button
        var boundsRectangle : Rectangle = new Rectangle();
        var equalsButton : DisplayObject = m_gameEngine.getUiEntity("modelEquationButton");
        var animationLayer : DisplayObjectContainer = equalsButton.parent.parent;
        
        boundsRectangle = equalsButton.getBounds(animationLayer);
        var leftTermStopEdge : Float = boundsRectangle.left;
        var rightTermStopEdge : Float = boundsRectangle.right;
        
        var leftTermArea : ExpressionTreeWidget = try cast(m_gameEngine.getUiEntity("leftTermArea"), ExpressionTreeWidget) catch(e:Dynamic) null;
        var leftTree : ExpressionTree = leftTermArea.getTree();
        var copyLeftTermArea : ExpressionTreeWidget = new ExpressionTreeWidget(
        leftTree, 
        m_gameEngine.getExpressionSymbolResources(), 
        m_assetManager, 
        leftTermArea.getConstraintsWidth(), 
        leftTermArea.getConstraintsHeight(), 
        true, 
        );
        boundsRectangle = leftTermArea.getBounds(animationLayer);
        copyLeftTermArea.x = boundsRectangle.x;
        copyLeftTermArea.y = boundsRectangle.y;
        animationLayer.addChild(copyLeftTermArea);
        
        var rightTermArea : ExpressionTreeWidget = try cast(m_gameEngine.getUiEntity("rightTermArea"), ExpressionTreeWidget) catch(e:Dynamic) null;
        var rightTree : ExpressionTree = rightTermArea.getTree();
        var copyRightTermArea : ExpressionTreeWidget = new ExpressionTreeWidget(
        rightTree, 
        m_gameEngine.getExpressionSymbolResources(), 
        m_assetManager, 
        rightTermArea.getConstraintsWidth(), 
        rightTermArea.getConstraintsHeight(), 
        true, 
        );
        boundsRectangle = rightTermArea.getBounds(animationLayer);
        copyRightTermArea.x = boundsRectangle.x;
        copyRightTermArea.y = boundsRectangle.y;
        animationLayer.addChild(copyRightTermArea);
        
        // Figure out the correct number of pixels to shift the term area copies such that they are
        // almost adjacent to each other
        // Need to get the tight bounds of the copies to figure out the correct shift amount.
        var copyLeftTightBounds : Rectangle = copyLeftTermArea.getBounds(animationLayer);
        var copyRightTightBounds : Rectangle = copyRightTermArea.getBounds(animationLayer);
        Starling.juggler.tween(copyLeftTermArea, m_moveExpressionsDuration, {
                    x : copyLeftTermArea.x + (leftTermStopEdge - copyLeftTightBounds.right),
                    onComplete : onExpressionsShifted,

                });
        Starling.juggler.tween(copyRightTermArea, m_moveExpressionsDuration, {
                    x : copyRightTermArea.x - (copyRightTightBounds.left - rightTermStopEdge),
                    onComplete : onExpressionsShifted,

                });
        
        // Shift the bounds over
        copyLeftTightBounds.x += leftTermStopEdge - copyLeftTightBounds.right;
        copyRightTightBounds.x = rightTermStopEdge;
        
        // Once the expressions are shifted paste them into a container with the background and equals sign
        var numShifted : Int = 0;
        function onExpressionsShifted() : Void
        {
            numShifted++;
            
            if (numShifted == 2) 
            {
                var backgroundBounds : Rectangle = copyLeftTightBounds.union(copyRightTightBounds);
                var scaleNineTexture : Texture = Texture.fromTexture(
					m_assetManager.getTexture("button_white"), 
					new Rectangle(10, 10, backgroundBounds.width - 10, backgroundBounds.height - 10));
                var scaleNineImage : Image = new Image(scaleNineTexture);
                scaleNineImage.color = 0x000000;
                scaleNineImage.width = backgroundBounds.width;
                scaleNineImage.height = backgroundBounds.height;
                var equationBackground : DisplayObject = scaleNineImage;
                
                // Create a container with the experssions and background to be tweened
                var equationContainer : Sprite = new Sprite();
                equationContainer.x = backgroundBounds.x;
                equationContainer.y = backgroundBounds.y;
                animationLayer.addChild(equationContainer);
                
                // Equals needs to be placed in between the two equation copies
                var equalsImage : Image = new Image(m_assetManager.getTexture("equal"));
                equalsImage.pivotX = equalsImage.width * 0.5;
                equalsImage.pivotY = equalsImage.height * 0.5;
                //equalsImage.x = backgroundBounds.width * 0.5;
                equalsImage.y = backgroundBounds.height * 0.5;
                
                // Readjust the position of the term areas to fit inside the container.
                boundsRectangle = copyLeftTermArea.getBounds(equationContainer);
                copyLeftTermArea.x += (boundsRectangle.x - copyLeftTightBounds.x);
                copyLeftTermArea.y += (boundsRectangle.y - copyLeftTightBounds.y);
                equalsImage.x = boundsRectangle.width;
                var leftEdge : Float = boundsRectangle.right;
                boundsRectangle = copyRightTermArea.getBounds(equationContainer);
                copyRightTermArea.x += (boundsRectangle.x - copyRightTightBounds.x);
                copyRightTermArea.y += (boundsRectangle.y - copyRightTightBounds.y);
                var rightEdge : Float = boundsRectangle.left;
                equalsImage.x += (rightEdge - leftEdge) * 0.5;
                
                
                equationContainer.addChild(equationBackground);
                equationContainer.addChild(equalsImage);
                equationContainer.addChild(copyLeftTermArea);
                equationContainer.addChild(copyRightTermArea);
                
                // Find the inventory button, this gives us the target location from which to move the equation image into
                var inventoryArea : DisplayObject = m_gameEngine.getUiEntity("inventoryArea");
                boundsRectangle = inventoryArea.getBounds(animationLayer);
                Starling.juggler.tween(equationContainer, m_moveEquationDuration, {
                            x : boundsRectangle.x,
                            y : boundsRectangle.y,
                            onComplete : function() : Void
                            {
                                // Dispose of all animation resources
                                equationContainer.removeFromParent(true);
                                copyLeftTermArea.dispose();
                                copyRightTermArea.dispose();
                                equalsImage.dispose();
                                equationBackground.dispose();
                            },

                        });
            }
        };
    }
}
