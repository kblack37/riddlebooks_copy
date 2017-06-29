package dragonbox.common.expressiontree;


import flash.utils.Dictionary;

import dragonbox.common.math.util.MathUtil;
import dragonbox.common.math.vectorspace.IVectorSpace;

/**
 * Set of general functions to poll data from a expression tree construct
 */
class ExpressionUtil
{
    /** Number starts with optional negative sign and only numbers following it */
    public static var NUMERIC_REGEX : EReg = new EReg('(^-?[0-9]+$)', "");
    /** Number starts with optional negative sign and only numbers following it */
    public static var VARIABLE_REGEX : EReg = new EReg('^-?[a-zA-Z]\\w*', "");
    
    public static function print(node : ExpressionNode, vectorSpace : IVectorSpace) : String
    {
        var s : String = "";
        if (node != null) 
        {
            // If parenthesis are not explicitly specified for a node, then we use
            // precedence rules to figure out whether parentheses must be injected
            var useParens : Bool = node.wrapInParentheses;
            if (!useParens && !node.isLeaf() && node.parent != null) 
            {
                var thisPrecedence : Int = vectorSpace.getOperatorPrecedence(node.data);
                var parentPrecedence : Int = vectorSpace.getOperatorPrecedence(node.parent.data);
                useParens = thisPrecedence < parentPrecedence;
            }
            
            if (useParens) 
            {
                s += "(";
            }
            
            s += print(node.left, vectorSpace);
            s += node.data;
            s += print(node.right, vectorSpace);
            
            if (useParens) 
            {
                s += ")";
            }
        }
        
        return s;
    }
    
    /**
     * Get whether two expression tree share the exact same structure. Note that either expression
     * could also be equations in which case the equals sign is treated as a commutative operator.
     * 
     * This ignores differences in wild cards, i.e. a wild card with expected data 'x' is equal to the 'x'.
     * 
     * @param communative
     *      If true we allow communative operations of addition and multiplication as well
     *      as the equality sign to flip the children of rootA.
     * @return
     *      True if the given trees are structurally identical
     */
    public static function getExpressionsStructurallyEquivalent(rootA : ExpressionNode,
            rootB : ExpressionNode,
            communative : Bool,
            vectorSpace : IVectorSpace) : Bool
    {
        var match : Bool = false;
        if (rootA != null && rootB != null) 
        {
            match = (rootA.data == rootB.data);
            
            // Can return immediately if the roots do not have the same value or if they
            // are both leaves
            if (match && !rootA.isLeaf() && !rootB.isLeaf()) 
            {
                // If they are both matching operators we now must check whether their
                // children node are identical
                
                // If we allow communative transforms, then addition and multiplication subtree
                // will need to be compared differently. We will need to compare the sets of subtrees
                // added or multiplied together
                var isAddition : Bool = rootA.isSpecificOperator(vectorSpace.getAdditionOperator());
                var isMultiplication : Bool = rootA.isSpecificOperator(vectorSpace.getMultiplicationOperator());
                var isEquality : Bool = rootA.isSpecificOperator(vectorSpace.getEqualityOperator());
                if (communative && (isAddition || isMultiplication || isEquality)) 
                {
                    var rootAGroups : Array<ExpressionNode> = new Array<ExpressionNode>();
                    ExpressionUtil.getCommutativeGroupRoots(rootA, rootA.data, rootAGroups);
                    var rootBGroups : Array<ExpressionNode> = new Array<ExpressionNode>();
                    ExpressionUtil.getCommutativeGroupRoots(rootB, rootA.data, rootBGroups);
                    
                    match = ExpressionUtil.getExpressionSetsStructurallyEquivalent(rootAGroups, rootBGroups, communative, vectorSpace);
                }
                else 
                {
                    var leftSidesMatch : Bool = ExpressionUtil.getExpressionsStructurallyEquivalent(rootA.left, rootB.left, communative, vectorSpace);
                    var rightSidesMatch : Bool = ExpressionUtil.getExpressionsStructurallyEquivalent(rootA.right, rootB.right, communative, vectorSpace);
                    match = leftSidesMatch && rightSidesMatch;
                }
            }
            else if (rootA.isLeaf() && !rootB.isLeaf() || !rootA.isLeaf() && rootB.isLeaf()) 
            {
                match = false;
            }
        }
        else 
        {
            match = (rootA == null) && (rootB == null);
        }
        return match;
    }
    
    /**
     * Get whether a set of expression subtrees are equal with each other, for every tree
     * in one set there is a structurally identical tree in the other set
     */
    public static function getExpressionSetsStructurallyEquivalent(setA : Array<ExpressionNode>,
            setB : Array<ExpressionNode>,
            communative : Bool,
            vectorSpace : IVectorSpace) : Bool
    {
        var setsIdentical : Bool = false;
        var setASize : Int = setA.length;
        var setBSize : Int = setB.length;
        
        if (setASize == setBSize) 
        {
            var consumedIndices : Dictionary = new Dictionary();
            var consumedCount : Int = 0;
            var i : Int;
            var j : Int;
            
            // Do a brute force sweep of matching subtrees
            for (i in 0...setASize){
                var rootA : ExpressionNode = setA[i];
                var itemMatched : Bool = false;
                for (j in 0...setBSize){
                    var rootB : ExpressionNode = setB[j];
                    
                    // We want to prevent duplicate checking of items. Once an item in setB
                    // has been matched with an item in setA both need to removed from any
                    // further comparisons.
                    if (!consumedIndices.exists(j)) 
                    {
                        if (ExpressionUtil.getExpressionsStructurallyEquivalent(rootA, rootB, communative, vectorSpace)) 
                        {
                            itemMatched = true;
                            consumedIndices[j] = 0;
                            consumedCount++;
                            break;
                        }
                    }
                }  // fail immediately    // If no subtree in setB was able to match with an item in setA we can  
                
                
                
                
                
                if (!itemMatched) 
                {
                    break;
                }
            }
            
            if (consumedCount == setASize) 
            {
                setsIdentical = true;
            }
        }
        
        return setsIdentical;
    }
    
