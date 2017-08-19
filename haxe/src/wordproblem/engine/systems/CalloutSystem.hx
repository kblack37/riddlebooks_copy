package wordproblem.engine.systems;


import openfl.geom.Rectangle;

import dragonbox.common.ui.MouseState;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;

import wordproblem.display.CustomCallout;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.resource.AssetManager;

// TODO: uncomment this once callout system is redesigned

/**
 * This system is responsible for drawing and updating various callout/tooltip
 * images to be displayed next to entities.
 * 
 * This can also act as a simplistic dialog system for characters in the game world
 * 
 * TODO: The behavior of the callout seems to be if the callout content is larger than the default background size,
 * the callout will stretch to fill in the dimension difference. However if the background is larger, then the
 * content gets stretched to fill in the empty space.
 * 
 * The auto background stretch is okay, however the resizing of content is not. Changing the size of the background
 * does not since it gets automatically overwritten by feathers. The work around is to add dummy padding around the content
 */
class CalloutSystem extends BaseSystemScript
{
    private var m_assetManager : AssetManager;
    private var m_calloutLayer : DisplayObjectContainer;
    
    // Note that some callout will close on a click.
    // Since we have no original way to hook into this event we need to remove such callouts as soon as
    // we detect the callout has been removed
    private var m_calloutIdsThatSelfClose : Array<String>;
    
    /**
     * Need this to detect clicks on the callouts if they have been configured to be dismissed
     */
    private var m_mouseState : MouseState;
    private var m_globalViewBoundsBuffer : Rectangle;
    
    public function new(assetManager : AssetManager,
            calloutLayer : DisplayObjectContainer,
            mouseState : MouseState)
    {
        super("CalloutSystem");
        
        m_assetManager = assetManager;
        setCalloutLayer(calloutLayer);
        
        m_calloutIdsThatSelfClose = new Array<String>();
        m_mouseState = mouseState;
        m_globalViewBoundsBuffer = new Rectangle();
    }
    
