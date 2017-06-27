package wordproblem.engine.component
{
    /**
     * This component means an entity can be purchased with some number of coins.
     * The maximum total amount of an item type that can be purchased is also stored
     */   
    public class PriceComponent extends Component
    {
        public static const TYPE_ID:String = "PriceComponent";
        
        /**
         * The total number of coins needs to purchase an instance of the entity
         */
        public var price:int;
        
        public function PriceComponent(entityId:String)
        {
            super(entityId, PriceComponent.TYPE_ID);
            
            this.price = 0;
        }
        
        override public function serialize():Object
        {
            return {price: this.price};
        }
        
        override public function deserialize(data:Object):void
        {
            this.price = data.price;   
        }
    }
}