    /**
     * Given two expression subtrees we want to determine how similar they are to one
     * another. To do this we define a distance function that computes a single value about
     * how two expression trees compare to one another.
     * A value of zero means the trees are structured exactly the same.
     * 
     * @return
     *      An integer representing the how different the two expressions are in relation
     *      to each other. The greater the number, the greater the difference. Zero means they are the same.
     */
    public static function getExpressionDistance(expressionA : ExpressionNode,
            expressionB : ExpressionNode) : Int
    {
        // Condition to end recursion
        // a node is null or has no children
        var distance : Int = 0;
        var expressionCountA : Int = ExpressionUtil.nodeCount(expressionA);
        var expressionCountB : Int = ExpressionUtil.nodeCount(expressionB);
        var expressionDifference : Int = Math.abs(expressionCountA - expressionCountB);
        
        // First check that the root nodes are equivalent.
        // If they are not, a distance penalty needs to be incurred. The magnitude depends
        // on the 'type' of the distance
        if (expressionA != null && expressionB != null) 
        {
            var expressionsMatch : Bool = expressionA.data == expressionB.data;
            
            if (!expressionsMatch) 
            {
                // Case for different symbol values
                if (expressionA.isLeaf() && expressionB.isLeaf()) 
                {
                    distance += 5;
                }
                // Case for different operator values
                else if (!expressionA.isLeaf() && !expressionB.isLeaf()) 
                {
                    distance += 5;
                }
                // Case for one being an operator and the other being a symbol
                else 
                {
                    distance += 5;
                }
            }  // This check should occur regardless of whether the expression data matches or not.    // is a subtree of the larger expression)    // We pick the minimum distance of these comparisons. (Essentially checks if the entire smaller expression    // The CHILDREN of the expression with more nodes are compared against other expression.    // If one expression has fewer nodes then there is no way they will be equal to each other  
            
            
            
            
            
            
            
            
            
            
            
            if (expressionDifference != 0) 
            {
                var childLeft : ExpressionNode;
                var childRight : ExpressionNode;
                var subtreeToCheck : ExpressionNode;
                if (expressionCountA > expressionCountB) 
                {
                    childLeft = expressionA.left;
                    childRight = expressionA.right;
                    subtreeToCheck = expressionB;
                }
                else 
                {
                    childLeft = expressionB.left;
                    childRight = expressionB.right;
                    subtreeToCheck = expressionA;
                }
                
                var distanceLeft : Int = ExpressionUtil.getExpressionDistance(childLeft, subtreeToCheck);
                var distanceRight : Int = ExpressionUtil.getExpressionDistance(childRight, subtreeToCheck);
                distance += Math.min(distanceLeft, distanceRight);
            }
            // Case for same number of nodes
            else 
            {
                // We compare sets of expressions
                var expressionSetA : Array<ExpressionNode> = new Array<ExpressionNode>();
                var expressionSetB : Array<ExpressionNode> = new Array<ExpressionNode>();
                
                // If the data are the same:
                // For communative operators we break down the expressions into sets of subtrees
                // (do not look at non-communative because we don't want 3/4 to be the same as 4/3)
                // Run exhaustive comparison of each one of the sets, picking the minimum distance for each one
                // The two matching expressions are removed from consideration
                if (expressionsMatch) 
                {
                    // If non-communative we want to do a regular recursive check
                    var vectorSpace : IVectorSpace = expressionA.vectorSpace;
                    var communativeOperator : Bool = (expressionA.data == vectorSpace.getAdditionOperator()) ||
                    (expressionA.data == vectorSpace.getMultiplicationOperator()) ||
                    (expressionA.data == vectorSpace.getEqualityOperator());
                    if (!communativeOperator) 
                    {
                        // DON'T USE THE SET COMPARE FOR JUST THIS CASE
                        distance += ExpressionUtil.getExpressionDistance(expressionA.left, expressionB.left);
                        distance += ExpressionUtil.getExpressionDistance(expressionA.right, expressionB.right);
                    }
                    else 
                    {
                        // Gather all subtrees belonging to the operator
                        ExpressionUtil.getCommutativeGroupRoots(expressionA, expressionA.data, expressionSetA);
                        ExpressionUtil.getCommutativeGroupRoots(expressionB, expressionA.data, expressionSetB);
                    }
                }
                // If the data does not match:
                // We no longer care about order for ANY operator since we know the overall expression won't match.
                // Do a comparison of all four different children trees (checking if the operator is the only difference)
                // Compare the two children with the entire other tree (checking if one is a subtree).
                // We pick the minimum distance for each child of one of the trees and add it to the total distance
                else 
                {
                    expressionSetA.push(expressionA.left);
                    expressionSetA.push(expressionA.right);
                    
                    expressionSetB.push(expressionB.left);
                    expressionSetB.push(expressionB.right);
                    
                }  // This seems to be the problem area, a minimum child distance of zero is bubbling upwards    // than a greedy search    // TODO: This chunk below should be revised such that it picks the optimal smallest subset rather  
                
                
                
                
                
                
                
                if (expressionSetA.length > 0 && expressionSetB.length > 0) 
                {
                    var i : Int;
                    var j : Int;
                    var minDistance : Int = 0;
                    var minDistanceIndex : Int = -1;
                    var expA : ExpressionNode;
                    var expB : ExpressionNode;
                    var numExpressionsA : Int = expressionSetA.length;
                    for (i in 0...numExpressionsA){
                        expA = expressionSetA[i];
                        var numExpressionsB : Int = expressionSetB.length;
                        for (j in 0...numExpressionsB){
                            expB = expressionSetB[j];
                            var childDistance : Int = ExpressionUtil.getExpressionDistance(expA, expB);
                            if (childDistance < minDistance || minDistanceIndex < 0) 
                            {
                                minDistanceIndex = j;
                                minDistance = childDistance;
                            }
                        }  // The optimal distance is (10 + 5) but we would get (5 + 20) depending on ordering.    // (consider a case where for a set of two expressions in A, the first gets 5 and 10. The second gets 5 and 20,    // This is a greedy solution that may not be optimal in reducing the total distance.    // remove that from consideration for other comparisons    // Pick the expression from the other set that produces the minimum distance  
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        if (minDistanceIndex >= 0) 
                        {
                            expressionSetB.splice(minDistanceIndex, 1);
                            
                            // Reset the min index
                            minDistanceIndex = -1;
                        }
                        distance += minDistance;
                    }
                }
            }
        }
        // If one of the expressions in null we can terminate the search
        // Add a penalty if only one of them is null
        else 
        {
            // Penalty is proportional in how many more nodes exist in the non-null expression if it exists
            var nullPenaltyFactor : Int = 10;
            distance += expressionDifference * nullPenaltyFactor;
        }
        
        return distance;
    }
    
    /**
     * A helper function that counts the total number of nodes within an expression tree
     * structure.
     * 
     * @param root
     * @param onlyLeaves
     *      If true, count only the leaf nodes
     */
    public static function nodeCount(root : ExpressionNode, onlyLeaves : Bool = false) : Int
    {
        var count : Int = 0;
        if (root != null) 
        {
            count = nodeCount(root.left, onlyLeaves) + nodeCount(root.right, onlyLeaves);
            if (!onlyLeaves || root.isLeaf()) 
            {
                count += 1;
            }
        }
        
        return count;
    }
    
    /**
     * Get back an ordered list of nodes that is takes to traverse upwards from
     * a starting node to an end node.
     * 
     * @return
     *      Empty list if there is no path. Otherwise the path from start to end, which
     *      does not include the start node but does include the end node.
     */
    public static function getPathUpToNode(startNode : ExpressionNode,
            endNode : ExpressionNode) : Array<ExpressionNode>
    {
        var path : Array<ExpressionNode> = new Array<ExpressionNode>();
        
        if (startNode != null && endNode != null) 
        {
            var trackerNode : ExpressionNode = startNode.parent;
            var continueSearch : Bool = true;
            while (continueSearch)
            {
                if (trackerNode == endNode) 
                {
                    path.push(trackerNode);
                    continueSearch = false;
                }
                else if (trackerNode.parent == null) 
                {
                    as3hx.Compat.setArrayLength(path, 0);
                    continueSearch = false;
                }
                else 
                {
                    path.push(trackerNode);
                    trackerNode = trackerNode.parent;
                }
            }
        }
        
        return path;
    }
    
    /**
     * The lowest common ancestor is the node first similar node we encounter if we
     * take paths from two nodes up to the root
     * 
     * @param nodeA
     * @param nodeB
     * @return
     *         The lowest common ancestor, if the given nodes are part of the same tree
     *         this should always return at least the root
     */
    public static function findLowestCommonAncestor(nodeA : ExpressionNode,
            nodeB : ExpressionNode) : ExpressionNode
    {
        var pathA : Array<ExpressionNode> = findPathToRoot(nodeA);
        var pathB : Array<ExpressionNode> = findPathToRoot(nodeB);
        var commonAncestor : ExpressionNode = null;
        
        var pathsDiverged : Bool = false;
        while (pathA.length > 0 && pathB.length > 0 && !pathsDiverged)
        {
            var nodePathA : ExpressionNode = pathA.pop();
            var nodePathB : ExpressionNode = pathB.pop();
            if (nodePathA == nodePathB) 
            {
                commonAncestor = nodePathA;
            }
            else 
            {
                pathsDiverged = true;
            }
        }
        if (nodeA == nodeB) 
        {
            commonAncestor = nodeA;
        }
        
        return commonAncestor;
    }
    
    private static function findPathToRoot(node : ExpressionNode) : Array<ExpressionNode>
    {
        var path : Array<ExpressionNode> = new Array<ExpressionNode>();
        while (node.parent != null)
        {
            path.push(node.parent);
            node = node.parent;
        }
        
        return path;
    }
    
