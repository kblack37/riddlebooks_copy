package wordproblem.scripts.barmodel;


import flash.geom.Rectangle;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import starling.animation.Juggler;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.textures.Texture;

import wordproblem.display.DottedRectangle;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.drag.WidgetDragSystem;

/**
 * The hit area script has to bind to another gesture script, which specifies the hit area location and size.
 * This script just draws that area.
 * 
 * For example the gesture to add new comparison, that script is responsible for drawing the hit
 * areas within the bar model ui that the player needs to interact with for that gesture to be applied.
 */
class ShowBarModelHitAreas extends BaseBarModelScript
{
    /**
     * This script has a dependency on the real add new segment script in order to sync up with the
     * actual hit areas
     */
    private var m_hitAreaScript : IHitAreaScript;
    
    /**
     * Are the hit areas at a shown state
     */
    private var m_hitAreasShown : Bool;
    
    /**
     * The name of the node that will calculate the hit areas to show.
     */
    private var m_nodeIdToCalculateHitAreas : String;
    
    /**
     * Keep track of all hit area visualizations
     */
    private var m_displayedHitAreaImages : Array<DisplayObject>;
    
    /**
     * Buffered list to keep track of the containers to pass along to script so they
     * can apply additional effects
     */
    private var m_postProcessHitAreaBuffer : Array<DisplayObjectContainer>;
    
    private var m_animationJuggler : Juggler;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            nodeIdToCalculateHitAreas : String,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_hitAreasShown = false;
        m_nodeIdToCalculateHitAreas = nodeIdToCalculateHitAreas;
        m_displayedHitAreaImages = new Array<DisplayObject>();
        m_postProcessHitAreaBuffer = new Array<DisplayObjectContainer>();
        m_animationJuggler = Starling.current.juggler;
    }
    
    /**
     * Initializer if we want to use this script logic independent of the game engine blob
     */
    public function setParams(barModelArea : BarModelAreaWidget,
            widgetDragSystem : WidgetDragSystem,
            hitAreaScript : IHitAreaScript) : Void
    {
        m_barModelArea = barModelArea;
        m_widgetDragSystem = widgetDragSystem;
        m_hitAreaScript = hitAreaScript;
        m_ready = true;
    }
    
    override public function visit() : Int
    {
        if (m_ready && m_isActive) 
        {
            // Show hit area if the attached gesture for the frame says that it is okay
            // An example where a gesture would fail is if the user is already performing an action
            if (m_hitAreaScript.getShowHitAreasForFrame()) 
            {
                // If no other action is interrupting then we assume that the card is not is any hit area
                if (!m_hitAreasShown) 
                {
					m_postProcessHitAreaBuffer = new Array<DisplayObjectContainer>();
                    var hitAreaBackgroundTexture : Texture = m_assetManager.getTexture("wildcard.png");
                    var nineslicePadding : Int = 10;
                    var ninesliceGrid : Rectangle = new Rectangle(nineslicePadding, nineslicePadding, hitAreaBackgroundTexture.width - 2 * nineslicePadding, hitAreaBackgroundTexture.height - 2 * nineslicePadding);
                    var cornerTexture : Texture = m_assetManager.getTexture("dotted_line_corner.png");
                    var segmentTexture : Texture = m_assetManager.getTexture("dotted_line_segment.png");
                    
                    var hitAreas : Array<Rectangle> = m_hitAreaScript.getActiveHitAreas();
                    var i : Int = 0;
                    var hitArea : Rectangle = null;
                    var numHitAreas : Int = hitAreas.length;
                    for (i in 0...numHitAreas){
                        hitArea = hitAreas[i];
                        
                        var finalTransparency : Float = 0.25;
                        var dottedRectangle : DottedRectangle = new DottedRectangle(hitAreaBackgroundTexture, ninesliceGrid, 0.6, cornerTexture, segmentTexture);
                        dottedRectangle.resize(hitArea.width, hitArea.height, 5, 5);
                        dottedRectangle.x = hitArea.x;
                        dottedRectangle.y = hitArea.y;
                        m_barModelArea.addChild(dottedRectangle);
                        
                        // Animate the fading in of the hit boxes
                        dottedRectangle.alpha = 0.0;
                        var fadeInTween : Tween = new Tween(dottedRectangle, 0.4);
                        fadeInTween.fadeTo(finalTransparency);
                        fadeInTween.onComplete = function() : Void
                                {
                                    m_animationJuggler.remove(fadeInTween);
                                };
                        m_animationJuggler.add(fadeInTween);
                        
                        m_displayedHitAreaImages.push(dottedRectangle);
                        m_postProcessHitAreaBuffer.push(dottedRectangle);
                    }
                    m_hitAreaScript.postProcessHitAreas(hitAreas, m_postProcessHitAreaBuffer);
                    m_hitAreasShown = true;
                }
            }
            // Clear out the hit area images
            else if (m_hitAreasShown) 
            {
                reset();
            }
        }  // No notion of success with this script  
        
        return ScriptStatus.FAIL;
    }
    
    override public function reset() : Void
    {
        super.reset();
        
        // We take a reset call to indicate that the script was not visited on a frame
        // We delete all the hit area icons in this case since this means that the user activated
        // some preview and the icons serve to only cause more clutter
        if (m_hitAreasShown) 
        {
            m_hitAreasShown = false;
            
            while (m_displayedHitAreaImages.length > 0)
            {
                var hitAreaImage : DisplayObject = m_displayedHitAreaImages.pop();
                
                // Animate the fade out of the hit boxes
                var fadeOutTween : Tween = new Tween(hitAreaImage, 0.4);
                fadeOutTween.fadeTo(0.0);
                fadeOutTween.onCompleteArgs = [fadeOutTween, hitAreaImage];
                fadeOutTween.onComplete = function(targetTween : Tween, targetImage : DisplayObject) : Void
                        {
                            targetImage.removeFromParent(true);
                            m_animationJuggler.remove(targetTween);
                        };
                m_animationJuggler.add(fadeOutTween);
            }
        }
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_hitAreaScript = try cast(this.getNodeById(m_nodeIdToCalculateHitAreas), IHitAreaScript) catch(e:Dynamic) null;
    }
}
