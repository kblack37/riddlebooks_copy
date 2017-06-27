package gameconfig.commonresource
{
    import wordproblem.resource.bundles.ResourceBundle;

    public class EmbeddedBarModelResources extends ResourceBundle
    {
        /*
        Assets specifically for the bar model
        */
        [Embed(source="/../assets/ui/button_check_bar_model_down.png")]
        public static const button_check_bar_model_down:Class;
        [Embed(source="/../assets/ui/button_check_bar_model_over.png")]
        public static const button_check_bar_model_over:Class;
        [Embed(source="/../assets/ui/button_check_bar_model_up.png")]
        public static const button_check_bar_model_up:Class;
        [Embed(source="/../assets/ui/bar_model/bracket_middle.png")]
        public static const brace_center:Class;
        [Embed(source="/../assets/ui/bar_model/bracket_left_edge.png")]
        public static const brace_left_end:Class;
        [Embed(source="/../assets/ui/bar_model/bracket_right_edge.png")]
        public static const brace_right_end:Class;
        [Embed(source="/../assets/ui/bar_model/bracket_full.png")]
        public static const brace_full:Class;
        
        [Embed(source="/../assets/ui/bar_model/comparison_left.png")]
        public static const comparison_left:Class;
        [Embed(source="/../assets/ui/bar_model/comparison_right.png")]
        public static const comparison_right:Class;
        [Embed(source="/../assets/ui/bar_model/comparison_full.png")]
        public static const comparison_full:Class;
        
        [Embed(source="/../assets/ui/bar_model/dotted_line_corner.png")]
        public static const dotted_line_corner:Class;
        [Embed(source="/../assets/ui/bar_model/dotted_line_segment.png")]
        public static const dotted_line_segment:Class;
        [Embed(source="/../assets/ui/bar_model/ring.png")]
        public static const ring:Class;

        public function EmbeddedBarModelResources()
        {
            super();
        }
    }
}