    /**
     * An example case is a/b*c should look like a*c/b instead
     * 
     * This function still respects parentheses and will not try to push if ordering
     * is violated.
     * 
     * IMPORTANT: Note that the initial node pointer passed in may no longer be the root
     * at the end of the function call.
     */
    public static function pushDivisionNodesUpward(node : ExpressionNode,
            vectorSpace : IVectorSpace) : Void
    {
        if (node != null && !node.isLeaf()) 
        {
            pushDivisionNodesUpward(node.left, vectorSpace);
            pushDivisionNodesUpward(node.right, vectorSpace);
            
            if (node.isSpecificOperator(vectorSpace.getMultiplicationOperator())) 
            {
                if (node.left.isSpecificOperator(vectorSpace.getDivisionOperator()) && !node.left.wrapInParentheses) 
                {
                    var divisionNodeToShift : ExpressionNode = node.left;
                    var numeratorNode : ExpressionNode = divisionNodeToShift.left;
                    divisionNodeToShift.left = node;
                    
                    // Attach the division node to the parent
                    var parentOfNode : ExpressionNode = node.parent;
                    if (parentOfNode != null) 
                    {
                        if (parentOfNode.left == node) 
                        {
                            parentOfNode.left = divisionNodeToShift;
                        }
                        else 
                        {
                            parentOfNode.right = divisionNodeToShift;
                        }
                    }
                    divisionNodeToShift.parent = parentOfNode;
                    
                    // The current multiplication node should multiply the numerator with its right child
                    node.left = numeratorNode;
                    numeratorNode.parent = node;
                    node.parent = divisionNodeToShift;
                }  // i.e. we wanted it in the form a*c/b in the first place    // No need to swap around the right child since precedence rules work correctly in this case  
            }
        }
    }
    
    /**
     * In an expression tree, parentheses are implicit in the structure of the tree so there is never ambiguity
     * about how to evaluate. However, depending on how the tree is displayed this single distinct path may not
     * be apparent to the player, which is why parentheses need to be drawn.
     * 
     * Each individual node has no knowledge that they should wrap their contents in parentheses, since the times
     * where it necessary depend on the orientation of a node and its parent operator
     * 
     * This function explicitly marks nodes as needing parentheses when they are drawn to avoid possible evaluation
     * ordering issues when the player view the expression
     * 
     * @param node
     *      root node of the subtree to add necessary parens to. Important to note that no parens may need to be added,
     *      for example if the tree is just several terms added together then ordering makes no difference.
     * @param vectorSpace
     * 
     */
    public static function addImplicitParentheses(node : ExpressionNode,
            vectorSpace : IVectorSpace) : Void
    {
        if (node != null) 
        {
            // If we have an operator that has a parent operator that is not already wrapped in a set of parentheses...
            if (node.isOperator() && node.parent != null && !node.wrapInParentheses) 
            {
                // There are two cases where parens are needed
                // First: The precedence of the operator and a parent operator is lower than that of the parent operator
                // ex.) (a+b)*c or a/(b-c)
                
                // Second: The precedence of the operator is the same as the parent AND the parent operator is not
                // associative AND the operator is the right child. You can think of this the left to right eval rule.
                // ex.) a-(b+c) or a/(b*c)
                var parentOperatorNode : ExpressionNode = node.parent;
                var thisPrecedence : Int = vectorSpace.getOperatorPrecedence(node.data);
                var parentPrecedence : Int = vectorSpace.getOperatorPrecedence(parentOperatorNode.data);
                if (thisPrecedence == parentPrecedence) 
                {
                    node.wrapInParentheses = !vectorSpace.getOperatorIsAssociative(parentOperatorNode.data) && parentOperatorNode.right == node;
                }
                else 
                {
                    node.wrapInParentheses = thisPrecedence < parentPrecedence;
                }
            }  // Check the children  
            
            
            
            addImplicitParentheses(node.left, vectorSpace);
            addImplicitParentheses(node.right, vectorSpace);
        }
    }
    
    /**
     * Create a copy of a given subtree
     * 
     * @return
     *      A copy of the subtree root that was given.
     */
    public static function copy(originalNode : ExpressionNode, vectorSpace : IVectorSpace) : ExpressionNode
    {
        var nodeCopy : ExpressionNode;
        if (originalNode != null) 
        {
            nodeCopy = originalNode.clone();
            var leftCopy : ExpressionNode = copy(originalNode.left, vectorSpace);
            if (leftCopy != null) 
            {
                leftCopy.parent = nodeCopy;
                nodeCopy.left = leftCopy;
            }
            
            var rightCopy : ExpressionNode = copy(originalNode.right, vectorSpace);
            if (rightCopy != null) 
            {
                rightCopy.parent = nodeCopy;
                nodeCopy.right = rightCopy;
            }
        }
        
        return nodeCopy;
    }
    
    /**
     * Retrieves all terminal nodes is a given subtree
     * 
     * @param outNodes
     *      An output list that will contain all terminal nodes
     */
    public static function getLeafNodes(node : ExpressionNode,
            outNodes : Array<ExpressionNode>) : Void
    {
        if (node != null) 
        {
            if (node.isLeaf()) 
            {
                outNodes.push(node);
            }
            else 
            {
                ExpressionUtil.getLeafNodes(node.left, outNodes);
                ExpressionUtil.getLeafNodes(node.right, outNodes);
            }
        }
    }
    
    /**
     * From a starting root node retrieve the subtrees that have been combined together with
     * particular operator that are as high up as possible. Note that this respects the parentheses
     * so that an operator wrapped in parentheses will return the entire wrapped subtree
     */
    public static function getCommutativeGroupRoots(node : ExpressionNode,
            operator : String,
            outGroupRoots : Array<ExpressionNode>) : Void
    {
        _getCommutativeGroupRoots(node, operator, outGroupRoots, false);
    }
    
    private static function _getCommutativeGroupRoots(node : ExpressionNode,
            operator : String,
            outGroupRoots : Array<ExpressionNode>,
            stopAtParenthesis : Bool) : Void
    {
        if (node != null) 
        {
            if (node.isSpecificOperator(operator) && (!stopAtParenthesis || !node.wrapInParentheses)) 
            {
                _getCommutativeGroupRoots(node.left, operator, outGroupRoots, true);
                _getCommutativeGroupRoots(node.right, operator, outGroupRoots, true);
            }
            else 
            {
                outGroupRoots.push(node);
            }
        }
    }
    
    public static function containsNode(root : ExpressionNode, nodeToFind : ExpressionNode) : Bool
    {
        var hasNode : Bool = false;
        if (root != null) 
        {
            if (root == nodeToFind) 
            {
                hasNode = true;
            }
            else 
            {
                hasNode = containsNode(root.left, nodeToFind) || containsNode(root.right, nodeToFind);
            }
        }
        
        return hasNode;
    }
    
    /**
     * Get whether a node in a subtree contains a specific id
     * 
     * @param id
     *         The id value to check for
     * @param root
     *         The node that is the root of a subtree to check against
     * @return 
     *         True if the node in the subtree has a matching id
     */
    public static function containsId(id : Int, root : ExpressionNode) : Bool
    {
        return getNodeById(id, root) != null;
    }
    
    /**
     * Get the node in a subtree contains a specific id
     * 
     * @param id
     *         The id value to check for
     * @param root
     *         The node that is the root of a subtree to check against
     * @return 
     *         The node with the matching id, null if none match
     */
    public static function getNodeById(id : Int, root : ExpressionNode) : ExpressionNode
    {
        var matchingNode : ExpressionNode = null;
        if (root != null) 
        {
            if (root.id == id) 
            {
                matchingNode = root;
            }
            else 
            {
                matchingNode = getNodeById(id, root.left);
                
                if (matchingNode == null) 
                {
                    matchingNode = getNodeById(id, root.right);
                }
            }
        }
        
        return matchingNode;
    }
    
    /**
     * @return
     *         True if the given node is in a denominator or numerator of an explicit
     *         fraction node.
     */
    public static function isNodePartOfFraction(vectorSpace : IVectorSpace,
            node : ExpressionNode) : Bool
    {
        var isPartOfFraction : Bool = false;
        if (node != null) 
        {
            var nodeParent : ExpressionNode = node.parent;
        }
        while (nodeParent != null)
        {
            if (nodeParent.isSpecificOperator(vectorSpace.getDivisionOperator())) 
            {
                isPartOfFraction = true;
                break;
            }
            else 
            {
                nodeParent = nodeParent.parent;
            }
        }
        return isPartOfFraction;
    }
    
