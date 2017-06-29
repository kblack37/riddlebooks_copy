package wordproblem.engine.systems;


import flash.geom.Rectangle;

import feathers.display.Scale9Image;
import feathers.textures.Scale9Textures;

import starling.animation.Juggler;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Sprite;
import starling.textures.Texture;

import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.HighlightComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.resource.AssetManager;

/**
 * This is responsible for drawing a highlight that might animate on a display object
 */
class HighlightSystem extends BaseSystemScript
{
    private var m_highlightJuggler : Juggler;
    
    /**
     * The primary texture representing the base highlight, only need to create this once
     * since all highlights will share this texture.
     */
    private var m_highlightTexture : Scale9Textures;
    
    private var m_boundsBuffer : Rectangle;
    
    public function new(assetManager : AssetManager)
    {
        super("HighlightSystem");
        
        m_highlightJuggler = Starling.juggler;
        
        var highlightTexture : Texture = assetManager.getTexture("halo");
        var scale9Delta : Float = 2;
        m_highlightTexture = new Scale9Textures(highlightTexture, new Rectangle(
                (highlightTexture.width - scale9Delta) * 0.5, 
                (highlightTexture.height - scale9Delta) * 0.5, 
                scale9Delta, 
                scale9Delta, 
                ));
        
        m_boundsBuffer = new Rectangle();
    }
    
    override public function update(componentManager : ComponentManager) : Void
    {
        var highlightComponents : Array<Component> = componentManager.getComponentListForType(HighlightComponent.TYPE_ID);
        var numHighlightComponents : Int = highlightComponents.length;
        var highlightComponent : HighlightComponent;
        var i : Int;
        for (i in 0...numHighlightComponents){
            highlightComponent = try cast(highlightComponents[i], HighlightComponent) catch(e:Dynamic) null;
            
            var renderableComponent : RenderableComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                    highlightComponent.entityId,
                    RenderableComponent.TYPE_ID
                    ), RenderableComponent) catch(e:Dynamic) null;
            if (renderableComponent != null) 
            {
                // For document views we rely on a pill like texture to place behind the content
                if (Std.is(renderableComponent.view, DocumentView)) 
                {
                    var documentView : DocumentView = try cast(renderableComponent.view, DocumentView) catch(e:Dynamic) null;
                    if (highlightComponent.displayedHighlight == null) 
                    {
                        // A highlight needs to be able to span over multiple lines.
                        // We can do this by first understanding at the lowest level of a document view tree,
                        // the contents never breaks to another line.
                        var outChildViews : Array<DocumentView> = new Array<DocumentView>();
                        documentView.getDocumentViewLeaves(outChildViews);
                        var canvasToAddTo : Sprite = documentView;
                        var viewIndex : Int;
                        var childView : DocumentView;
                        var currentLineNumber : Int = -1;
                        var currentLineBounds : Rectangle = null;
                        var resultBounds : Rectangle;
                        var lineBounds : Array<Rectangle> = new Array<Rectangle>();
                        for (viewIndex in 0...outChildViews.length){
                            // Determine the bounding dimensions of the content of each line.
                            // This will give us the necessary data to draw the background.
                            childView = outChildViews[viewIndex];
                            resultBounds = childView.getBounds(canvasToAddTo);
                            if (childView.lineNumber > currentLineNumber) 
                            {
                                // Flush the previous contents
                                if (currentLineBounds != null) 
                                {
                                    lineBounds.push(currentLineBounds);
                                }  // Start a new line with the current contents  
                                
                                
                                
                                currentLineBounds = resultBounds;
                                currentLineNumber = childView.lineNumber;
                            }
                            else 
                            {
                                // Create a union of all the bounds on the same line
                                currentLineBounds = currentLineBounds.union(resultBounds);
                            }
                        }
                        
                        if (currentLineBounds != null) 
                        {
                            lineBounds.push(currentLineBounds);
                        }  // for it to paste on the document view    // each line relative to the document view. For each line we want to create a highlight    // The lines vector now contains a list of rectangles describing the outer bounds of  
                        
                        
                        
                        
                        
                        
                        
                        
                        var highlightLayer : Sprite = new Sprite();
                        var lineIndex : Int;
                        for (lineIndex in 0...lineBounds.length){
                            resultBounds = lineBounds[lineIndex];
                            
                            var highlightImage : Scale9Image = new Scale9Image(m_highlightTexture);
                            highlightImage.width = Math.max(m_highlightTexture.texture.width, resultBounds.width);
                            highlightImage.height = Math.max(m_highlightTexture.texture.height, resultBounds.height);
                            highlightImage.x = resultBounds.x - (highlightImage.width - resultBounds.width) * 0.5;
                            highlightImage.y = resultBounds.y - (highlightImage.height - resultBounds.height) * 0.5;
                            highlightImage.color = highlightComponent.color;
                            
                            highlightLayer.addChildAt(highlightImage, 0);
                        }
                        
                        documentView.addChildAt(highlightLayer, 0);
                        highlightComponent.displayedHighlight = highlightLayer;
                        addHighlightAnimation(highlightComponent);
                    }
                }
                else 
                {
                    // Only create the highlight if the root object is displayed and has some width and height
                    var renderView : DisplayObject = renderableComponent.view;
                    if (highlightComponent.displayedHighlight == null && renderView.stage != null) 
                    {
                        highlightImage = new Scale9Image(m_highlightTexture);
                        highlightImage.color = highlightComponent.color;
                        
                        // Add the highlight just below the object
                        var displayIndex : Int = renderView.parent.getChildIndex(renderView);
                        renderView.parent.addChildAt(highlightImage, Math.max(0, displayIndex - 1));
                        
                        highlightComponent.displayedHighlight = highlightImage;
                        addHighlightAnimation(highlightComponent);
                    }
                    
                    if (highlightComponent.displayedHighlight != null) 
                    {
                        var highlightDisplay : DisplayObject = highlightComponent.displayedHighlight;
                        renderView.getBounds(renderView.parent, m_boundsBuffer);
                        
                        // Make sure the highlight also scales
                        m_boundsBuffer.inflate(20, 20);
                        highlightDisplay.width = Math.max(m_highlightTexture.texture.width, m_boundsBuffer.width);
                        highlightDisplay.height = Math.max(m_highlightTexture.texture.height, m_boundsBuffer.height);
                        
                        // Center the image so it becomes easier later to reposition within the center of the anchor object
                        highlightDisplay.pivotX = highlightDisplay.width * 0.5;
                        highlightDisplay.pivotY = highlightDisplay.height * 0.5;
                        
                        // Move the highlight along with the anchored object, make sure it in the center
                        highlightDisplay.x = m_boundsBuffer.x + m_boundsBuffer.width * 0.5;
                        highlightDisplay.y = m_boundsBuffer.y + m_boundsBuffer.height * 0.5;
                    }
                }
            }
        }
    }
    
    private function addHighlightAnimation(highlightComponent : HighlightComponent) : Void
    {
        // Create a tween for the highlighting if the component specifies some time frame
        if (highlightComponent.animationPeriod > 0) 
        {
            var tween : Tween = new Tween(highlightComponent.displayedHighlight, highlightComponent.animationPeriod);
            tween.animate("alpha", 0.2);
            tween.repeatCount = 0;
            tween.reverse = true;
            m_highlightJuggler.add(tween);
            
            highlightComponent.juggler = m_highlightJuggler;
            highlightComponent.tween = tween;
        }
    }
}
