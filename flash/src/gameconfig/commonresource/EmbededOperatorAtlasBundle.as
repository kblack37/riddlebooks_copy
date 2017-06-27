package gameconfig.commonresource
{
    import wordproblem.resource.bundles.ResourceBundle;

    public class EmbededOperatorAtlasBundle extends ResourceBundle
    {
        [Embed(source="/../assets/operators/plus.png")]
        public static const add:Class;
        [Embed(source="/../assets/operators/subtract.png")]
        public static const subtract:Class;
        [Embed(source="/../assets/operators/parentheses_right.png")]
        public static const paren_right:Class;
        [Embed(source="/../assets/operators/parentheses_left.png")]
        public static const paren_left:Class;
        [Embed(source="/../assets/operators/multiply_dot.png")]
        public static const multiply_dot:Class;
        [Embed(source="/../assets/operators/multiply_x.png")]
        public static const multiply_x:Class;
        [Embed(source="/../assets/operators/equal.png")]
        public static const equal:Class;
        [Embed(source="/../assets/operators/divide_obelus.png")]
        public static const divide_obelus:Class;
        [Embed(source="/../assets/operators/divide_bar.png")]
        public static const divide_bar:Class;
        
        public function EmbededOperatorAtlasBundle()
        {
            super();
        }
    }
}