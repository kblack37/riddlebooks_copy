package wordproblem.summary;


import flash.text.TextFormat;

import cgs.internationalization.StringTable;

import dragonbox.common.util.XTextField;

import starling.animation.Juggler;
import starling.animation.Transitions;
import starling.animation.Tween;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.engine.objectives.BaseObjective;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.resource.AssetManager;

/**
 * This display renders the list of goals that could be achieved in the level
 */
class SummaryObjectivesWidget extends Sprite
{
    private var m_assetManager : AssetManager;
    
    /**
     * List of objectives are pasted on top of here
     */
    private var m_objectivesListContainer : Sprite;
    
    /**
     * This juggler is used to play all the animations
     */
    private var m_juggler : Juggler;
    
    private var m_tweensInstantiated : Array<Tween>;
    
    /**
     * While all the objectives are animating we need to keep track of which one is animating.
     */
    private var m_currentObjectiveIndexAnimating : Int;
    
    /*
    Since the animations can be cancelled, we need some way to piece together the display
    objects
    */
    
    private var m_displayWithoutMarksBuffer : Array<Sprite>;
    private var m_checkMarkBuffer : Array<DisplayObject>;
    
    /**
     * Used to make sure the objective description text fits in the ui box
     */
    private var m_measuringTextField : MeasuringTextField;
    
    public function new(assetManager : AssetManager, juggler : Juggler)
    {
        super();
        m_assetManager = assetManager;
        m_juggler = juggler;
        m_tweensInstantiated = new Array<Tween>();
        
        var objectivesTitle : TextField = new TextField(270, 60, StringTable.lookup("goals"), GameFonts.DEFAULT_FONT_NAME, 36, 0xFFFFFF);
        this.addChild(objectivesTitle);
        
        m_objectivesListContainer = new Sprite();
        m_objectivesListContainer.x = 0;
        m_objectivesListContainer.y = objectivesTitle.height;
        this.addChild(m_objectivesListContainer);
        
        m_displayWithoutMarksBuffer = new Array<Sprite>();
        m_checkMarkBuffer = new Array<DisplayObject>();
        m_measuringTextField = new MeasuringTextField();
        m_measuringTextField.wordWrap = true;
        m_measuringTextField.embedFonts = true;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        this.clear();
    }
    
    public function clear() : Void
    {
        m_objectivesListContainer.removeChildren(0, -1, true);
        
        while (m_tweensInstantiated.length > 0)
        {
            m_juggler.remove(m_tweensInstantiated.pop());
        }
    }
    
    /**
     *
     * @param onSingleObjectiveAnimationComplete
     *      Called when a single objective is done animating
     *      Signature callback(objective:BaseObjective, objectiveDisplay:DisplayObject):void
     * @param onAnimationComplete
     *      Called when all objectives are done animating
     *      Signature callback():void
     */
    public function animateObjectives(objectives : Array<BaseObjective>,
            onSingleObjectiveAnimationComplete : Function,
            onAnimationComplete : Function) : Void
    {
        /*
        For each objective start by drawing the outlines and description
        Once that tween is complete
        
        The offset need to be determined beforehand. Need to calculate positions at the start
        Need to be able to interrupt the tween.
        Thus there needs to be a routine to piece together all the parts one by one
        */
        as3hx.Compat.setArrayLength(m_displayWithoutMarksBuffer, 0);
        as3hx.Compat.setArrayLength(m_checkMarkBuffer, 0);
        
        var objectiveYOffset : Float = 0;
        var numObjectives : Int = objectives.length;
        var i : Int;
        for (i in 0...numObjectives){
            // Get all the pieces need to contruct the objective display and
            // perform a preliminary layout
            var objective : BaseObjective = objectives[i];
            var objectiveDisplayWithoutMark : Sprite = getObjectiveDisplayWithoutMark(objective);
            m_displayWithoutMarksBuffer.push(objectiveDisplayWithoutMark);
            
            // Figure out at the start where the completion mark should go
            var checkboxDisplay : DisplayObject = objectiveDisplayWithoutMark.getChildAt(1);
            var completionMark : DisplayObject = getObjectiveDisplayMark(objective, checkboxDisplay);
            completionMark.x = checkboxDisplay.x + checkboxDisplay.width * 0.5;
            completionMark.y = checkboxDisplay.y + checkboxDisplay.height * 0.5;
            m_checkMarkBuffer.push(completionMark);
            
            // Later we sequence everything so that they animate correctly
            // Get the object at the current index
            objectiveDisplayWithoutMark.y = objectiveYOffset;
            objectiveYOffset += objectiveDisplayWithoutMark.height;
        }
        
        if (numObjectives > 0) 
        {
            // Reset current index to be the start
            m_currentObjectiveIndexAnimating = 0;
            animateObjective(m_displayWithoutMarksBuffer[0], m_checkMarkBuffer[0], onAnimateObjectiveComplete);
        }
        else 
        {
            onAnimationComplete();
        }
        
        function onAnimateObjectiveComplete() : Void
        {
            onSingleObjectiveAnimationComplete(
                    objectives[m_currentObjectiveIndexAnimating], m_displayWithoutMarksBuffer[m_currentObjectiveIndexAnimating]);
            m_currentObjectiveIndexAnimating++;
            if (m_currentObjectiveIndexAnimating >= objectives.length) 
            {
                // All objectives are done animating, can send another signal
                // so other widgets can continue in their animations
                onAnimationComplete();
            }
            else 
            {
                animateObjective(m_displayWithoutMarksBuffer[m_currentObjectiveIndexAnimating],
                        m_checkMarkBuffer[m_currentObjectiveIndexAnimating],
                        onAnimateObjectiveComplete);
            }
        };
    }
    
