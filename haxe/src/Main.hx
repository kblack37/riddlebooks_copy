
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

import gameconfig.versions.brainpopturk.GameConfig;

import starling.core.Starling;
import starling.events.Event;
import starling.events.ResizeEvent;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.WordProblemGameBase;

@:meta(SWF(width="800",height="600",backgroundColor="0x000000"))


/**
 * The main class simply acts as a wrapper around starling.
 */
class Main extends Sprite
{
    private var m_starling : Starling;
    
    /**
     * CHANGE ON RELEASE (the game config class wraps together all custom
     * parameters used for each version release)
     */
    private var m_gameConfig : AlgebraAdventureConfig = new GameConfig();
    
    public function new()
    {
        super();
        // BE CAREFUL OF THIS, starling will keep a copy of each texture when restoring itself.
        // To avoid this look at the code for the default AssetManager which restores textures from a source
        Starling.handleLostContext = true;
        
        this.addEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
    }
    
    private function onAddedToStage(event : flash.events.Event) : Void
    {
        this.stage.scaleMode = StageScaleMode.NO_SCALE;
        this.stage.align = StageAlign.TOP_LEFT;
        
        m_starling = new Starling(m_gameConfig.getMainGameApplication(), this.stage);
        m_starling.enableErrorChecking = true;
        m_starling.start();
        m_starling.showStats = false;
        
        // Have listener detect when the application class is created, we can then properly initialize it
        // with various config parameters.
        m_starling.addEventListener(starling.events.Event.ROOT_CREATED, onRootObjectCreated);
        m_starling.stage.addEventListener(ResizeEvent.RESIZE, onResize);
        onResize(null);
        
        this.removeEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
        
        // Disable right click by binding to event listener that does nothing
        this.stage.addEventListener(MouseEvent.RIGHT_CLICK, function(event : MouseEvent) : Void{
                });
    }
    
    private function onRootObjectCreated(event : starling.events.Event, data : Dynamic) : Void
    {
        if (Std.is(data, WordProblemGameBase)) 
        {
            var mainApplication : WordProblemGameBase = try cast(data, WordProblemGameBase) catch(e:Dynamic) null;
            mainApplication.initialize(this.stage, m_gameConfig);
        }
    }
    
    private function onResize(event : ResizeEvent) : Void
    {
        // Compute max view port size
        var fullViewPort : Rectangle = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
        var DES_WIDTH : Float = 800;
        var DES_HEIGHT : Float = 600;
        var scaleFactor : Float = Math.min(stage.stageWidth / DES_WIDTH, stage.stageHeight / DES_HEIGHT);
        
        // Compute ideal view port
        var viewPort : Rectangle = new Rectangle();
        viewPort.width = scaleFactor * DES_WIDTH;
        viewPort.height = scaleFactor * DES_HEIGHT;
        viewPort.x = 0.5 * (stage.stageWidth - viewPort.width);
        viewPort.y = 0.5 * (stage.stageHeight - viewPort.height);
        
        // Ensure the ideal view port is not larger than the max view port (could cause a crash otherwise)
        viewPort = viewPort.intersection(fullViewPort);
        
        // Set the updated view port
        Starling.current.viewPort = viewPort;
    }
}
