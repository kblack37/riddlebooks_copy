package wordproblem.engine.events
{
    /**
     * These are all the events that can be fired through the game engine interface.
     */
    public class GameEvent
    {
        /**
         * Fired when the user tried to add a new card into one of the modeling areas
         * 
         * params:
         * widget: the BaseTermWidget that was attempted to be added
         * success: true if the add was successful
         */
        public static const ADD_TERM_ATTEMPTED:String = "add_term_attempted";
        
        /**
         * Fired when the user removed a term from the equation building part
         * 
         * params:
         * widget: the BaseTermWidget that was removed
         */
        public static const REMOVE_TERM:String = "remove_term";
        
        /**
         * Fired when the user changed an operator in the equation
         * 
         * params:
         * value: New operator value changed to
         */
        public static const CHANGED_OPERATOR:String = "changed_operator";
        
        /**
         * Fired when the user has explicitly discovered an expression
         * that was hidden in the deck
         * 
         * params:
         * component: The expression component that was revealed
         */
        public static const EXPRESSION_REVEALED:String = "expression_revealed";
        
        /**
         * Fired if the level is at the stage of discovering terms and the player released a
         * card without it being one of the remaining expressions to be discovered.
         * 
         * params:
         * expression: The expression string that was dropped
         */
        public static const EXPRESSION_RELEASED_NO_REVEAL:String = "expression_released_no_reveal";
        
        /**
         * Fired when the user has successfully modeled an equation
         * 
         * params (object): 
         * id: int id of equation modeled
         * equation: String decompiled equation that was created
         */
        public static const EQUATION_MODEL_SUCCESS:String = "equation_modeled";
        
        /**
         * Fired when the user attempted to model an equation but it failed because it did not match
         * certain restrictions
         * 
         * params (object):
         * equation:String of decompiled equation that failed, empty string if equation was not proper format
         */
        public static const EQUATION_MODEL_FAIL:String = "equation_modeled_fail";
        
        /**
         * Fired when the contents of an equation object has been altered
         * 
         * params: the equation object itself
         */
        public static const EQUATION_CHANGED:String = "equation_changed";
        
        /**
         * Fired when the player has finished dragging a card representing a term
         * 
         * params (Object): 
         * widget:BaseTermWidget that was dragged
         * origin:display object widget that drag originated from
         * Note that there are other extra params that are injected from WidgetDragSystem
         */
        public static const END_DRAG_TERM_WIDGET:String = "end_drag_new_term";
        
        /**
         * Fired when the player starts dragging a card representing a term
         * 
         * params: 
         * widget:the term widget dragged
         * location:point at which drag started in global coordinates
         */
        public static const START_DRAG_TERM_WIDGET:String = "start_drag_new_term";
        
        /**
         * Fired when player has finished dragging a term that already exists on the term area
         * 
         * params (object): 
         * widget:BaseTermWidget that was dragged
         * origin:display object widget that drag originated from
         */
        public static const END_DRAG_EXISTING_TERM_WIDGET:String = "end_drag_existing_term";
        
        /**
         * Fired when the player starts dragging a term that already exists on the term area
         * 
         * params: the term widget dragged
         */
        public static const START_DRAG_EXISTING_TERM_WIDGET:String = "start_drag_existing_term";
        
        /**
         * Fired when the player has released the mouse while they were dragging
         * a card from the deck area.
         * 
         * params: copy of the dragged term widget
         */
        public static const RELEASED_DRAG_DECK_AREA:String = "released_drag_deck_area";
        
        /**
         * Fired when the player starts presses but not drags a card
         * 
         * params: the base widget dragged
         */
        public static const START_DRAG_DECK_AREA:String = "start_drag_deck_area";
        
        /**
         * Fired when the player has clicked on a card within the deck area
         * 
         * params: the base widget selected
         */
        public static const SELECT_DECK_AREA:String = "select_deck_area";
        
        /**
         * Fired when the player has started dragging on a symbol within
         * the term area.
         * 
         * params: 
         * widget: the BaseTermWidget dragged
         * termArea: the TermAreaWidget the dragged widget was part of
         */
        public static const START_DRAG_TERM_AREA:String = "start_drag_term_area";
        
        /**
         * Fired when the player has pressed down on a symbol within the term
         * area
         * 
         * params: 
         * widget: the BaseTermWidget pressed
         * termArea: the TermAreaWidget the dragged widget was part of
         */
        public static const PRESS_TERM_AREA:String = "press_term_area";
        
        /**
         * Fired when player has clicked on a symbol within the term area
         * 
         * params: 
         * widget: the BaseTermWidget pressed
         * termArea: the TermAreaWidget the dragged widget was part of
         */
        public static const CLICK_TERM_AREA:String = "click_term_area";
        
        /**
         * Temp event fired when player has pressed down
         * 
         * params:
         * widget: the BaseTermWidget containing the pressed parenthesis
         * termArea: the TermAreaWidget the pressed widget was part of
         * left: true if the paren selected was the left, false if it was the right
         */
        public static const PRESS_PARENTHESIS_TERM_AREA:String = "press_parenthesis_term_area";
        
        /**
         * Fired when the player has pressed down on an object in the text
         * area view port (not same as click)
         * 
         * params:
         * DocumentView that was pressed (can be null if nothing valid hit)
         */
        public static const PRESS_TEXT_AREA:String = "press_text_area";
        
        /**
         * Fired when the player has started dragging on a view within the paragraph
         * widget
         * 
         * params:
         * documentView: DocumentView that was dragged
         * location: A point containing the global coordinates where the drag starts
         */
        public static const START_DRAG_TEXT_AREA:String = "start_drag_text_area";
        
        /**
         * Fired when the player has released after pressing down on an object
         * in the text area view port
         * 
         * params:
         * DocumentView that had been pressed or dragged
         */
        public static const RELEASE_TEXT_AREA:String = "release_text_area";
        
        /**
         * Called when the text area has finished redrawing with a new set of views
         * 
         * params:
         * None
         */
        public static const TEXT_AREA_REDRAWN:String = "text_area_redrawn";
        
        /**
         * Fired when the contents of the term area has been ENTIRELY RESET.
         * Example usage is when we undo a move or clear the area in which case a brand
         * new expression tree is made.
         * 
         * (HACK: This thing get called BEFORE the term area gets a chance to redraw itself
         * so polling the term area after using this is no good)
         */
        public static const TERM_AREA_RESET:String = "term_area_reset";
        
        /**
         * Fired when the contents of the term area has been altered by some
         * incremental change. This usually occurs after some animation has completed.
         * (not including a wholesale reset)
         * 
         * params:
         *      undo: If true then this change was triggered by undo. This is a hack
         *      because undo logic relies exactly on this event to create a history entry
         *      BUT we don't want to create a history entry for the change caused by the undo.
         */
        public static const TERM_AREA_CHANGED:String = "term_area_changed";
        public static const TERM_AREA_CARD_DROP:String = "term_area_card_drop";
        
        /**
         * Fired by the game state when both when a term area has had its contents modified
         * and all term areas are in a ready state. For example if an operation makes changes to
         * multiple term areas at once, only one event gets fired for that batch of changes.
         * 
         * No params, any external class needs to make a function call to fetch the contents
         */
        public static const TERM_AREAS_CHANGED:String = "term_areas_changed";
        
        /**
         * Fired when the player has selected without dragging some item that
         * is part of the inventory area.
         * 
         * params (array of arguments):
         * integer entityId of selected object
         */
        public static const SELECT_INVENTORY_AREA:String = "select_inventory_area";
        
        /**
         * Fired when the player has started dragging an item.
         * 
         * params:
         * RenderComponent of dragged object
         * Point position of the drag
         */
        public static const START_DRAG_INVENTORY_AREA:String = "start_drag_inventory_area";
        
        /**
         * Fired when the player has expanded or collapsed the inventory
         * 
         * params:
         * Boolean of whether the inventory is expanded
         */
        public static const EXPAND_INVENTORY_AREA:String = "expand_inventory_area";
        
        /**
         * Fired when an option in the expression picker has been selected
         * 
         * params (object)
         * expression: The string expression of the option
         * pickerId: Id of the picker widget
         */
        public static const EXPRESSION_PICKER_SELECT_OPTION:String = "expression_picker_select_option";
        
        /**
         * Fired when an option in the expression picker has been deselected
         * 
         * params (object)
         * expression: The string expression of the option
         * pickerId: Id of the picker widget
         */
        public static const EXPRESSION_PICKER_DESELECT_OPTION:String = "expression_picker_deselect_option";
        
        /**
         * Fired when a problem uses the expression picker interface and the options selected were
         * acceptable
         * 
         * no params right now
         */
        public static const EXPRESSION_PICKER_CORRECT:String = "expression_picker_correct";
        
        /**
         * Fired when a problem uses the expression picker interface and the options selected were
         * not correct
         * 
         * no params right now
         */
        public static const EXPRESSION_PICKER_INCORRECT:String = "expression_picker_incorrect";
        
        /**
         * Fired whenever the bar model area undergoes a change.
         * (This is a signal that a snapshot of the bar model data should be taken)
         * 
         * params (object)
         * previousSnapshot:clone of the BarModelData BEFORE the change occured
         */
        public static const BAR_MODEL_AREA_CHANGE:String = "bar_model_area_change";
        
        /**
         * Fired whenever the bar model area has finished redrawing and laying out
         * its elements. (The preview view dispatches this as well)
         */
        public static const BAR_MODEL_AREA_REDRAWN:String = "bar_model_area_redrawn";
        
        /**
         * Fired when an attempt to validate the contents of the bar model area
         * is incorrect, it doesn't match any supplied reference models.
         */
        public static const BAR_MODEL_INCORRECT:String = "bar_model_incorrect";
        
        /**
         * Fired when an attempt to validate the contents of the bar model area
         * is successful, it correctly match one of the supplied answers.
         */
        public static const BAR_MODEL_CORRECT:String = "bar_model_correct";
        
        /**
         * Fired when all the resources of a level are loaded and ready.
         * Scripts can start setup of logic.
         */
        public static const LEVEL_READY:String = "level_ready";
        
        /**
         * When the final win condition for that level has been satisified, not the same as the
         * player simply exiting the level. This means all meaningful progress a player can make
         * has been finished.
         * 
         * Look at the level complete event below for a detailed distinction.
         */
        public static const LEVEL_SOLVED:String = "level_solved";
        
        /**
         * Fired when there are no more scripted events to take place in the level.
         * This should almost always occur after the solve event, the exceptions being debug
         * scenarios where the player skips through a level but wants it to still
         * be marked as complete.
         * 
         * An example of how they differ, player needs to model an equation and calculate the
         * final answer. After inputting the final answer the level fires the solved event since
         * there is no more meaningful action the player can take that will affect their performance on
         * the level.
         * 
         * However, there might be some additional cutscenes or animations to be finished before we
         * are ready for the level to end. These extras are not important to saved progress though,
         * if the player disconnects before this event but after the solve, that level should still
         * be marked as completed.
         * 
         * no parameters
         */
        public static const LEVEL_COMPLETE:String = "level_complete";
        
        /**
         * Fired when the player has selected the various buttons.
         */
        public static const HINT_BUTTON_SELECTED:String = "hint_button_selected";        
        public static const OPTIONS_SELECTED:String = "options_selected";
        public static const UNDO_SELECTED:String  = "undo_selected";
        public static const RESUME_SELECTED:String= "resume_selected";
        public static const SKIP_SELECTED:String  = "skip_selected";
        public static const MUSIC_SELECTED:String = "music_selected";
        public static const SFX_SELECTED:String   = "sfx_selected";
        public static const MENU_SELECTED:String  = "menu_selected";
        
        /**
         * Fired whenever some part of the application wants to force the hint system to run
         * a specific hint process.
         * 
         * params (object)
         * hint: The hint script object containing all the data about the hint.
         * smoothlyRemove: Optional boolean, if true any existing hint should be smoothly removed before showing
         * the new one.
         */
        public static const SHOW_HINT:String = "show_hint";
        
        /**
         * Fired whenever the user has signaled they want to fetch a new hint in the current level
         * 
         * params (object)
         * hint: The hint script object containing all the data about the new hint
         */
        public static const GET_NEW_HINT:String = "get_new_hint";
        
        /**
         * Fired whenever one part of the system wants the currently visible hint to be removed.
         * An example usage is when the player performs an action to modify the bar model area, in which
         * a hint regarding a mistake in the previous bar model should be dismissed.
         * 
         * params (object)
         * smoothlyRemove: Optional boolean, if true the current hint should be smoothly removed.
         */
        public static const REMOVE_HINT:String = "remove_hint";
        
        /**
         * Special event where we want to update the grade and gender of a player after they
         * already registered for an account.
         * 
         * params (object)
         * grade
         * gender
         */
        public static const UPDATE_GRADE_GENDER:String = "update_grade_gender";
        
        /**
         * Fired when the game has instantiated a new target equation the player is supposed to model
         * 
         * params (object)
         * expression: A reference to the root node of the target equation (NOT A COPY so avoid modifying it)
         */
        public static const ADD_NEW_EQUATION:String = "add_new_equation";
        
        /**
         * Fired when the game has instantiated a new set of reference bar models the player is supposed
         * to match.
         * 
         * Note that unlike equation, multiple reference bar models may frequently represent the same
         * semantic construct
         * 
         * params (object)
         * referenceModels: A vector of bar model data (NOT A COPY so avoid modifying it)
         */
        public static const ADD_NEW_BAR_MODEL:String = "add_new_bar_model";
        
        /**
         * Fired when the user should be directed to the a replay showing how to do a particular action.
         * For example, if it passes along a param with the tip name for bar difference, a replaying
         * showing the player how to add the difference should pop up in a separate window.
         * 
         * params (object)
         * tipName
         */
        public static const LINK_TO_TIP:String = "link_to_tip";
        
        /**
         * Fired when the radial options menu used to resolve conflicts in overlapping bar model gestures
         * is created and opened. At this point the display for the radial menu has been created.
         * 
         * params (object)
         * display: The display object representing the menu
         */
        public static const OPEN_RADIAL_OPTIONS:String = "open_radial_options";
        
        /**
         * Fired when the radial options menu has been closed and destroyed.
         */
        public static const CLOSE_RADIAL_OPTIONS:String = "close_radial_options";
        
        /**
         * Fired when the player starts a resize operation on a label
         */
        public static const START_RESIZE_HORIZONTAL_LABEL:String = "start_resize_horizontal_label";
        
        /**
         * Fired when the player ends a resize operation on a label (triggers even if the label did
         * not actually change in length)
         */
        public static const END_RESIZE_HORIZONTAL_LABEL:String = "end_resize_horizontal_label";
    }
}