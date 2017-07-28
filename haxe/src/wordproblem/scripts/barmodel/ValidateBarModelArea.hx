package wordproblem.scripts.barmodel;


import flash.geom.Rectangle;

import cgs.audio.Audio;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.events.Event;
import starling.filters.ColorMatrixFilter;
import starling.textures.Texture;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.animation.ColorChangeAnimation;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.DecomposedBarModelData;
import wordproblem.engine.events.GameEvent;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;

/**
 * This script handles validation tests that can performed on the bar modeling widget
 */
class ValidateBarModelArea extends BaseBarModelScript
{
    /**
     * A vector of reference bar models, derived from level xml spec, against which to test for validation.
     */
    private var m_referenceBarModels : Array<BarModelData>;
    
    /**
     * Add another layer of validation that enforces proportion checking on labels and segments.
     * Use these objects to compare to player model for extra strictness.
     * The decomposed model for the reference models only needs to be computed once when the reference models
     * are first assigned.
     */
    private var m_decomposedReferenceBarModels : Array<DecomposedBarModelData>;
    
    /**
     * Links to the reference model list, each value here is a flag indicating whether the
     * reference model at the same index has been solved.
     */
    private var m_referenceBarModelValidated : Array<Bool>;
    
    /**
     * The button when pressed that should trigger the validation
     */
    private var m_validateButton : DisplayObject;
    
    /**
     * Used to flash the background of the bar model area a different color when a validation
     * is correct or incorrect
     */
    private var m_colorChangeAnimation : ColorChangeAnimation;
    
