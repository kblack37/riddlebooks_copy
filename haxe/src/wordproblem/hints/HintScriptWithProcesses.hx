package wordproblem.hints;

import haxe.Constraints.Function;

import openfl.display.DisplayObject;

import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.selector.SequenceSelector;


/**
 * A bit of a hack, define a hint where the behavior when active is defined by the
 * execution of a series of 'processes' (which are simply self contained actions).
 *
 * The idea behind this class is we want to be able to create hints with variation without
 * having to create a new subclass for each variant. It is a similar idea to the use of
 * entity + components, different hints are crafted through composition rather than
 * inheritance.
 */
class HintScriptWithProcesses extends HintScript
{
	/**
	 * Hack: We want to log details about some of the hints shown so we are expecting external
	 * script to set this field during construction and stuffing it with the appropriate details
	 */
	public var serializedHintData : Dynamic;

	/**
	 * The definition of the behavior of hint within the main game screen is determined
	 * by the process executed by this main sequence.
	 *
	 * Stuff like moving a character or highlighting elements in the game world should be
	 * added to this main sequence.
	 */
	private var m_mainProcessSequence:SequenceSelector;

	/**
	 * The behavior to execute if this hint to asked to interrupt and then remove itself.
	 */
	private var m_interruptProcessSequence:SequenceSelector;

	/**
	 * Need to remember the last interrupt callback set so we can trigger it at the appropriate time.
	 */
	private var m_interruptCallback:Function;

	/**
	 * The main reason for this callback rather than each process performing cleanup on its own
	 * is that we might have several processes have the same cleanup procedure.
	 */
	private var m_customHideCallback:Function;

	private var m_customGetDescription:Function;
	private var m_customDisposeDescription:Function;

	/**
	 *
	 * @param customGetDescription
	 *      signature callback(width:Number, height:Number):DisplayObject
	 * @param customHideCallback
	 *      signature callback() : Void
	 *      Instead of the processes themselves doing cleanup, all cleanup is bundled together in
	 *      this hide callback.
	 */
	public function new(customGetDescription:Function,
											customDisposeDescription:Function,
											customHideCallback:Function,
											unlocked : Bool,
											id:String=null,
											isActive : Bool=true)
	{
		super(unlocked, id, isActive);

		m_customGetDescription = customGetDescription;
		m_customDisposeDescription = customDisposeDescription;
		m_customHideCallback = customHideCallback;
		m_mainProcessSequence = new SequenceSelector();
		m_interruptProcessSequence = new SequenceSelector();
	}

	public function addProcess(process:ScriptNode, index : Int=-1) : Void
	{
		m_mainProcessSequence.pushChild(process, index);
	}

	public function addInterruptProcess(process:ScriptNode, index : Int=-1) : Void
	{
		m_interruptProcessSequence.pushChild(process, index);
	}

	override public function getSerializedData() : Dynamic
	{
		return this.serializedHintData;
	}

	override public function interruptSmoothly(onInterruptFinished:Function) : Void
	{
		m_interruptCallback = onInterruptFinished;

		// On interrupt we stop the main process from executing and run the interrupt process.
	}

	/**
	 * Normally a return value of fail would mean at that frame the hint should be deactivated.
	 */
	override public function visit() : Int
	{
		super.visit();

		var scriptStatus : Int = ScriptStatus.SUCCESS;
		if (m_interruptCallback == null)
		{
			m_mainProcessSequence.visit();
			if (m_mainProcessSequence.allChildrenFinished())
			{
				scriptStatus = ScriptStatus.FAIL;
			}
		}
		else
		{
			m_interruptProcessSequence.visit();
			if (m_interruptProcessSequence.allChildrenFinished())
			{
				scriptStatus = ScriptStatus.FAIL;
				m_interruptCallback();
				m_interruptCallback = null;
			}
		}

		return scriptStatus;
	}

	override public function getDescription(width:Float, height:Float):DisplayObject
	{
		var description:DisplayObject = null;
		if (m_customGetDescription != null)
		{
			description = m_customGetDescription(width, height);
		}

		return description;
	}

	override public function disposeDescription(description:DisplayObject) : Void
	{
		if (m_customDisposeDescription != null)
		{
			m_customDisposeDescription(description);
		}
		else if (description != null)
		{
			description = null;
		}
	}

	override public function show() : Void
	{
		// Reset the processes so we can start the sequence fresh from the beginning
		m_mainProcessSequence.reset();
		m_mainProcessSequence.setIsActive(true);
	}

	override public function hide() : Void
	{
		// Call a custom hide function to clean up changes caused by the processes
		if (m_customHideCallback != null)
		{
			m_customHideCallback();
		}

		m_mainProcessSequence.setIsActive(false);
	}

	override public function dispose() : Void
	{
		super.dispose();
		m_mainProcessSequence.dispose();

		if (m_interruptProcessSequence != null)
		{
			m_interruptProcessSequence.dispose();
		}
	}
}