    /**
     * HACK:
     * The way callout works is that there is a global property that defines the parent display
     * container where callouts are added. This means that if we have multiple screens we switch between
     * that uses callouts, then we need to call this function to reset the correct layer whenever the
     * screen switch occurs otherwise callout will not have the right z-order.
     */
    public function setCalloutLayer(calloutLayer : DisplayObjectContainer) : Void
    {
        m_calloutLayer = calloutLayer;
        //PopUpManager.root = m_calloutLayer;
    }
    //
    //override public function update(componentManager : ComponentManager) : Void
    //{
        //m_calloutIdsThatSelfClose = new Array<String>();
        //
        //var calloutComponents : Array<Component> = componentManager.getComponentListForType(CalloutComponent.TYPE_ID);
        //var i : Int;
        //var calloutComponent : CalloutComponent;
        //var numCalloutComponents : Int = calloutComponents.length;
        //for (i in 0...numCalloutComponents){
            //calloutComponent = try cast(calloutComponents[i], CalloutComponent) catch(e:Dynamic) null;
            //
            //// Get the primary render object for the entity with the callout
            //// The callout will refer to this object
            //// There are many different types of renderers
            //if (componentManager.hasComponentType(RenderableComponent.TYPE_ID)) 
            //{
                //var renderComponent : RenderableComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                        //calloutComponent.entityId,
                        //RenderableComponent.TYPE_ID
                        //), RenderableComponent) catch(e:Dynamic) null;
                //if (renderComponent != null && renderComponent.view != null && renderComponent.view.parent != null) 
                //{
                    //if (calloutComponent.closeOnTouchOutside && calloutComponent.callout != null && calloutComponent.callout.parent == null) 
                    //{
                        //m_calloutIdsThatSelfClose.push(calloutComponent.entityId);
                    //}
                    //else 
                    //{
                        //drawCallout(calloutComponent, renderComponent.view);
                    //}
                    //
                    //if (calloutComponent.closeOnTouchInside && m_mouseState.leftMousePressedThisFrame &&
                        //calloutComponent.callout != null && calloutComponent.callout.stage != null) 
                    //{
                        //
                        //m_globalViewBoundsBuffer = calloutComponent.callout.getBounds(calloutComponent.callout.stage);
                        //if (m_globalViewBoundsBuffer.contains(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y)) 
                        //{
                            //calloutComponent.callout.close(false);
                            //m_calloutIdsThatSelfClose.push(calloutComponent.entityId);
                            //if (calloutComponent.closeCallback != null) 
                            //{
                                //calloutComponent.closeCallback();
                            //}
                        //}
                    //}
                //}
            //}
        //}  // attached to a parent    // We figure that a callout self-closed if it was bound to a component but was not    // Delete the callout components that were configured to self-close  
        //
        //
        //
        //
        //
        //
        //
        //var numCalloutIdsThatSelfClose : Int = m_calloutIdsThatSelfClose.length;
        //for (i in 0...numCalloutIdsThatSelfClose){
            //componentManager.removeComponentFromEntity(m_calloutIdsThatSelfClose[i], CalloutComponent.TYPE_ID);
        //}
    //}
    //
    ///**
     //* Show the callout anchored at the given view
     //*/
    //private function drawCallout(calloutComponent : CalloutComponent, view : DisplayObject) : Void
    //{
        //// Create a new callout if one did not exist OR current callout is not attached to the current view
        //if (calloutComponent.callout != null && calloutComponent.callout.parent == null) 
        //{
            //calloutComponent.callout.close(false);
            //calloutComponent.callout = null;
        //}  // The view the callout is anchored to must be part of the display hierarchy  
        //
        //
        //
        //if (calloutComponent.callout == null && view.stage != null) 
        //{
            //// Check if the size of the regular texture used for the background
            //var calloutContent : DisplayObject = calloutComponent.display;
            //if (calloutComponent.backgroundTexture != null) 
            //{
                //var needToCreateWrapper : Bool = false;
                //var fillWidth : Float = calloutContent.width;
                //var backgroundTexture : Texture = m_assetManager.getTexture(calloutComponent.backgroundTexture);
                //if (fillWidth < backgroundTexture.width) 
                //{
                    //needToCreateWrapper = true;
                    //fillWidth = backgroundTexture.width;
                //}
                //
                //var fillHeight : Float = calloutContent.height;
                //if (fillHeight < backgroundTexture.height) 
                //{
                    //needToCreateWrapper = true;
                    //fillHeight = backgroundTexture.height;
                //}
                //
                //if (needToCreateWrapper) 
                //{
                    //// Create a dummy quad to fill in all the gaps to prevent feathers from trying
                    //// to automatically scale the content.
                    //var calloutDummyContainer : Sprite = new Sprite();
                    //var dummyFillQuad : Quad = new Quad(fillWidth, fillHeight, 0);
                    //dummyFillQuad.alpha = 0.001;
                    //calloutDummyContainer.addChild(dummyFillQuad);
                    //
                    //// Make sure content is centered
                    //calloutContent.x = (fillWidth - calloutContent.width) * 0.5;
                    //calloutContent.y = (fillHeight - calloutContent.height) * 0.5;
                    //calloutDummyContainer.addChild(calloutContent);
                    //
                    //// The content is now a wrapper
                    //calloutContent = calloutDummyContainer;
                //}
            //}
            //
            //var callout : Callout = Callout.show(
                    //calloutContent,
                    //view,
                    //calloutComponent.directionFromOrigin,
                    //false,
                    //function calloutFactory() : Callout
                    //{
                        //var callout : CustomCallout = new CustomCallout();
                        //callout.xOffset = calloutComponent.xOffset;
                        //callout.yOffset = calloutComponent.yOffset;
                        //
                        //// Do not dispose content since we want to reuse it if the attached view changes
                        //// For example this occurs for the helper characters when they change animation cycles.
                        //callout.disposeContent = false;
                        //callout.closeOnTouchBeganInside = calloutComponent.closeOnTouchInside;
                        //callout.closeOnTouchBeganOutside = calloutComponent.closeOnTouchOutside;
                        //
                        //if (calloutComponent.backgroundTexture != null) 
                        //{
                            //var backgroundPadding : Float = 10;
                            //var backgroundTexture : Texture = m_assetManager.getTexture(calloutComponent.backgroundTexture);
                            //var background9Texture : Scale9Textures = new Scale9Textures(
                            //backgroundTexture, 
                            //new Rectangle(backgroundPadding, backgroundPadding, backgroundTexture.width - backgroundPadding * 2, backgroundTexture.height - backgroundPadding * 2)
                            //);
                            //
                            //var background9Image : Scale9Image = new Scale9Image(background9Texture);
                            //background9Image.color = calloutComponent.backgroundColor;
                            //callout.backgroundSkin = background9Image;
                            //
                            //background9Image.width = 60;
                            //background9Image.height = 60;
                        //}
                        //
                        //if (calloutComponent.arrowTexture != null) 
                        //{
                            //var arrowTexture : Texture = m_assetManager.getTexture("callout_arrow_top_white");
                            //
                            //var bottomArrow : Image = new Image(arrowTexture);
                            //bottomArrow.color = calloutComponent.backgroundColor;
                            //bottomArrow.rotation = Math.PI;
                            //bottomArrow.pivotX = arrowTexture.width;
                            //bottomArrow.pivotY = arrowTexture.height;
                            //callout.bottomArrowSkin = bottomArrow;
                            //
                            //var topArrow : Image = new Image(arrowTexture);
                            //topArrow.color = calloutComponent.backgroundColor;
                            //callout.topArrowSkin = topArrow;
                            //
                            //var rightArrow : Image = new Image(arrowTexture);
                            //rightArrow.color = calloutComponent.backgroundColor;
                            //rightArrow.rotation = Math.PI * 0.5;
                            //rightArrow.pivotY = arrowTexture.height;
                            //callout.rightArrowSkin = rightArrow;
                            //
                            //var leftArrow : Image = new Image(arrowTexture);
                            //leftArrow.color = calloutComponent.backgroundColor;
                            //leftArrow.rotation = -Math.PI * 0.5;
                            //leftArrow.pivotX = arrowTexture.width;
                            //callout.leftArrowSkin = leftArrow;
                        //}
                        //// Blend in arrow into part of the background by making arrow padding negative
                        //else if (calloutComponent.edgePadding > 0) 
                        //{
                            //// Draw an empty arrow, this is the only way to add some spacing between the background and the target display
                            //var defaultArrow : Quad = new Quad(calloutComponent.edgePadding, calloutComponent.edgePadding, 0);
                            //defaultArrow.alpha = 0.0;
                            //callout.bottomArrowSkin = defaultArrow;
                            //callout.topArrowSkin = defaultArrow;
                            //callout.rightArrowSkin = defaultArrow;
                            //callout.leftArrowSkin = defaultArrow;
                        //}
                        //
                        //
                        //
                        //callout.topArrowGap = callout.rightArrowGap = callout.bottomArrowGap = callout.leftArrowGap = calloutComponent.edgePadding;
                        //return callout;
                    //}
                    //);
            //
            //// Quickly fade in callout
            //callout.alpha = 0;
            //Starling.juggler.tween(callout, 0.5, {
                        //alpha : 1.0
//
                    //});
            //
            //// Add content padding to the bottom to prevent bleed over
            //callout.paddingBottom = calloutComponent.contentPadding;
            //
            //// Check if the arrow should be animated
            //// One gotcha is that the animation only works if we know beforehand which arrow will be used
            //var calloutDirection : String = calloutComponent.directionFromOrigin;
            //if (calloutDirection != Callout.DIRECTION_ANY && calloutComponent.arrowTexture != null && calloutComponent.arrowAnimationPeriod > 0.0) 
            //{
                //var tweenTarget : DisplayObject = null;
                //
                //// Direction of the tween depends on the callout direction
                //// Note the edgePadding property affects how far the arrow starts off from the callout body
                //// We assume tweening the arrow will move from the original position up to the body.
                //var deltaY : Float = 0;
                //var deltaX : Float = 0;
                //if (calloutDirection == Callout.DIRECTION_DOWN) 
                //{
                    //tweenTarget = callout.topArrowSkin;
                    //deltaY = callout.topArrowGap;
                //}
                //else if (calloutDirection == Callout.DIRECTION_LEFT) 
                //{
                    //tweenTarget = callout.rightArrowSkin;
                    //deltaX = -callout.rightArrowGap;
                //}
                //else if (calloutDirection == Callout.DIRECTION_RIGHT) 
                //{
                    //tweenTarget = callout.leftArrowSkin;
                    //deltaX = callout.leftArrowGap;
                //}
                //else 
                //{
                    //tweenTarget = callout.bottomArrowSkin;
                    //deltaY = calloutComponent.display.height;
                //}
                //
                //var arrowTween : Tween = new Tween(tweenTarget, calloutComponent.arrowAnimationPeriod * 0.5);
                //arrowTween.onComplete = onFinishTween;
                //arrowTween.reverse = true;
                //arrowTween.repeatCount = 0;
                //if (deltaY != 0) 
                //{
                    //arrowTween.animate("y", deltaY);
                //}
                //if (deltaX != 0) 
                //{
                    //arrowTween.animate("x", deltaX);
                //}
                //Starling.juggler.add(arrowTween);
                //calloutComponent.arrowAnimationTween = arrowTween;
            //}
            //
            //calloutComponent.callout = callout;
        //}
    //}
    //
    //private function onFinishTween(tween : Tween) : Void
    //{
        //Starling.juggler.remove(tween);
    //}
}