    /**
     * @return
     *         True if the given node is part of a denominator in the smallest fraction
     *         subtree it could be in.
     */
    public static function isNodePartOfDenominator(vectorSpace : IVectorSpace,
            node : ExpressionNode) : Bool
    {
        var isPartOfDenominator : Bool = false;
        
        if (ExpressionUtil.isNodePartOfFraction(vectorSpace, node)) 
        {
            var divisionNodeChild : ExpressionNode = node;
            while (!divisionNodeChild.parent.isSpecificOperator(vectorSpace.getDivisionOperator()))
            {
                divisionNodeChild = divisionNodeChild.parent;
            }
            
            isPartOfDenominator = (divisionNodeChild.parent.right == divisionNodeChild);
        }
        return isPartOfDenominator;
    }
    
    public static function wildCardNodeExists(node : ExpressionNode) : Bool
    {
        var wildCardExists : Bool = false;
        if (node != null) 
        {
            if (node.isOperator()) 
            {
                wildCardExists = wildCardNodeExists(node.left) || wildCardNodeExists(node.right);
            }
            else if (node.isLeaf()) 
            {
                wildCardExists = (Std.is(node, WildCardNode));
            }
        }
        
        return wildCardExists;
    }
    
    /**
     * Given an expression subtree, this function extracts all unique leaf symbols
     * present in that subtree.
     * 
     * Note that it by default ignores wild cards and zero values.
     * 
     * @param negativesUnique
     *      If false, then we treat a value and its negative as the same symbol. If we encounter a (-x) first
     *      then we will not later add (x) if we encounter it
     *      If true we treat them as separate symbols, potentially adding both (x) and (-x) in the results.
     * @return
     *         A list of symbol names
     */
    public static function getUniqueSymbols(subtrees : Array<ExpressionNode>,
            vectorSpace : IVectorSpace,
            negativesUnique : Bool) : Array<String>
    {
        // Figure out what symbols should be placed into the deck for the solving game
        // Currently just dumping all unique symbol type found in the expression to solve
        var i : Int;
        var subtreeRoot : ExpressionNode;
        var leafNodes : Array<ExpressionNode> = new Array<ExpressionNode>();
        var uniqueSymbols : Dictionary = new Dictionary();
        var uniqueSymbolList : Array<String> = new Array<String>();
        var numSubtrees : Int = subtrees.length;
        for (i in 0...numSubtrees){
            subtreeRoot = subtrees[i];
            
            // Append leaves of the next subtree into the set of leaf nodes
            ExpressionUtil.getLeafNodes(subtreeRoot, leafNodes);
        }  // Iterate through every leaf node and extract the unique symbols amongst all of them  
        
        
        
        var symbol : String;
        var oppositeSymbol : String;
        for (leafNode in leafNodes)
        {
            symbol = leafNode.data;
            
            // Ignore zero and wild card values
            if (symbol != vectorSpace.zero() && symbol.indexOf("?") == -1) 
            {
                // Check that the results dictionary does not already contain the value
                if (!uniqueSymbols.exists(symbol)) 
                {
                    // If we ignore the uniqueness of a value and its negative, we also check whether
                    // the opposite value of the symbol exists
                    if (!negativesUnique && !uniqueSymbols.exists(leafNode.getOppositeValue()) ||
                        negativesUnique) 
                    {
                        Reflect.setField(uniqueSymbols, symbol, true);
                        uniqueSymbolList.push(symbol);
                    }
                }
            }
        }
        
        return uniqueSymbolList;
    }
    
    /**
     * Get the set of nodes that have been wrapped in parentheses.
     */
    public static function getNodesWrappedInParentheses(node : ExpressionNode,
            outNodes : Array<ExpressionNode>) : Void
    {
        if (node != null) 
        {
            if (node.wrapInParentheses) 
            {
                outNodes.push(node);
            }
            
            getNodesWrappedInParentheses(node.left, outNodes);
            getNodesWrappedInParentheses(node.right, outNodes);
        }
    }
    
    /**
     * Get whether a node is purely numeric.
     * rad 11/7/13 added null check
     */
    public static function isNodeNumeric(node : ExpressionNode) : Bool
    {
        var numericRegex : EReg = ExpressionUtil.NUMERIC_REGEX;
        if (node != null) {
            return node.data.search(numericRegex) == 0;
        }
        else {
            return false;
        }
    }
    
    /**
     * Get whether a node is purely numeric.
     * rad 11/7/13 added null check
     */
    public static function isVariableNode(node : ExpressionNode) : Bool
    {
        var variableRegex : EReg = ExpressionUtil.VARIABLE_REGEX;
        if (node != null) {
            return node.data.search(variableRegex) == 0;
        }
        else {
            return false;
        }
    }
    
    /**
     * Check whether a tree has leaf subtrees and represents a simple factor of a variable.
     * E.g. 2*x or 5*x
     * rad 11/8/13 
     */
    public static function isNodeAVariableFactor(aNode : ExpressionNode) : Bool
    {
        var isFactor : Bool = false;
        
        if ((aNode != null) && (aNode.data == aNode.vectorSpace.getMultiplicationOperator()) &&
            (aNode.left.isLeaf() && aNode.right.isLeaf()) &&
            ((isNodeNumeric(aNode.left) && isVariableNode(aNode.right)) || (isNodeNumeric(aNode.right) && isVariableNode(aNode.left)))) {
            isFactor = true;
        }
        return isFactor;
    }
    
    /**
     * Having checked whether a tree has leaf subtrees and represents a simple factor of a variable.
     * E.g. 2*x or 5*x
     * return the name of the variable in the factor
     * rad 11/8/13 
     */
    public static function getVariableFactorName(aNode : ExpressionNode) : String
    {
        
        if (isVariableNode(aNode.left)) {
            return aNode.left.data;
        }
        else if (isVariableNode(aNode.right)) {
            return aNode.right.data;
        }
        return null;
    }
    
    /**
     * Having checked whether a tree has leaf subtrees and represents a simple factor of a variable.
     * E.g. 2*x or 5*x
     * return the multiple of the variable in the factor
     * rad 11/8/13 
     */
    public static function getVariableFactorMultiple(aNode : ExpressionNode) : String
    {
        
        if (isNodeNumeric(aNode.left)) {
            return aNode.left.data;
        }
        else if (isNodeNumeric(aNode.right)) {
            return aNode.right.data;
        }
        return null;
    }
    
