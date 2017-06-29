package wordproblem.levelselect.scripts;


import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.ui.MouseState;

import feathers.controls.Callout;

import starling.animation.Juggler;

import wordproblem.callouts.CalloutCreator;
import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentFactory;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.action.CustomVisitNode;
import wordproblem.engine.scripting.graph.selector.SequenceSelector;
import wordproblem.engine.systems.CalloutSystem;
import wordproblem.engine.systems.FreeTransformSystem;
import wordproblem.engine.systems.HelperCharacterRenderSystem;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.event.LevelSelectEvent;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.resource.AssetManager;
import wordproblem.state.WordProblemSelectState;

/**
 * This script controls the actions of the helper characters while in the level selection screen.
 */
class LevelSelectCharacterSequence extends ScriptNode
{
    private var m_characterComponentManager : ComponentManager;
    private var m_characterController : HelperCharacterController;
    private var m_calloutCreator : CalloutCreator;
    private var m_wordProblemSelectState : WordProblemSelectState;
    
    private var m_levelManager : WordProblemCgsLevelManager;
    
    /*
    Systems needed to draw the characters appropriately
    */
    private var m_helpRenderSystem : HelperCharacterRenderSystem;
    private var m_calloutSystem : CalloutSystem;
    private var m_freeTransformSystem : FreeTransformSystem;
    
    public function new(assetManager : AssetManager,
            wordProblemSelectState : WordProblemSelectState,
            levelManager : WordProblemCgsLevelManager,
            spriteSheetJuggler : Juggler,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_wordProblemSelectState = wordProblemSelectState;
        m_wordProblemSelectState.addEventListener(LevelSelectEvent.OPEN_GENRE, onOpenGenre);
        m_wordProblemSelectState.addEventListener(LevelSelectEvent.CLOSE_GENRE, onCloseGenre);
        
        // Create data for the characters
        m_characterComponentManager = new ComponentManager();
        var componentFactory : ComponentFactory = new ComponentFactory(new LatexCompiler(new RealsVectorSpace()));
        var characterData : Dynamic = assetManager.getObject("characters");
        componentFactory.createAndAddComponentsForItemList(m_characterComponentManager, characterData.charactersLevelSelect);
        m_calloutCreator = new CalloutCreator(new TextParser(), new TextViewFactory(assetManager, null));
        m_characterController = new HelperCharacterController(m_characterComponentManager, m_calloutCreator);
        
        m_levelManager = levelManager;
        
        // Create systems to execute
        m_helpRenderSystem = new HelperCharacterRenderSystem(assetManager, spriteSheetJuggler, m_wordProblemSelectState.getRewardLayer());
        m_calloutSystem = new CalloutSystem(assetManager, wordProblemSelectState.getRewardLayer(), new MouseState(null, null));
        m_freeTransformSystem = new FreeTransformSystem();
        
        // So need to figure out a way before hand to skip ahead through some of the checked conditions
        // The initial set up of the scripts depends on the progress the player has made up
        // to this point.
        // This needs to get rebuilt every time we want to re-initialize the player's progress
        
        /*
        Set up logical behavior with custom visit nodes
        
        The determination of which nodes to add to the start can be gleaned from 
        */
        var mainSequence : ScriptNode = new SequenceSelector();
        mainSequence.pushChild(new CustomVisitNode(m_characterController.setCharacterVisible, {
                    id : "Cookie",
                    visible : false,

                }));
        
        // Character tells player to start at green shelf if they are brand new
        m_characterController.moveCharacterTo({
                    id : "Taco",
                    x : 880,
                    y : 50,
                    velocity : -1,

                });
        if (levelManager.currentLevelProgression.numLevelLeafsPlayed == 0) 
        {
            mainSequence.pushChild(new CustomVisitNode(m_characterController.rotateCharacterTo, {
                        id : "Taco",
                        rotation : -Math.PI * 0.5,
                        velocity : -1,

                    }));
            mainSequence.pushChild(new CustomVisitNode(m_characterController.isStillMoving, {
                        id : "Taco"

                    }));
            mainSequence.pushChild(new CustomVisitNode(m_characterController.rotateCharacterTo, {
                        id : "Taco",
                        rotation : 0.3,
                        velocity : 1.4,

                    }));
            mainSequence.pushChild(new CustomVisitNode(m_characterController.moveCharacterTo, {
                        id : "Taco",
                        x : 530,
                        y : 335,
                        velocity : 500,

                    }));
            mainSequence.pushChild(new CustomVisitNode(m_characterController.isStillMoving, {
                        id : "Taco"

                    }));
            mainSequence.pushChild(new CustomVisitNode(m_characterController.showDialogForCharacter, {
                        id : "Taco",
                        text : "Start playing here!",
                        color : 0xFFFFFF,
                        direction : Callout.DIRECTION_RIGHT,
                        width : 170,
                        padding : 0,

                    }));
            
            // Once played at least one level can get rid of the character
            mainSequence.pushChild(new CustomVisitNode(getNumLevelsPlayedExceedsLimit, {
                        limit : 0

                    }));
        }
        mainSequence.pushChild(new CustomVisitNode(m_characterController.setCharacterVisible, {
                    id : "Taco",
                    visible : false,

                }));
        
        // TODO:
        // Character tells player that there are new shelves to play after they have finished the first intro chapter
        // but have not yet played any other level
        
        m_children.push(mainSequence);
        
        function getNumLevelsPlayedExceedsLimit(param : Dynamic) : Int
        {
            return ((param.limit < m_levelManager.numLevelLeafsPlayed)) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
        };
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        m_wordProblemSelectState.removeEventListener(LevelSelectEvent.OPEN_GENRE, onOpenGenre);
        m_wordProblemSelectState.removeEventListener(LevelSelectEvent.CLOSE_GENRE, onCloseGenre);
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        if (value) 
        {
            // Make sure callouts on the characters are added at the appropriate layer
            if (m_calloutSystem != null) 
            {
                m_calloutSystem.setCalloutLayer(m_wordProblemSelectState.getRewardLayer());
            }
        }
        else 
        {
            // Remove and stop the characters when setting to inactive
            var textureAtlasComponents : Array<Component> = m_characterComponentManager.getComponentListForType(RenderableComponent.TYPE_ID);
            var textureAtlasComponent : RenderableComponent;
            var components : Int = textureAtlasComponents.length;
            var i : Int;
            for (i in 0...components){
                textureAtlasComponent = try cast(textureAtlasComponents[i], RenderableComponent) catch(e:Dynamic) null;
                
                if (textureAtlasComponent.view != null) 
                {
                    textureAtlasComponent.view.removeFromParent();
                }
            }
        }
    }
    
    override public function visit() : Int
    {
        // Execute the script logic
        for (childScriptNode/* AS3HX WARNING could not determine type for var: childScriptNode exp: EIdent(m_children) type: null */ in m_children)
        {
            childScriptNode.visit();
        }  // Update systems that read data to draw the characters  
        
        
        
        m_calloutSystem.update(m_characterComponentManager);
        m_freeTransformSystem.update(m_characterComponentManager);
        m_helpRenderSystem.update(m_characterComponentManager);
        
        return ScriptStatus.SUCCESS;
    }
    
    private function onOpenGenre() : Void
    {
    }
    
    private function onCloseGenre() : Void
    {
    }
}
