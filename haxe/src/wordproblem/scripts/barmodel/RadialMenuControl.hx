package wordproblem.scripts.barmodel;


import flash.geom.Point;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.ui.MouseState;

import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.extensions.textureutil.TextureUtil;
import starling.textures.Texture;

import wordproblem.display.Layer;

/**
 * This class encompasses all the logic necessary to bring up a radial menu prompt
 */
class RadialMenuControl implements IDisposable
{
    /**
     * True if the radial menu is currently opened
     */
    public var isOpen : Bool;
    
    /**
     * Need to poll mouse state every frame to figure out what option in the menu is selected
     */
    private var m_mouseState : MouseState;
    
    private var m_mouseOverOptionCallback : Function;
    private var m_mouseOutOptionCallback : Function;
    private var m_clickCallback : Function;
    
    /**
     * Buffer storing mouse coordinates relative to the central point of the menu
     */
    private var m_localLocationBuffer : Point;
    
    /**
     * Buffer storing mouse coordinates relative to the global space
     */
    private var m_globalLocationBuffer : Point;
    
    /**
     * Main container holding all the display objects related to the radial menu.
     * The origin of this menu is at center of the circle.
     */
    private var m_radialMenuContainer : Layer;
    
    private var m_enabledGestures : Array<Bool>;
    
    /**
     * These are the background images for the segments that make up the
     * radial menu. These are dynamic textures that should be deleted each
     * time the menu is closed.
     */
    private var m_radialMenuSegments : Array<DisplayObject>;
    private var m_radialMenuSegmentsDisabled : Array<DisplayObject>;
    private var m_radialMenuSegmentsOver : Array<DisplayObject>;
    
    /**
     * External script is responsible for drawing each segment
     * 
     * Signature callback(optionIndex:int, rotation:Number, arcLength:Number, mode:String):DisplayObject
     * We need multiple version of the segment button for up, over, and disabled, which is passed
     * as the 'mode' string
     */
    private var m_drawSegment : Function;
    
    /**
     * Since external script knows how to draw each segment, it is also responsible
     * for properly disposing it
     * 
     * Signature callback(segment:DisplayObject, mode:String):void
     * 'mode' is passed so the script can identify the type of segment.
     */
    private var m_disposeSegment : Function;
    
    private var m_outerRadius : Float = 60;
    private var m_outerRadiusSq : Float;
    private var m_innerRadius : Float = 30;
    private var m_innerRadiusSq : Float;
    
    /**
     * When the radial menu is split into options, there are several lines that indicate the
     * angles in which the ring segments are separated.
     * 
     * Each pair of adjacent indices specify the radians that are the bounds of the segment.
     * The first and last value should be the same value, as it wraps back around
     * 
     * The pairs start at the segment aligned at the top and move clockwise.
     * Values range from zero, which is the positive horizontal axis to 2*Pi
     */
    private var m_separatingAngles : Array<Float>;
    
    /**
     * We need to keep track of the segment hit on the last frame
     * 
     * If less than zero then nothing was hit on the last frame.
     */
    private var m_hitSegmentIndexOnLastFrame : Int;
    
    /**
     * All the mouse related callbacks accept a single parameter that is the index of
     * the segment related to that mouse action.
     * The indices are ordered from the segment at the top that is aligned with the vertical
     * axis and increases going clockwise.
     * 
     * @param mouseOverOptionCallback
     *      Callback triggered whenver the user mouses into a new option
     * @param mouseOutOptionCallback
     *      Callback triggered whenever the user mouses out of an option
     * @param clickCallback
     *      Callback triggered whenever user clicks on an option, signature callback(optionIndex:int):void
     *      option index is negative in no valid option was selected
     */
    public function new(mouseState : MouseState,
            mouseOverOptionCallback : Function,
            mouseOutOptionCallback : Function,
            clickCallback : Function,
            drawSegment : Function = null,
            disposeSegment : Function = null)
    {
        m_mouseState = mouseState;
        m_mouseOverOptionCallback = mouseOverOptionCallback;
        m_mouseOutOptionCallback = mouseOutOptionCallback;
        m_clickCallback = clickCallback;
        m_drawSegment = ((drawSegment != null)) ? drawSegment : defaultDraw;
        m_disposeSegment = ((disposeSegment != null)) ? disposeSegment : defaultDispose;
        
        m_outerRadiusSq = m_outerRadius * m_outerRadius;
        m_innerRadiusSq = m_innerRadius * m_innerRadius;
        m_separatingAngles = new Array<Float>();
        m_radialMenuSegments = new Array<DisplayObject>();
        m_radialMenuSegmentsOver = new Array<DisplayObject>();
        m_radialMenuSegmentsDisabled = new Array<DisplayObject>();
        
        m_localLocationBuffer = new Point();
        m_globalLocationBuffer = new Point();
    }
    
    public function getRadialMenuContainer() : Sprite
    {
        return m_radialMenuContainer;
    }
    