    /**
     * This function checks whether it is plausible for two given
     * nodes to be summed together to produce a single real result.
     * 
     * Some important notes:
     * Unless both nodes represent real numbers, addition of a symbolic node
     * only makes sense if its a symbol combined with negative counterpart to
     * produce 0.
     * 
     * @param allowNumericSimplify
     *         If true, then we will allow 
     * 
     * returns 
     *         true, if fromNode can add to toNode
     */
    public static function canAddNode(nodeA : ExpressionNode,
            nodeB : ExpressionNode,
            vectorSpace : IVectorSpace,
            allowNumericSimplify : Bool = true) : Bool
    {
        if (nodeA == nodeB) 
        {
            return false;
        }
        
        var fromNode : ExpressionNode = nodeA;
        var toNode : ExpressionNode = nodeB;
        
        var canAdd : Bool = true;
        var lca : ExpressionNode = ExpressionUtil.findLowestCommonAncestor(fromNode, toNode);
        fromNode = fromNode.parent;
        toNode = toNode.parent;
        if (lca.data != vectorSpace.getAdditionOperator()) 
        {
            canAdd = false;
        }
        while (fromNode != lca)
        {
            if (fromNode.data != vectorSpace.getAdditionOperator()) 
            {
                canAdd = false;
                break;
            }
            fromNode = fromNode.parent;
        }
        while (toNode != lca)
        {
            if (toNode.data != vectorSpace.getAdditionOperator()) 
            {
                canAdd = false;
                break;
            }
            toNode = toNode.parent;
        }  // If we find the nodes are joined by an add, we now check whether they are numeric  
        
        
        
        if (canAdd) 
        {
            
            var nodeANumeric : Bool = isNodeNumeric(nodeA);
            var nodeBNumeric : Bool = isNodeNumeric(nodeB);
            
            // We will always allow the cancellation of a symbol with its negative,
            // even if it is a number
            var nodeANegative : Bool = (nodeA.data.charAt(0) == vectorSpace.getSubtractionOperator());
            if (nodeANegative) 
            {
                canAdd = (nodeA.data.substr(1) == nodeB.data);
            }
            else 
            {
                canAdd = (nodeA.data == nodeB.data.substr(1));
            }
            
            if (!canAdd) 
            {
                if (nodeANumeric && nodeBNumeric) 
                {
                    canAdd = allowNumericSimplify;
                }
                else if (!nodeANumeric && !nodeBNumeric) 
                {
                    canAdd = (nodeA.data == nodeB.data);
                }
            }
        }
        
        return canAdd;
    }
    
    
    /**
     * Check whether expressions like '3 + (4*x) + 2' can be transformed into '4*x + 5', and go ahead and make the simplification.
     * See also the following similar function below, simplifyCommonFactors(..), which, with similar structure and logic collapses common factors of a single variable.
     * 
     * Warning: These functions work for the most common cases, but with expressions of sufficient complexity, the search is limited and common Numeric terms 
     * or common factors of a variable may not get completely collapsed to their simplest forms.  
     * 
     * returns 
     *         aNode simplified by substituting one numeric value by combining its numeric children.
     */
    public static function simplifyNumericLeaves(aNode : ExpressionNode) : ExpressionNode
    {
        var simpleNode : ExpressionNode = aNode;  //Does this destructively modify the original Node?  If so, BADBAD!  
        if (aNode != null && !aNode.isLeaf()) 
        {
            if (isNodeNumeric(aNode.left) && isNodeNumeric(aNode.right)) {
                simpleNode = collapseTwoValueNodesIntoOne(aNode.left, aNode.data, aNode.right);
            }
            else {
                aNode.left = ExpressionUtil.simplifyNumericLeaves(aNode.left);
                aNode.right = ExpressionUtil.simplifyNumericLeaves(aNode.right);
                
                if (isNodeNumeric(aNode.right)) {  //simplifications below may now allow simplifications at this level  
                    if (isNodeNumeric(aNode.left)) {  //the subtrees collapsed to simple numeric nodes, so collapse them again now  
                        simpleNode = collapseTwoValueNodesIntoOne(aNode.left, aNode.data, aNode.right);
                    }
                    // check for a situation like "3 + x + 4".  Do this by identifying a numeric leaf on the right and a one in the subtree on the left, and the identical operators at the two levels
                    else {
                        if (!aNode.left.isLeaf()) {  //the left holds a subtree  
                            if (aNode.left.left != null && isNodeNumeric(aNode.left.left) && (aNode.data == aNode.left.data)) {  // and there is the same operator at both levels  
                                aNode.right = collapseTwoValueNodesIntoOne(aNode.left.left, aNode.data, aNode.right);  //collapse left.right and right  
                                aNode.left = aNode.left.right;  // and raise the variable node up a level  
                                return aNode;
                            }
                            if (aNode.left.right != null && isNodeNumeric(aNode.left.right) && (aNode.data == aNode.left.data)) {  // and there is the same operator at both levels  
                                aNode.right = collapseTwoValueNodesIntoOne(aNode.left.right, aNode.data, aNode.right);  //collapse left.left and right  
                                aNode.left = aNode.left.left;  // and raise the variable node up a level  
                                return aNode;
                            }
                        }
                    }
                }
                return simpleNode;
            }
        }
        return simpleNode;
    }
    
    public static function simplifiedNumericLeavesValue(root : ExpressionNode) : ExpressionNode
    {
        var simpleNode : ExpressionNode = simplifyNumericLeaves(root);
        if (isNodeNumeric(simpleNode)) {
            return simpleNode;
        }
        if (!simpleNode.isLeaf()) {
            if (isNodeNumeric(simpleNode.left)) {
                return simpleNode.left;
            }
            if (isNodeNumeric(simpleNode.right)) {
                return simpleNode.right;
            }
        }
        return simpleNode;
    }
    /**
     * Check whether expressions like '3*x + (4*5) + 2*x' can be transformed into '5*x + 20', and go ahead and make the simplification.
     * 
     * See also the following similar function above, simplifyNumericLeaves(..), which, with similar structure and logic collapses common factors of a single variable.
     * 
     * Warning: These functions work for the most common cases, but with expressions of sufficient complexity, the search is limited and common Numeric terms 
     * or common factors of a variable may not get completely collapsed to their simplest forms.  
     * 
     * returns 
     *         aNode simplified by substituting one numeric value by combining its numeric children.
     */
    public static function simplifyCommonFactors(aNode : ExpressionNode) : ExpressionNode
    {
        var simpleNode : ExpressionNode = aNode;
        if (aNode != null && !aNode.isLeaf()) 
        {
            if ((isNodeAVariableFactor(aNode.left) && isNodeAVariableFactor(aNode.right)) &&
                (getVariableFactorName(aNode.left) == getVariableFactorName(aNode.right))) {  //check whether we have factor subtrees with the same variable. e.g. 3*x and 4*x  
                simpleNode = AddTwoFactorNodesIntoOne(aNode.left, aNode.data, aNode.right);
            }
            else {
                aNode.right = ExpressionUtil.simplifyCommonFactors(aNode.right);  //recurse now that top level collapse has occured  
                aNode.left = ExpressionUtil.simplifyCommonFactors(aNode.left);
                if (isNodeAVariableFactor(aNode.right)) {
                    var collapsedSubTrees : ExpressionNode;
                    if (isNodeAVariableFactor(aNode.left.left)) {  //need to peek down another level into subtrees  
                        collapsedSubTrees = AddTwoFactorNodesIntoOne(aNode.left.left, aNode.data, aNode.right);
                        simpleNode = new ExpressionNode(aNode.vectorSpace, aNode.data);
                        simpleNode.right = aNode.left.right;
                        simpleNode.left = collapsedSubTrees;
                    }
                    if (isNodeAVariableFactor(aNode.left.right)) {
                        collapsedSubTrees = AddTwoFactorNodesIntoOne(aNode.left.right, aNode.data, aNode.right);
                        simpleNode = new ExpressionNode(aNode.vectorSpace, aNode.data);
                        simpleNode.right = aNode.left.left;
                        simpleNode.left = collapsedSubTrees;
                    }
                }
                return simpleNode;
            }
        }
        return simpleNode;
    }
    
    /**
     * Helper function to simplifyNumericLeaves above.
     * Perform the specified operation on two numeric nodes (which may be in different levels in the tree) and 
     * return a single numeric node with the new combined value.
     */
    public static function collapseTwoValueNodesIntoOne(leftNode : ExpressionNode, op : String, rightNode : ExpressionNode) : ExpressionNode
    {
        switch (op)
        {
            case leftNode.vectorSpace.getAdditionOperator():
                return new ExpressionNode(leftNode.vectorSpace, Std.string((Std.parseFloat(Std.string(leftNode)) + Std.parseFloat(Std.string(rightNode)))));
            case leftNode.vectorSpace.getSubtractionOperator():
                return new ExpressionNode(leftNode.vectorSpace, Std.string((Std.parseFloat(Std.string(leftNode)) - Std.parseFloat(Std.string(rightNode)))));
            case leftNode.vectorSpace.getMultiplicationOperator():
                return new ExpressionNode(leftNode.vectorSpace, Std.string((Std.parseFloat(Std.string(leftNode)) * Std.parseFloat(Std.string(rightNode)))));
            case leftNode.vectorSpace.getDivisionOperator():
                return new ExpressionNode(leftNode.vectorSpace, Std.string((Std.parseFloat(Std.string(leftNode)) / Std.parseFloat(Std.string(rightNode)))));
            default:trace("Illegal operator, or tree case I haven't handled yet");
                return null;
        }
    }
    
    /**
     * Helper function to simplifyCommonFactors above.
     * Perform the specified operation on two subtrees nodes (which may be in different levels in the tree) which represent factors of a common variable and 
     * return a single binary node with the new combined value of the factor and the variable.
     */
    
