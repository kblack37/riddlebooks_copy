package wordproblem.engine.expression.event
{
    /**
     * List of events dispatched from the expression tree
     */
    public class ExpressionTreeEvent
    {
        /**
         * Dispatched when a new leaf was added
         * 
         * Param: Object
         * nodeAdded: ExpressionNode that was added
         * initialXPosition: Starting x of the added node
         * initialXPosition: Starting y of the added node
         */
        public static const ADD:String = "add";
        
        /**
         * Dispatched when a batch of nodes were added
         * 
         * Param: Object
         * nodesAdded: List of expression nodes added
         * initialXPositions: List of starting x positions
         * initialYPositions: List of starting y positions
         */
        public static const ADD_BATCH:String = "add_batch";
        
        /**
         * Dispatched when a node was moved. In this instance nodes are not created nor destroyed.
         */
        public static const MOVE:String = "move";
        
        /**
         * Dispatched when a node was removed
         * 
         * Param: Object
         * nodeId: int id of node that was removed
         */
        public static const REMOVE:String = "remove";
        
        /**
         * Dispatched when a substitution completed
         * 
         * Param: Object
         * nodeIdToReplace: The id of the node that was to be replaced
         * subtreeToReplace: The root of the subtree that replaced a node
         */
        public static const SUBSTITUTE:String = "substitute";
        
        /**
         * Dispatched when a distribution operation finished
         * 
         * Param: Object
         * nodeIdDistributed: The id of the node that was selected for distribution
         * nodeIdsPostDistribution: The ids of nodes that are copies of the distributed node after the operation
         * has been completed.
         * 
         * Useful if we need an animation that requires the position of the nodes that were
         * just added.
         */
        public static const DISTRIBUTE:String = "distribute";
        
        /**
         * Dispatched when a single node was simplified
         * 
         * Param: Object
         * nodeIds: Vector of int ids of nodes that were simplified
         */
        public static const SIMPLIFY_SINGLE:String = "simplify_single";
        
        /**
         * Dispatched when a pair of nodes was simplified with each other
         * 
         * Param:
         * nodeIds: Vector of int ids of nodes that were simplified
         */
        public static const SIMPLIFY_PAIR:String = "simplify_pair";
        
        /**
         * Dispatched when a cluster, > 2 nodes were simplified
         * 
         * Param:
         * nodeIds: Vector of int ids of nodes that were simplified
         */
        public static const SIMPLIFY_CLUSTER:String = "simplify_cluster";
    }
}