    /**
     * The animation takes in preconstructed parts
     */
    private function animateObjective(objectiveDisplayWithoutMark : Sprite, completionMark : DisplayObject, completeCallback : Function) : Void
    {
        // Animate the description
        var fadeInTween : Tween = new Tween(objectiveDisplayWithoutMark, 0.5);
        objectiveDisplayWithoutMark.alpha = 0.0;
        fadeInTween.fadeTo(1.0);
        fadeInTween.onComplete = function() : Void
                {
                    // On complete the check box should get a symbol, a check or an x to indicate completion
                    // (or just be left blank)
                    // Animate that symbol popping in if it exists
                    if (completionMark == null) 
                    {
                        if (completeCallback != null) 
                        {
                            completeCallback();
                        }
                    }
                    else 
                    {
                        var checkboxDisplay : DisplayObject = objectiveDisplayWithoutMark.getChildAt(1);
                        objectiveDisplayWithoutMark.addChild(completionMark);
                        
                        var popInTween : Tween = new Tween(completionMark, 0.3, Transitions.EASE_OUT_ELASTIC);
                        var originalScale : Float = completionMark.scaleX;
                        completionMark.scaleX = completionMark.scaleY = 5.0;
                        popInTween.scaleTo(originalScale);
                        completionMark.alpha = 0.4;
                        popInTween.fadeTo(1.0);
                        popInTween.onComplete = function() : Void
                                {
                                    if (completeCallback != null) 
                                    {
                                        completeCallback();
                                    }
                                };
                        m_tweensInstantiated.push(popInTween);
                        m_juggler.add(popInTween);
                    }
                };
        m_tweensInstantiated.push(fadeInTween);
        m_juggler.add(fadeInTween);
        
        m_objectivesListContainer.addChild(objectiveDisplayWithoutMark);
    }
    
    private function getObjectiveDisplayWithoutMark(objective : BaseObjective) : Sprite
    {
        var objectiveDisplay : Sprite = new Sprite();
        
        // Display has a limiting max width
        var totalObjectiveWidth : Float = 270;
        var totalObjectiveHeight : Float = 90;
        
        var outlineTexture : Texture = m_assetManager.getTexture("chalk_outline");
        var outline : Image = new Image(outlineTexture);
        outline.width = totalObjectiveWidth;
        outline.height = totalObjectiveHeight;
        objectiveDisplay.addChild(outline);
        
        var checkboxHorizontalPadding : Float = 20;
        var checkboxWidth : Float = 40;
        var checkbox : Image = new Image(outlineTexture);
        checkbox.x = checkboxHorizontalPadding;
        checkbox.y = (totalObjectiveHeight - checkboxWidth) * 0.5;
        checkbox.width = checkboxWidth;
        checkbox.height = checkboxWidth;
        objectiveDisplay.addChild(checkbox);
        
        // Since starling textfield has no word wrap, we use the normal flash text and then convert it
        // into a starling texture
        var maxTextWidth : Float = totalObjectiveWidth - checkboxWidth - checkboxHorizontalPadding - checkbox.x - 10;
        var maxTextHeight : Float = totalObjectiveHeight - 20;
        var objectiveDescription : String = objective.getDescription();
        var objectiveTextFormat : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 26, 0xFFFFFF);
        m_measuringTextField.setTextFormat(objectiveTextFormat);
        var resizedFontSize : Float = m_measuringTextField.resizeToDimensions(maxTextWidth, maxTextHeight, objectiveDescription);
        objectiveTextFormat.size = resizedFontSize;
        
        var descriptionTextField : DisplayObject = XTextField.createWordWrapTextfield(objectiveTextFormat, objectiveDescription,
                maxTextWidth, maxTextHeight);
        descriptionTextField.x = checkbox.x + checkboxWidth + 20;
        descriptionTextField.y = 20;
        objectiveDisplay.addChild(descriptionTextField);
        
        return objectiveDisplay;
    }
    
    private function getObjectiveDisplayMark(objective : BaseObjective, checkboxDisplay : DisplayObject) : DisplayObject
    {
        // Do not show any mark if the objective is not completed
        // (recieved feedback that the red 'x' may be too discouraging
        var displayMark : DisplayObject = null;
        if (objective.getCompleted()) 
        {
            var completionTexture : Texture = m_assetManager.getTexture("correct");
            var completionImage : Image = new Image(completionTexture);
            completionImage.pivotX = completionTexture.width * 0.5;
            completionImage.pivotY = completionTexture.height * 0.5;
            displayMark = completionImage;
        }
        else 
        {
            displayMark = new Quad(1, 1, 0);
            displayMark.alpha = 0;
        }
        
        return displayMark;
    }
}