    public static function AddTwoFactorNodesIntoOne(leftNode : ExpressionNode, op : String, rightNode : ExpressionNode) : ExpressionNode
    {
        var newNode : ExpressionNode = new ExpressionNode(leftNode.vectorSpace, leftNode.vectorSpace.getMultiplicationOperator());  //the new node will be a factor of a variable too.  
        var varName : String = getVariableFactorName(leftNode);
        
        newNode.right = new ExpressionNode(leftNode.vectorSpace, varName);  //the variable name should be on the right  
        
        if (op == leftNode.vectorSpace.getAdditionOperator()) {
            newNode.left = new ExpressionNode(leftNode.vectorSpace, Std.string((Std.parseFloat(getVariableFactorMultiple(leftNode)) + Std.parseFloat(getVariableFactorMultiple(rightNode)))));
        }
        if (op == leftNode.vectorSpace.getMultiplicationOperator()) {
            trace("Illegal multiply. We should only add factors");
            newNode.right = new ExpressionNode(leftNode.vectorSpace, newNode.right.data + "_squared");
            newNode.left = new ExpressionNode(leftNode.vectorSpace, Std.string((Std.parseFloat(getVariableFactorMultiple(leftNode)) * Std.parseFloat(getVariableFactorMultiple(rightNode)))));
        }
        return newNode;
    }
    
    /**
     * Checks whether two nodes in an expression can be multiplied together in
     * a way that alters the current structure of the expression.
     * 
     * returns 
     *         true, if fromNode can time toNode
     */
    public static function canMultiplyNode(nodeA : ExpressionNode,
            nodeB : ExpressionNode,
            vectorSpace : IVectorSpace,
            allowNumericSimplify : Bool = true) : Bool
    {
        if (nodeA == nodeB) 
        {
            return false;
        }
        
        var canMultiply : Bool = true;
        var fromNode : ExpressionNode = nodeA;
        var toNode : ExpressionNode = nodeB;
        var lca : ExpressionNode = ExpressionUtil.findLowestCommonAncestor(fromNode, toNode);
        if (lca.data != vectorSpace.getMultiplicationOperator()) 
        {
            canMultiply = false;
        }
        while (fromNode != lca)
        {
            if (fromNode.parent.data == vectorSpace.getDivisionOperator()) 
            {
                if (fromNode.parent.right == fromNode) 
                {
                    canMultiply = false;
                    break;
                }
            }
            else if (fromNode.parent.data != vectorSpace.getMultiplicationOperator()) 
            {
                canMultiply = false;
                break;
            }
            fromNode = fromNode.parent;
        }
        
        while (toNode.parent != lca)
        {
            if (toNode.parent.data == vectorSpace.getDivisionOperator()) 
            {
                if (toNode.parent.right == toNode) 
                {
                    return false;
                }
            }
            else if (toNode.parent.data != vectorSpace.getMultiplicationOperator()) 
            {
                canMultiply = false;
            }
            toNode = toNode.parent;
        }
        
        if (canMultiply) 
        {
            var nodeANumeric : Bool = isNodeNumeric(nodeA);
            var nodeBNumeric : Bool = isNodeNumeric(nodeB);
            if (nodeANumeric && nodeBNumeric) 
            {
                canMultiply = allowNumericSimplify;
            }
            else 
            {
                // If at least one node is not numeric then it only makes sense
                // to multiply if it is by a 1, -1, or 0 to produce a new value
                if (nodeANumeric) 
                {
                    canMultiply = Std.parseFloat(nodeA.data) == vectorSpace.identity();
                }
                else if (nodeBNumeric) 
                {
                    canMultiply = Std.parseFloat(nodeB.data) == vectorSpace.identity();
                }
                else 
                {
                    canMultiply = false;
                }
            }
        }
        
        return canMultiply;
    }
    
    /**
     * Checks whether two nodes can be divided in a way that will alter the
     * structure of the tree. (For example in 3/2, the number can technically divide
     * but neither value alter the tree)
     * 
     * returns 
     *         true, if fromNode can divide toNode
     */
    public static function canDivideNode(nodeA : ExpressionNode,
            nodeB : ExpressionNode,
            vectorSpace : IVectorSpace,
            allowNumericSimplify : Bool = true) : Bool
    {
        if (nodeA == nodeB) 
        {
            return false;
        }
        
        var canDivide : Bool = true;
        
        // One node must be part of a numerator and another must be part of a denominator
        var aIsDenom : Bool = ExpressionUtil.isNodePartOfDenominator(vectorSpace, nodeA);
        var bIsDenom : Bool = ExpressionUtil.isNodePartOfDenominator(vectorSpace, nodeB);
        if (aIsDenom && bIsDenom || !aIsDenom && !bIsDenom) 
        {
            return false;
        }  // division as far up as possible    // operator. The latter case would occur in instances like (3*b)*(a/3). Could be avoid if we bubble the    // Two divideable nodes have a common ancestor that is either a division or a multiplication  
        
        
        
        
        
        
        
        var lca : ExpressionNode = ExpressionUtil.findLowestCommonAncestor(nodeA, nodeB);
        if (!lca.isSpecificOperator(vectorSpace.getDivisionOperator()) &&
            !lca.isSpecificOperator(vectorSpace.getMultiplicationOperator())) 
        {
            return false;
        }
        
        var nodeATracer : ExpressionNode = nodeA;
        while (nodeATracer != lca)
        {
            if (nodeATracer.parent == lca) 
            {
                break;
            }
            
            if (!aIsDenom && nodeATracer.parent.data != vectorSpace.getMultiplicationOperator()) 
            {
                canDivide = false;
                break;
            }
            else if (aIsDenom && (nodeATracer.parent.data != vectorSpace.getMultiplicationOperator() && nodeATracer.parent.data != vectorSpace.getDivisionOperator())) 
            {
                canDivide = false;
                break;
            }
            nodeATracer = nodeATracer.parent;
        }
        
        var nodeBTracer : ExpressionNode = nodeB;
        while (nodeBTracer != lca)
        {
            if (nodeBTracer.parent == lca) 
            {
                break;
            }
            
            if (!bIsDenom && nodeBTracer.parent.data != vectorSpace.getMultiplicationOperator()) 
            {
                canDivide = false;
                break;
            }
            else if (bIsDenom && (nodeBTracer.parent.data != vectorSpace.getMultiplicationOperator() && nodeBTracer.parent.data != vectorSpace.getDivisionOperator())) 
            {
                canDivide = false;
                break;
            }
            nodeBTracer = nodeBTracer.parent;
        }
        
        if (canDivide) 
        {
            var nodeANumeric : Bool = isNodeNumeric(nodeA);
            var nodeBNumeric : Bool = isNodeNumeric(nodeB);
            
            if (nodeA.data == nodeB.data) 
            {
                canDivide = true;
            }
            else if (nodeANumeric && nodeBNumeric) 
            {
                if (allowNumericSimplify) 
                {
                    var gcd : Int = MathUtil.greatestCommonDivisor(Std.parseFloat(nodeA.data), Std.parseFloat(nodeB.data));
                    canDivide = (gcd != vectorSpace.identity() || (bIsDenom && Std.parseFloat(nodeB.data) == vectorSpace.identity() || aIsDenom && Std.parseFloat(nodeA.data) == vectorSpace.identity()));
                }
                else 
                {
                    canDivide = false;
                }
            }
            else 
            {
                // Otherwise the only way to divide is if the denominator is a one
                canDivide = (aIsDenom && Std.parseFloat(nodeA.data) == vectorSpace.identity() ||
                        bIsDenom && Std.parseFloat(nodeB.data) == vectorSpace.identity());
            }
        }
        return canDivide;
    }
    