    public function visit() : Void
    {
        var hitSegmentIndex : Int = -1;
        
        if (m_radialMenuContainer != null) 
        {
            
            // To detect mouse hits on the segment, we can just convert the mouse coordinates
            // from global to relative then convert that to polar coordinates.
            // The converted radius should fall within the inner and outer radius
            // theta should within the 'arms' constraining each segment.
            m_globalLocationBuffer.x = m_mouseState.mousePositionThisFrame.x;
            m_globalLocationBuffer.y = m_mouseState.mousePositionThisFrame.y;
            m_radialMenuContainer.globalToLocal(m_globalLocationBuffer, m_localLocationBuffer);
            var mouseRSq : Float = m_localLocationBuffer.x * m_localLocationBuffer.x + m_localLocationBuffer.y * m_localLocationBuffer.y;
            if (mouseRSq >= m_innerRadiusSq && mouseRSq <= m_outerRadiusSq) 
            {
                // We expect 0 rad to be the postive horizontal axis,
                // However, arctan only returns a range between -pi/2 and pi/2,
                // where as we need the range to be from 0 to pi*2
                var mouseTheta : Float = 0;
                if (m_localLocationBuffer.x == 0) 
                {
                    if (m_localLocationBuffer.y < 0) 
                    {
                        mouseTheta = (3 / 2) * Math.PI;
                    }
                    else 
                    {
                        mouseTheta = Math.PI * 0.5;
                    }
                }
                // Segments are indexed from 0 at the very top and then increase going clockwise
                else if (m_localLocationBuffer.y == 0) 
                {
                    if (m_localLocationBuffer.x < 0) 
                    {
                        mouseTheta = Math.PI;
                    }
                }
                else 
                {
                    // Depending on the quadrant the point is in, we need to shift
                    // over the angle so it fits in the range 0 to 2*pi
                    mouseTheta = Math.atan(m_localLocationBuffer.y / m_localLocationBuffer.x);
                    
                    if (m_localLocationBuffer.x < 0) 
                    {
                        mouseTheta += Math.PI;
                    }
                    else if (m_localLocationBuffer.x > 0 && m_localLocationBuffer.y < 0) 
                    {
                        mouseTheta += 2 * Math.PI;
                    }
                }
                
                
                
                if (m_separatingAngles.length >= 2) 
                {
                    var i : Int;
                    var numAngles : Int = m_separatingAngles.length - 1;
                    for (i in 0...numAngles){
                        // Note that there is the wrap around from 2*pi back to zero we need
                        // account for
                        var firstAngle : Float = m_separatingAngles[i];
                        var secondAngle : Float = m_separatingAngles[i + 1];
                        if (secondAngle < firstAngle) 
                        {
                            if (mouseTheta < secondAngle && mouseTheta > 0 ||
                                mouseTheta > firstAngle && mouseTheta < 2 * Math.PI) 
                            {
                                hitSegmentIndex = i;
                                break;
                            }
                        }
                        else if (mouseTheta > firstAngle && mouseTheta < secondAngle) 
                        {
                            hitSegmentIndex = i;
                            break;
                        }
                    }
                }
            }  // mouse out    // If the hit segment on the new frame doesn't exist then trigger a  
            
            
            
            
            
            if (m_hitSegmentIndexOnLastFrame != hitSegmentIndex && m_hitSegmentIndexOnLastFrame >= 0) 
            {
                if (m_enabledGestures[m_hitSegmentIndexOnLastFrame]) 
                {
                    m_radialMenuSegmentsOver[m_hitSegmentIndexOnLastFrame].removeFromParent();
                }
                
                m_mouseOutOptionCallback(m_hitSegmentIndexOnLastFrame);
            }  // If the hit segment on this frame is new then trigger a mouse in  
            
            
            
            if (m_hitSegmentIndexOnLastFrame != hitSegmentIndex && hitSegmentIndex >= 0) 
            {
                if (m_enabledGestures[hitSegmentIndex]) 
                {
                    m_radialMenuContainer.addChild(m_radialMenuSegmentsOver[hitSegmentIndex]);
                }
                
                m_mouseOverOptionCallback(hitSegmentIndex);
            }  // Check for click on a segment (this is the selection of an option)  
            
            
            
            if (m_mouseState.leftMousePressedThisFrame) 
            {
                if (hitSegmentIndex == -1) 
                {
                    m_clickCallback(hitSegmentIndex);
                }
            }
            else if (m_mouseState.leftMouseReleasedThisFrame) 
            {
                if (hitSegmentIndex >= 0) 
                {
                    m_clickCallback(hitSegmentIndex);
                }
            }
        }
        
        m_hitSegmentIndexOnLastFrame = hitSegmentIndex;
    }
    
    public function dispose() : Void
    {
    }
    
