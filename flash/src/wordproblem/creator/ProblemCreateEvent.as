package wordproblem.creator
{
    public class ProblemCreateEvent
    {
        /**
         * Dispatched when the user want to start highlighting text in order to tag it to
         * a part of the bar model
         * 
         * params:
         * {id: part id of the bar model that should link to the highlighted text}
         */
        public static const USER_HIGHLIGHT_STARTED:String = "user_highlight_started";
        
        /**
         * params:
         * {id: high level id of the element bound to the new highlight}
         */
        public static const USER_HIGHLIGHT_FINISHED:String = "user_highlight_finished";
        
        /**
         * Dispatched when highlighting in cancelled, it should have no affect
         */
        public static const USER_HIGHLIGHT_CANCELLED:String = "user_highlight_cancelled";
        
        /**
         * Dispatched whenever one of more highlighted parts gets redrawn.
         * No params at the moment so listening modules will not be able to determine
         * directly the exact highlight that changed.
         */
        public static const HIGHLIGHT_REFRESHED:String = "highlight_refreshed";
        
        public static const PROBLEM_CREATE_INIT:String = "create_problem_init";
        
        /**
         * Dispatched whenever an element in the bar model view has been selected.
         * 
         * params:
         * the part id in the bar model
         */
        public static const SELECT_BAR_ELEMENT:String = "select_bar_element";
        
        /**
         * Dispatched whenever an element in the bar model view has the mouse leaving it
         * since the last frame
         * 
         * params:
         * partId: the id associated with the generic template of the model (a,b,c,?)
         * elementId: the id the specific piece in the current bar model
         */
        public static const MOUSE_OUT_BAR_ELEMENT:String = "mouse_out_bar_element";
        
        /**
         * Dispatched whenever an element in the model view has the mouse entering it
         * since the last frame
         * 
         * params:
         * partId: the id associated with the generic template of the model (a,b,c,?)
         * elementId: the id the specific piece in the current bar model
         */
        public static const MOUSE_OVER_BAR_ELEMENT:String = "mouse_over_bar_element";
        
        /**
         * Dispatched whenever the value/name for one or more of the elements of the bar model 
         * has been modified
         * 
         * params:
         * None so far
         */
        public static const BAR_PART_VALUE_CHANGED:String = "bar_part_value_changed";
        
        /**
         * Dispatched when the user has altered the background of the problem they are editing
         */
        public static const BACKGROUND_AND_STYLES_CHANGED:String = "background_and_styles_changed";
        
        /**
         * Dispatched when we want to start showing the example problem. This event is useful for
         * other scripts to disable ui that we don't want active when the example is show.
         */
        public static const SHOW_EXAMPLE_START:String = "show_example_start";
        
        /**
         * Dispatched when we want to hide the example problem. This event is useful for other scripts
         * to re-enable ui that might have been disabled when the example is shown.
         */
        public static const SHOW_EXAMPLE_END:String = "show_example_end";
        
        /**
         * Dispatched when the player wants to exit the testing level.
         */
        public static const TEST_LEVEL_EXIT:String = "test_level_exit";
    }
}