    /**
     * Create a new tree structure given the subtrees for the left and right
     * sides and the parent operator. Note that this creates brand new copies
     * of the left and right tree.
     * 
     * @return
     *      The root node with given operator joining copies of the left and right
     *      subtrees.
     */
    public static function createOperatorTree(leftNode : ExpressionNode,
            rightNode : ExpressionNode,
            vectorSpace : IVectorSpace,
            operatorName : String) : ExpressionNode
    {
        var rootOperator : ExpressionNode = new ExpressionNode(vectorSpace, operatorName);
        
        if (leftNode != null) 
        {
            var leftCopy : ExpressionNode = ExpressionUtil.copy(leftNode, vectorSpace);
            rootOperator.left = leftCopy;
            leftCopy.parent = rootOperator;
        }
        
        if (rightNode != null) 
        {
            var rightCopy : ExpressionNode = ExpressionUtil.copy(rightNode, vectorSpace);
            rootOperator.right = rightCopy;
            rightCopy.parent = rootOperator;
        }
        
        return rootOperator;
    }
    
    /**
     * Given a list of subtrees, compress them into a single tree, each one joined by an equality.
     * Nodes passed in are not modified, copies are created.
     * 
     * @return
     *      Root of the new subtree
     */
    public static function compressToSingleTree(nodes : Array<ExpressionNode>, vectorSpace : IVectorSpace) : ExpressionNode
    {
        // Create a stack of valid expressions that represent each term area
        // We join together all non-null expression with an equality and then
        // pass that as an argument to the event
        
        // Splice out the null values
        var i : Int;
        var numNodes : Int = nodes.length;
        var expressionsStack : Array<ExpressionNode> = new Array<ExpressionNode>();
        for (i in 0...numNodes){
            if (nodes[i] != null) 
            {
                expressionsStack.push(nodes[i]);
            }
        }
        
        var root : ExpressionNode = null;
        if (expressionsStack.length > 1) 
        {
            root = expressionsStack.pop();
            while (expressionsStack.length > 0)
            {
                root = ExpressionUtil.createOperatorTree(
                                expressionsStack.pop(),
                                root,
                                vectorSpace,
                                vectorSpace.getEqualityOperator()
                                );
            }
        }
        else if (expressionsStack.length == 1) 
        {
            // If only one node was found, we just create a copy of it
            root = ExpressionUtil.copy(expressionsStack.pop(), vectorSpace);
        }
        
        return root;
    }
    
    /**
     * Remove a particular node from a given subtree
     * 
     * @return
     *      The new root of the subtree
     */
    public static function removeNode(root : ExpressionNode, node : ExpressionNode) : ExpressionNode
    {
        // If the node is the root the tree is basically destroyed
        if (node == root) 
        {
            root = null;
        }
        else 
        {
            // The parent operator tied to the deleted node gets deleted as well
            var parentOfDeletedNode : ExpressionNode = node.parent;
            
            // If the node's parent is the root then the sibling becomes the new root
            if (node.parent == root) 
            {
                var isSiblingLeft : Bool = (parentOfDeletedNode.right == node);
                var sibling : ExpressionNode = ((isSiblingLeft)) ? parentOfDeletedNode.left : parentOfDeletedNode.right;
                sibling.parent = null;
                sibling.wrapInParentheses = (parentOfDeletedNode.wrapInParentheses || sibling.wrapInParentheses);
                
                parentOfDeletedNode.left = null;
                parentOfDeletedNode.right = null;
                root = sibling;
            }
            // The sibling of the removed node becomes a child of the grandparent (if it existed)
            else 
            {
                var deletedNodeIsLeft : Bool = (parentOfDeletedNode.left == node);
                
                var grandparentOfDeletedNode : ExpressionNode = parentOfDeletedNode.parent;
                var siblingOfDeletedNode : ExpressionNode = ((deletedNodeIsLeft)) ? 
                parentOfDeletedNode.right : parentOfDeletedNode.left;
                var siblingInLeftSubtree : Bool = (grandparentOfDeletedNode.left == parentOfDeletedNode);
                if (siblingInLeftSubtree) 
                {
                    grandparentOfDeletedNode.left = siblingOfDeletedNode;
                }
                else 
                {
                    grandparentOfDeletedNode.right = siblingOfDeletedNode;
                }
                siblingOfDeletedNode.parent = grandparentOfDeletedNode;
                siblingOfDeletedNode.wrapInParentheses = (parentOfDeletedNode.wrapInParentheses || siblingOfDeletedNode.wrapInParentheses);
            }
            
            parentOfDeletedNode.parent = null;
            parentOfDeletedNode.left = null;
            parentOfDeletedNode.right = null;
        }
        
        return root;
    }
    
    /**
     * Get whether two expressions which are equations with the equality symbol at the root
     * are the equivalent on a semantic level. (For example x = a + b is the same as x+c-a=b+c)
     * 
     * TODO: This function is a bit fragile as the expected equation needs to be in definition form
     * where the left side is a single variable. May want to make it more robust.
     * 
     * This ignores differences in wild cards, i.e. a wild card with expected data 'x' is equal to the 'x'.
     * 
     * @param expectedEquationRoot
     *      We currently force the requirement that the expectedEquationRoot has on its left side
     *      a single variable which is not present of the right side
     * @param givenEquationRoot
     *      The equation root to check against, in normal cases this is an expression created by the user
     */
    public static function getEquationsSemanticallyEquivalent(expectedEquationRoot : ExpressionNode,
            givenEquationRoot : ExpressionNode,
            vectorSpace : IVectorSpace) : Bool
    {
        var equationsEquivalent : Bool = true;
        
        var definitionVariable : String = expectedEquationRoot.left.data;
        
        // Fail the check immediately if given equation does not have left and right children,
        // i.e. it doesn't look like an equation.
        if (givenEquationRoot.left != null && givenEquationRoot.right != null) 
        {
            // We also want to automatically fail the cases where the given equation is of the
            // form a=a, where a is some arbitrary expression.
            // UNLESS that is that is actually the correct answer expected (this should never be
            // the case however since all it's really saying is 0=0 which is trivial)
            if (ExpressionUtil.getExpressionsStructurallyEquivalent(
                        givenEquationRoot.left,
                        givenEquationRoot.right,
                        true,
                        vectorSpace)) 
            {
                return false;
            }
        }
        else 
        {
            return false;
        }
        
        var uniqueExpectedVariables : Array<String> = new Array<String>();
        ExpressionUtil.getUniqueVariables(expectedEquationRoot.right, vectorSpace, uniqueExpectedVariables);
        
        // Make sure the definition is not negative
        var wasDefinitionNegative : Bool = definitionVariable.charAt(0) == vectorSpace.getSubtractionOperator();
        if (wasDefinitionNegative) 
        {
            definitionVariable = definitionVariable.substr(1);
        }
        uniqueExpectedVariables.push(definitionVariable);
        
        var uniqueGivenVariables : Array<String> = new Array<String>();
        ExpressionUtil.getUniqueVariables(givenEquationRoot, vectorSpace, uniqueGivenVariables);
        
        // First check is to see if the given equation has all the variables contained
        for (i in 0...uniqueExpectedVariables.length){
            var expectedVariable : String = uniqueExpectedVariables[i];
            var foundExpectedVariable : Bool = false;
            for (j in 0...uniqueGivenVariables.length){
                var givenVariable : String = uniqueGivenVariables[j];
                if (givenVariable == expectedVariable) 
                {
                    foundExpectedVariable = true;
                    break;
                }
            }  // the variables of the expected one.    // Equations cannot be equivalent if the given equation does not contain all  
            
            
            
            
            
            if (!foundExpectedVariable) 
            {
                return false;
            }
        }  // Delete the definition as we do not want to assign it a value in the next step  
        
        
        
        uniqueExpectedVariables.splice(Lambda.indexOf(uniqueExpectedVariables, definitionVariable), 1);
        
        // Map the non-negative version of a variable symbol to a numeric value
        var variableToValueMap : Dictionary;
        
        // For x number of iterations, assign values to the right side of the definition
        var iterationsToCheck : Int = 10;
        var error : Float = 0.0001;
        for (i in 0...iterationsToCheck){
            variableToValueMap = new Dictionary();
            var randomRange : Int = 50;
            for (uniqueExpectedVariable in uniqueExpectedVariables)
            {
                var replacementValue : Int = Math.random() * randomRange + 1;
                if (Math.random() > 0.5) 
                {
                    replacementValue *= -1;
                }
                
                Reflect.setField(variableToValueMap, uniqueExpectedVariable, replacementValue);
                variableToValueMap[vectorSpace.getSubtractionOperator() + uniqueExpectedVariable] = replacementValue * -1;
            }  // Assign the derived value of the definition variable in the goal equation  
            
            
            
            var expectedVariableValue : Float = evaluateWithVariableReplacement(expectedEquationRoot.right, variableToValueMap, vectorSpace);
            Reflect.setField(variableToValueMap, definitionVariable, ((wasDefinitionNegative)) ? 
            -1 * expectedVariableValue : expectedVariableValue);
            variableToValueMap[vectorSpace.getSubtractionOperator() + definitionVariable] = -1 * Reflect.field(variableToValueMap, definitionVariable);
            
            // Need to assign values to variables in the modeled equation that might not have been found
            // in the definition format. It is possible for the given equation to still be correct in this
            // situation as long as those extra variables cancel out
            for (uniqueGivenVariable in uniqueGivenVariables)
            {
                // Variable was not found in the list of expected ones
                if (!variableToValueMap.exists(uniqueGivenVariable)) 
                {
                    replacementValue = Math.random() * randomRange + 1;
                    if (Math.random() > 0.5) 
                    {
                        replacementValue *= -1;
                    }
                    
                    Reflect.setField(variableToValueMap, uniqueGivenVariable, replacementValue);
                    variableToValueMap[vectorSpace.getSubtractionOperator() + uniqueGivenVariable] = replacementValue * -1;
                }
            }  // solution to the given equation    // equation. If they are equal then that means the solution to the definition matches with the    // With all variables having values we now evaluate the left and right sides of the given  
            
            
            
            
            
            
            
            var givenLeftValue : Float = evaluateWithVariableReplacement(givenEquationRoot.left, variableToValueMap, vectorSpace);
            var givenRightValue : Float = evaluateWithVariableReplacement(givenEquationRoot.right, variableToValueMap, vectorSpace);
            var difference : Float = Math.abs(givenLeftValue - givenRightValue);
            if (difference > error) 
            {
                // Not equal for this iteration
                equationsEquivalent = false;
                break;
            }
        }
        
        return equationsEquivalent;
    }
    
