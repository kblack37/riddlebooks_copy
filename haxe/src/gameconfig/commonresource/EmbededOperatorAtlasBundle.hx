package gameconfig.commonresource;


import wordproblem.resource.bundles.ResourceBundle;

class EmbededOperatorAtlasBundle extends ResourceBundle
{
    @:meta(Embed(source="/../assets/operators/plus.png"))

    public static var add : Class<Dynamic>;
    @:meta(Embed(source="/../assets/operators/subtract.png"))

    public static var subtract : Class<Dynamic>;
    @:meta(Embed(source="/../assets/operators/parentheses_right.png"))

    public static var paren_right : Class<Dynamic>;
    @:meta(Embed(source="/../assets/operators/parentheses_left.png"))

    public static var paren_left : Class<Dynamic>;
    @:meta(Embed(source="/../assets/operators/multiply_dot.png"))

    public static var multiply_dot : Class<Dynamic>;
    @:meta(Embed(source="/../assets/operators/multiply_x.png"))

    public static var multiply_x : Class<Dynamic>;
    @:meta(Embed(source="/../assets/operators/equal.png"))

    public static var equal : Class<Dynamic>;
    @:meta(Embed(source="/../assets/operators/divide_obelus.png"))

    public static var divide_obelus : Class<Dynamic>;
    @:meta(Embed(source="/../assets/operators/divide_bar.png"))

    public static var divide_bar : Class<Dynamic>;
    
    public function new()
    {
        super();
    }
}
