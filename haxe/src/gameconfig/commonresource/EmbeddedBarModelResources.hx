package gameconfig.commonresource;

import wordproblem.resource.bundles.ResourceBundle;

class EmbeddedBarModelResources extends ResourceBundle
{
	/*
	Assets specifically for the bar model
	*/
	@:meta(Embed(source="/../assets/ui/button_check_bar_model_down.png"))
	public static var button_check_bar_model_down : Class<Dynamic>;
	@:meta(Embed(source="/../assets/ui/button_check_bar_model_over.png"))
	public static var button_check_bar_model_over : Class<Dynamic>;
	@:meta(Embed(source="/../assets/ui/button_check_bar_model_up.png"))
	public static var button_check_bar_model_up : Class<Dynamic>;
	
	@:meta(Embed(source="/../assets/ui/bar_model/bracket_middle.png"))
	public static var brace_center : Class<Dynamic>;
	@:meta(Embed(source="/../assets/ui/bar_model/bracket_left_edge.png"))
	public static var brace_left_end : Class<Dynamic>;
	@:meta(Embed(source="/../assets/ui/bar_model/bracket_right_edge.png"))
	public static var brace_right_end : Class<Dynamic>;
	@:meta(Embed(source="/../assets/ui/bar_model/bracket_full.png"))
	public static var brace_full : Class<Dynamic>;
	
	@:meta(Embed(source="/../assets/ui/bar_model/comparison_left.png"))
	public static var comparison_left : Class<Dynamic>;
	@:meta(Embed(source="/../assets/ui/bar_model/comparison_right.png"))
	public static var comparison_right : Class<Dynamic>;
	@:meta(Embed(source="/../assets/ui/bar_model/comparison_full.png"))
	public static var comparison_full : Class<Dynamic>;
	
	@:meta(Embed(source="/../assets/ui/bar_model/dotted_line_corner.png"))
	public static var dotted_line_corner : Class<Dynamic>;
	@:meta(Embed(source="/../assets/ui/bar_model/dotted_line_segment.png"))
	public static var dotted_line_segment : Class<Dynamic>;
	@:meta(Embed(source="/../assets/ui/bar_model/ring.png"))
	public static var ring : Class<Dynamic>;
	
	public function new() {
		super();
	}
}