    /**
     * Get whether two expressions WITHOUT an equality symbol in either one are equal sematically.
     * Basically this means for all arbitrary mappings of variables to values, the values that
     * are generated for both subtrees is always the same.
     * 
     * (NOTE: This is different from the above function which only deals with equations)
     * This ignores differences in wild cards, i.e. a wild card with expected data 'x' is equal to the 'x'.
     * 
     * @param expectedExpressionRoot
     * @param givenExpressionRoot
     */
    public static function getExpressionsSemanticallyEquivalent(expectedExpressionRoot : ExpressionNode,
            givenExpressionRoot : ExpressionNode,
            vectorSpace : IVectorSpace) : Bool
    {
        // Attempt to test equality between the goal expression AND the expression the
        // player has placed on the board. If we work under the assumption that the player
        // is modelling just one side of the equation, no longer have to deal with the
        // complexity of check equation equality
        // The simplest way to do this is to select arbitrary values for each of the
        // non-numeric values and just execute evaluation. Then we have two real numbers
        // to compare against.
        
        // Get the variables for the expected solution, we will replace them with random values
        // to perform the evaluation. We basically assume with sufficiently random value run enough times
        // it is highly unlikely to unequal expression
        var uniqueVariables : Array<String> = new Array<String>();
        ExpressionUtil.getUniqueVariables(expectedExpressionRoot, vectorSpace, uniqueVariables);
        
        var iterationsToCheck : Int = 10;
        var error : Float = 0.0001;
        var variableToValueMap : Dictionary = new Dictionary();
        
        var allTestsPassed : Bool = true;
        for (i in 0...iterationsToCheck){
            var variableToReplace : String;
            var randomRange : Int = 100;
            for (variableToReplace in uniqueVariables)
            {
                // Assign the inverse of the variable a value as well
                var replacementValue : Int = Math.random() * randomRange + 1;
                Reflect.setField(variableToValueMap, variableToReplace, replacementValue);
                variableToValueMap["-" + variableToReplace] = replacementValue * -1;
            }
            
            var submittedValue : Float = ExpressionUtil.evaluateWithVariableReplacement(
                    givenExpressionRoot, variableToValueMap, vectorSpace);
            var expectedValue : Float = ExpressionUtil.evaluateWithVariableReplacement(
                    expectedExpressionRoot, variableToValueMap, vectorSpace);
            
            if (Math.abs(expectedValue - submittedValue) > error) 
            {
                // Not equal for this iteration
                allTestsPassed = false;
                break;
            }
        }
        
        return allTestsPassed;
    }
    
    /**
     * Note that this ignores negatives signs, they are stripped out before being placed
     * in the output list.
     */
    public static function getUniqueVariables(node : ExpressionNode, vectorSpace : IVectorSpace, outVariables : Array<String>) : Void
    {
        
        if (node != null) 
        {
            if (node.isOperator()) 
            {
                getUniqueVariables(node.left, vectorSpace, outVariables);
                getUniqueVariables(node.right, vectorSpace, outVariables);
            }
            else 
            {
                if (Math.isNaN(Std.parseFloat(node.data))) 
                {
                    // Strip out the negative value
                    var variableContent : String = node.data;
                    if (node.data.charAt(0) == vectorSpace.getSubtractionOperator()) 
                    {
                        variableContent = node.data.substr(1);
                    }
                    
                    if (Lambda.indexOf(outVariables, variableContent) == -1) 
                    {
                        outVariables.push(variableContent);
                    }
                }
            }
        }
    }
    
    /**
     * Evaluate the tree to get back a numerical value, replacing any instances
     * of a variable with a value from a given map
     * 
     * @param node
     * @param variableValueMap
     *         A mapping with the key being the variable content, i.e. "c" or "-c" and
     *         the value being some assigned numerical value. Note that you need to be extremely
     *         careful of integer overflow
     *         null if we don't care about variables
     * @return
     *         The numerical value of the tree rooted at the given node
     */
    public static function evaluateWithVariableReplacement(node : ExpressionNode,
            variableValueMap : Dictionary,
            vectorSpace : IVectorSpace) : Float
    {
        var value : Float = 0;
        if (node != null) {
            if (node.isOperator()) 
            {
                var leftValue : Float = evaluateWithVariableReplacement(node.left, variableValueMap, vectorSpace);
                var rightValue : Float = evaluateWithVariableReplacement(node.right, variableValueMap, vectorSpace);
                if (node.isSpecificOperator(vectorSpace.getAdditionOperator())) 
                {
                    value = vectorSpace.add(leftValue, rightValue);
                }
                else if (node.isSpecificOperator(vectorSpace.getDivisionOperator())) 
                {
                    value = vectorSpace.div(leftValue, rightValue);
                }
                else if (node.isSpecificOperator(vectorSpace.getMultiplicationOperator())) 
                {
                    value = vectorSpace.mul(leftValue, rightValue);
                }
                else if (node.isSpecificOperator(vectorSpace.getSubtractionOperator())) 
                {
                    value = vectorSpace.sub(leftValue, rightValue);
                }
            }
            else 
            {
                // TODO: Right now this is assumming that the mapping has negative variables
                // as separate entries
                if (variableValueMap != null && variableValueMap.exists(node.data)) 
                {
                    value = variableValueMap[node.data];
                }
                else 
                {
                    value = vectorSpace.valueOf(node.data);
                }
            }
        }
        return value;
    }
    
    /**
     * Returns all terms separated by "+" symbol, i.e. for a*b/x + 3 + c/d = e*f/g it will return [a*b/x, 3, c/d, e*f/g]
     * @param    root
     * @param    outTerms This input vector will be filled by this function with the additive terms within the given root
     */
    public static function getAdditiveTerms(root : ExpressionNode, outTerms : Array<ExpressionNode>) : Void
    {
        if (root != null) {
            if ((root.data == root.vectorSpace.getEqualityOperator() || root.data == root.vectorSpace.getAdditionOperator())) {
                getAdditiveTerms(root.left, outTerms);
                getAdditiveTerms(root.right, outTerms);
            }
            else {
                outTerms.push(root);
            }
        }
    }

    public function new()
    {
    }
}