    // Need to include function that draws the radial menu from scratch
    // Needs to include textures for mouse over/down/disabled
    // so it looks ok
    public function open(enabledGestures : Array<Bool>,
            xLocation : Float,
            yLocation : Float,
            canvas : DisplayObjectContainer) : Void
    {
        m_enabledGestures = enabledGestures;
        as3hx.Compat.setArrayLength(m_separatingAngles, 0);
        as3hx.Compat.setArrayLength(m_radialMenuSegments, 0);
        m_radialMenuContainer = new Layer();
        
        /*
        The number of options determines how many times we need to slice the ring
        
        Need to figure out the central points of each sliced segment
        This is where the main icon or text should be anchored at for each segment
        
        We draw n slices which all start with orientation at 0 rad going clockwise.
        
        Regadless of the number of slices, it should always be the case that the first segment
        is anchored such that the middle of it is aligned with the vertical axis
        */
        var numOptions : Int = enabledGestures.length;
        var radPerSegment : Float = Math.PI * 2 / numOptions;
        var rotationOffset : Float = -Math.PI / 2 - radPerSegment / 2;
        m_separatingAngles.push((Math.PI * 3 - radPerSegment) * 0.5);
        var i : Int;
        for (i in 0...numOptions){
            // Need to draw and get back three versions of the image
            m_radialMenuSegments.push(m_drawSegment(i, rotationOffset, radPerSegment, "up"));
            m_radialMenuSegmentsOver.push(m_drawSegment(i, rotationOffset, radPerSegment, "over"));
            m_radialMenuSegmentsDisabled.push(m_drawSegment(i, rotationOffset, radPerSegment, "disabled"));
            
            // If gesture at that index is disabled then use the special disable graphic
            if (enabledGestures[i]) 
            {
                m_radialMenuContainer.addChild(m_radialMenuSegments[i]);
            }
            else 
            {
                m_radialMenuContainer.addChild(m_radialMenuSegmentsDisabled[i]);
            }
            
            rotationOffset += radPerSegment;
            
            var prevAngle : Float = m_separatingAngles[m_separatingAngles.length - 1];
            
            // Clamp so new angle does not exceed one revolutions
            var newAngle : Float = prevAngle + radPerSegment;
            if (newAngle > Math.PI * 2) 
            {
                newAngle -= Math.PI * 2;
            }
            m_separatingAngles.push(newAngle);
        }  // Position the radial menu  
        
        
        
        m_radialMenuContainer.x = xLocation;
        m_radialMenuContainer.y = yLocation;
        canvas.addChild(m_radialMenuContainer);
        
        m_radialMenuContainer.scaleX = m_radialMenuContainer.scaleY = 0.0;
        var popOpenTween : Tween = new Tween(m_radialMenuContainer, 0.4, Transitions.EASE_OUT);
        popOpenTween.scaleTo(1.0);
        popOpenTween.onComplete = function() : Void
                {
                    isOpen = true;
                };
        Starling.juggler.add(popOpenTween);
    }
    
    public function close() : Void
    {
        this.isOpen = false;
        
        var containerToDispose : Layer = m_radialMenuContainer;
        m_radialMenuContainer = null;
        var closeTween : Tween = new Tween(containerToDispose, 0.2);
        closeTween.scaleTo(0.0);
        closeTween.fadeTo(0.0);
        closeTween.onComplete = function() : Void
                {
                    
                    // Dispose of the resources
                    containerToDispose.removeChildren(0, -1);
                    containerToDispose.removeFromParent();
                    
                    // Need to properly dispose of all the elements in each list
                    // (Very important to do this since textures use up valuable graphics memory)
                    disposeSegments(m_radialMenuSegments, "up");
                    disposeSegments(m_radialMenuSegmentsOver, "over");
                    disposeSegments(m_radialMenuSegmentsDisabled, "disabled");
                    
                    function disposeSegments(segments : Array<DisplayObject>, mode : String) : Void
                    {
                        for (segment in segments)
                        {
                            m_disposeSegment(segment, mode);
                        }
                        
                        as3hx.Compat.setArrayLength(segments, 0);
                    };
                };
        Starling.juggler.add(closeTween);
    }
    
    // An external script is responsible for specifying the actual draw
    // The parameters it needs is arc length and rotation to apply to the slice
    // From these properties
    private function defaultDraw(optionIndex : Int, rotation : Float, arcLength : Float, mode : String) : DisplayObject
    {
        // Make sure each piece rotates around the center of the circle,
        // will make positioning them later easier
        var segmentTexture : Texture = null;
        if (mode == "up") 
        {
            segmentTexture = TextureUtil.getRingSegmentTexture(
                            m_innerRadius, m_outerRadius, 0, arcLength, true
                            );
        }
        else if (mode == "over") 
        {
            segmentTexture = TextureUtil.getRingSegmentTexture(
                            m_innerRadius, m_outerRadius, 0, arcLength, true, null, 0xFF0000
                            );
        }
        else 
        {
            segmentTexture = TextureUtil.getRingSegmentTexture(
                            m_innerRadius, m_outerRadius, 0, arcLength, true, null, 0xCCCCCC
                            );
        }
        
        var segmentImage : Image = new Image(segmentTexture);
        segmentImage.pivotX = segmentImage.pivotY = m_outerRadius;
        segmentImage.rotation = rotation;
        
        return segmentImage;
    }
    
    private function defaultDispose(segment : DisplayObject, mode : String) : Void
    {
        (try cast(segment, Image) catch(e:Dynamic) null).texture.dispose();
        segment.dispose();
    }
}
