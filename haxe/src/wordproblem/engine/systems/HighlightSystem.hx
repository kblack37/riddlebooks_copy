package wordproblem.engine.systems;


import dragonbox.common.util.XColor;
import motion.Actuate;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import wordproblem.display.PivotSprite;

import openfl.display.DisplayObject;
import openfl.display.Sprite;

import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.HighlightComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.resource.AssetManager;

// TODO: uncomment this once callout system is redesigned

/**
 * This is responsible for drawing a highlight that might animate on a display object
 */
class HighlightSystem extends BaseSystemScript
{
    /**
     * The primary texture representing the base highlight, only need to create this once
     * since all highlights will share this texture.
     */
    private var m_highlightBitmapData : BitmapData;
    
    private var m_boundsBuffer : Rectangle;
	
	private var m_scale9Rect : Rectangle;
    
    public function new(assetManager : AssetManager)
    {
        super("HighlightSystem");
        
        m_highlightBitmapData = assetManager.getBitmapData("halo");
        var scale9Delta : Float = 2;
        m_scale9Rect = new Rectangle(
            (m_highlightBitmapData.width - scale9Delta) * 0.5, 
            (m_highlightBitmapData.height - scale9Delta) * 0.5, 
            scale9Delta, 
            scale9Delta
        );
        
        m_boundsBuffer = new Rectangle();
    }
    
    override public function update(componentManager : ComponentManager) : Void
    {
        var highlightComponents : Array<Component> = componentManager.getComponentListForType(HighlightComponent.TYPE_ID);
        var numHighlightComponents : Int = highlightComponents.length;
        var highlightComponent : HighlightComponent = null;
        var i : Int = 0;
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
                        var viewIndex : Int = 0;
                        var childView : DocumentView = null;
                        var currentLineNumber : Int = -1;
                        var currentLineBounds : Rectangle = null;
                        var resultBounds : Rectangle = null;
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
                                } 
								
								// Start a new line with the current contents  
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
                        }  
						
						// The lines vector now contains a list of rectangles describing the outer bounds of  
						// each line relative to the document view. For each line we want to create a highlight 
                        // for it to paste on the document view  
                        var highlightLayer : Sprite = new Sprite();
                        var lineIndex : Int = 0;
                        for (lineIndex in 0...lineBounds.length){
                            resultBounds = lineBounds[lineIndex];
                            
                            var highlightBitmap : Bitmap = new Bitmap(m_highlightBitmapData);
                            highlightBitmap.width = Math.max(m_scale9Rect.width, resultBounds.width);
                            highlightBitmap.height = Math.max(m_scale9Rect.height, resultBounds.height);
                            highlightBitmap.x = resultBounds.x - (highlightBitmap.width - resultBounds.width) * 0.5;
                            highlightBitmap.y = resultBounds.y - (highlightBitmap.height - resultBounds.height) * 0.5;
							highlightBitmap.transform.colorTransform = XColor.rgbToColorTransform(highlightComponent.color);
                            
                            highlightLayer.addChildAt(highlightBitmap, 0);
                        }
                        
                        documentView.addChildAt(highlightLayer, 0);
                        highlightComponent.displayedHighlight = new PivotSprite();
						highlightComponent.displayedHighlight.addChild(highlightLayer);
                        addHighlightAnimation(highlightComponent);
                    }
                }
                else 
                {
                    // Only create the highlight if the root object is displayed and has some width and height
                    var renderView : DisplayObject = renderableComponent.view;
                    if (highlightComponent.displayedHighlight == null && renderView.stage != null) 
                    {
                        var highlightBitmap = new Bitmap(m_highlightBitmapData);
						highlightBitmap.transform.colorTransform = XColor.rgbToColorTransform(highlightComponent.color);
                        
                        // Add the highlight just below the object
                        var displayIndex : Int = renderView.parent.getChildIndex(renderView);
                        renderView.parent.addChildAt(highlightBitmap, Std.int(Math.max(0, displayIndex - 1)));
                        
                        highlightComponent.displayedHighlight = new PivotSprite();
						highlightComponent.displayedHighlight.addChild(highlightBitmap);
                        addHighlightAnimation(highlightComponent);
                    }
                    
                    if (highlightComponent.displayedHighlight != null) 
                    {
                        var highlightDisplay : PivotSprite = highlightComponent.displayedHighlight;
                        m_boundsBuffer = renderView.getBounds(renderView.parent);
                        
                        // Make sure the highlight also scales
                        m_boundsBuffer.inflate(20, 20);
                        highlightDisplay.width = Math.max(m_highlightBitmapData.width, m_boundsBuffer.width);
                        highlightDisplay.height = Math.max(m_highlightBitmapData.height, m_boundsBuffer.height);
                        
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
			var tween = Actuate.tween(highlightComponent.displayedHighlight, highlightComponent.animationPeriod, { alpha: 0.2 }).repeat().reverse();
        }
    }
}