    /**
     * Key: name of an alias term value
     * Value: the original term value
     * 
     * Multiple aliases might map to one original value
     */
    private var m_aliasValueToTermMap : Dynamic;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true,
            hints : Dynamic = null)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        m_referenceBarModels = new Array<BarModelData>();
        m_decomposedReferenceBarModels = new Array<DecomposedBarModelData>();
        m_referenceBarModelValidated = new Array<Bool>();
        m_colorChangeAnimation = new ColorChangeAnimation();
        m_aliasValueToTermMap = { };
    }
    
    public function getReferenceModels() : Array<BarModelData>
    {
        return m_referenceBarModels;
    }
    
    public function getDecomposedReferenceModels() : Array<DecomposedBarModelData>
    {
        return m_decomposedReferenceBarModels;
    }
    
    public function getAliasValuesToTerms() : Dynamic
    {
        return m_aliasValueToTermMap;
    }
    
    public function clearAliases() : Void
    {
        m_aliasValueToTermMap = { };
    }
    
    /**
     * For tutorial levels we have situations where the bar model to create allows the player to pick any option
     * for something like a new segment or a label.
     * 
     * For example, the player have 5 choices to name a bar with. The name is just cosmetic, all five options are ok.
     * Rather than making 5 separate reference models, we can say those 5 choices are aliases for a single reference
     * value.
     * 
     * @param value
     *      The original term value the alias names are replaceable with
     * @param aliases
     *      List of term values that serve as an alias for the original
     */
    public function setTermValueAliases(value : String, aliases : Array<String>) : Void
    {
        var i : Int;
        for (i in 0...aliases.length){
            Reflect.setField(m_aliasValueToTermMap, Std.string(aliases[i]), value);
        }
    }
    
    /**
     * Set up a new batch of reference bar models. All the models passed in
     * should point to the same semantically equivalent type.
     * 
     * NOTE: This removes all previously set models.
     * 
     * @param modelData
     *      List of bar models to check against
     */
    public function setReferenceModels(modelData : Array<BarModelData>) : Void
    {
		m_referenceBarModels = new Array<BarModelData>();
        
        // Set all new models as not being validated
		m_referenceBarModelValidated = new Array<Bool>();
        // Create decomposed model data for later validation
		m_decomposedReferenceBarModels = new Array<DecomposedBarModelData>();
        for (i in 0...modelData.length){
            m_referenceBarModels.push(modelData[i]);
            m_referenceBarModelValidated.push(false);
            m_decomposedReferenceBarModels.push(new DecomposedBarModelData(modelData[i]));
        }
        
        m_gameEngine.dispatchEventWith(GameEvent.ADD_NEW_BAR_MODEL, false, {
            referenceModels : modelData
        });
    }
    
    /**
     * Get whether at least one of the reference models that were set had been validated.
     * This helps with figuring what progress a player has made in a level, for example
     * in the generic bar model level we want to determine when the player is done with
     * bar modeling so hints for bar modeling can be discarded.
     * 
     * @return
     *      true if at least one reference model was validated by pressing check, false
     *      otherwise OR if the reference set is empty
     */
    public function getAtLeastOneSetComplete() : Bool
    {
        var atLeastOneSetValidated : Bool = false;
        for (i in 0...m_referenceBarModelValidated.length){
            if (m_referenceBarModelValidated[i]) 
            {
                atLeastOneSetValidated = true;
                break;
            }
        }
        return atLeastOneSetValidated;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            if (m_validateButton != null) 
            {
                m_validateButton.removeEventListener(Event.TRIGGERED, validate);
                (try cast(m_validateButton, Button) catch(e:Dynamic) null).enabled = value;
                if (value) 
                {
                    m_validateButton.addEventListener(Event.TRIGGERED, validate);
                    m_validateButton.filter = null;
                }
                else if (m_validateButton.filter == null) 
                {
                    var colorMatrixFilter : ColorMatrixFilter = new ColorMatrixFilter();
                    colorMatrixFilter.adjustSaturation(-1);
                    m_validateButton.filter = colorMatrixFilter;
                }
            }
        }
    }
    
    override public function dispose() : Void
    {
        super.dispose();
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_validateButton = m_gameEngine.getUiEntity("validateButton");
        setIsActive(m_isActive);
    }
    
    /**
     * Get whether any of the reference models recorded in this script matches
     */
    public function getCurrentModelMatchesReference(outMatchedReferenceIndices : Array<Int> = null) : Bool
    {
        var matched : Bool = false;
        var currentModelSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
        if (currentModelSnapshot != null) 
        {
            // Relace alias values in the given model (treat a set of values as one common one)
            currentModelSnapshot.replaceAllAliasValues(m_aliasValueToTermMap);
            
            // Iterate through all reference models, only re-check ones that have not been validated already
            // Always go through every model even if we detect success in case we want to know how other
            // models failed
            var currentModelDecomposed : DecomposedBarModelData = new DecomposedBarModelData(currentModelSnapshot);
            if (currentModelDecomposed.detectedLabelValueConflict.length == 0) 
            {
                var i : Int;
                var numModels : Int = m_referenceBarModels.length;
                for (i in 0...numModels){
                    // Compare the user created model at that time to reference model.
                    // TODO: Based on the bar model type, the equivalency check might want to ignore the use
                    // of any extra boxes  within the validated model.
                    if (!m_referenceBarModelValidated[i] && currentModelDecomposed.isEquivalent(m_decomposedReferenceBarModels[i])) 
                    {
                        matched = true;
                        if (outMatchedReferenceIndices != null) 
                        {
                            outMatchedReferenceIndices.push(i);
                        }
                    }
                }
            }
        }
        return matched;
    }
    
    private function validate() : Void
    {
        // Need to detect all changes in the bar model data. On each change need to create a snapshot
        // of the model data and save it for later
        var matchedReferenceIndices : Array<Int> = new Array<Int>();
        var isValidModel : Bool = getCurrentModelMatchesReference(matchedReferenceIndices);
        if (isValidModel) 
        {
            for (matchedIndex in matchedReferenceIndices)
            {
                m_referenceBarModelValidated[matchedIndex] = true;
            }
            
            var backgroundColorToFadeTo : Int = 0x00FF00;
            if (!isValidModel) 
            {
                backgroundColorToFadeTo = 0xFF0000;
            }
            m_colorChangeAnimation.play(backgroundColorToFadeTo, 0xFFFFFF, 1.0, m_barModelArea.getBackgroundImage());
            Starling.current.juggler.add(m_colorChangeAnimation);
            
            m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_CORRECT);
            Audio.instance.playSfx("find_correct_equation");
        }
        else 
        {
            m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_INCORRECT);
            Audio.instance.playSfx("wrong");
        }  
		
		// The serialized object is used mainly for logging purposes  
        // We replace the values in the labels with the name visible to the player in case they are different
        var modelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
        modelDataSnapshot.replaceLabelValuesWithVisibleNames(m_gameEngine.getExpressionSymbolResources());
        
        var targetReferenceModel : BarModelData = m_referenceBarModels[0].clone();
        targetReferenceModel.replaceLabelValuesWithVisibleNames(m_gameEngine.getExpressionSymbolResources());
        
        var serializedObject : Dynamic = {
            refModel : targetReferenceModel.serialize(),
            studentModel : modelDataSnapshot.serialize(),
            showReference : false,

        };
        
        m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.VALIDATE_BAR_MODEL, false, {
                    barModel : serializedObject,
                    isCorrect : isValidModel,

                });
        
        animateSolutionValid(isValidModel);
    }
    
    /**
     * Called when solution is validated. Invalid items input, if valid then array is empty.
     * @param	invalidItems
     */
    private function animateSolutionValid(isValid : Bool) : Void
    {
        var barModelAreaConstraints : Rectangle = m_barModelArea.getConstraints();
        var maxEdgeLength : Float = Math.min(barModelAreaConstraints.width, barModelAreaConstraints.height);
        var targetTexture : Texture = ((isValid)) ? m_assetManager.getTexture("correct") : m_assetManager.getTexture("wrong");
        
        // Tween in the icon
        var targetIcon : Image = new Image(targetTexture);
        targetIcon.pivotX = targetTexture.width * 0.5;
        targetIcon.pivotY = targetTexture.height * 0.5;
        targetIcon.x = m_barModelArea.x + barModelAreaConstraints.width * 0.5;
        targetIcon.y = m_barModelArea.y;
        targetIcon.touchable = false;
        
        var startingScaleFactor : Float = maxEdgeLength / targetTexture.width;
        var endingScaleFactor : Float = startingScaleFactor * 0.5;
        targetIcon.scaleX = targetIcon.scaleY = startingScaleFactor;
        targetIcon.alpha = 0.7;
        m_barModelArea.addChild(targetIcon);
        
        var fadeInTween : Tween = new Tween(targetIcon, 0.7, Transitions.EASE_OUT_BACK);
        fadeInTween.animate("scaleX", endingScaleFactor);
        fadeInTween.animate("scaleY", endingScaleFactor);
        fadeInTween.animate("alpha", 1.0);
        fadeInTween.onComplete = function() : Void
                {
                    var fadeOutTween : Tween = new Tween(targetIcon, 0.3);
                    fadeOutTween.animate("alpha", 0.0);
                    fadeOutTween.delay = 0.4;
                    fadeOutTween.onComplete = function() : Void
                            {
                                targetIcon.removeFromParent(true);
                            };
                    Starling.current.juggler.add(fadeOutTween);
                };
        Starling.current.juggler.add(fadeInTween);
    }
}
