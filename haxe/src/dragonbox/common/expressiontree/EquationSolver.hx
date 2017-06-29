package dragonbox.common.expressiontree;

import dragonbox.common.expressiontree.ExpressionNode;
import flash.errors.Error;

import flash.geom.Vector3D;

class EquationSolver
{
    private var m_variableToSolveFor : String;
    
    public function new()
    {
    }
    
    ////// SOLVER //////
    // This code, up to the marker "////// END SOLVER //////"
    // is copied wholesale from DragonBox ExpressionTreeUtility.as along with associated helper functions
    // and adapted for use with the base classes of AlgebraAdventure, e.g.(and principally) ExpressionNode instead of Node.
    // Note that it does not necessarily result in a completely reduced expression in a reasonable sense, but rather one consistent
    // with the game play.  That is, certain reductions cannot be done with the right "cards" available in the "deck" that is dealt to the player.
    // So, for example, we will be left with the expression: x=8/2+-3/2 after beginning with: 3 + 5 * 1 + 0 + 2*x + -5  = 8 + 0
    
    /**
     * This function solves the given equation for the Key and returns the root node of the solution
     * @param root
     *      Root of the equation to be solved. IMPORTANT: Given equation must be a complete binary tree AND
     *      must contain at least one variable. Otherwise this function will crash.
     * @return
     *      A modified expression node, where a variable is isolated on the left side
     */
    public function solveForKey(root : ExpressionNode, variableToSolveFor : String) : ExpressionNode
    {
        m_variableToSolveFor = variableToSolveFor;
        
        var rootCopy : ExpressionNode = ExpressionUtil.copy(root, root.vectorSpace);
        standardizeOnes(rootCopy);
        var TRACE_STEPS : Bool = false;
        if (TRACE_STEPS) {trace("Start:" + Std.string(rootCopy));
        }  //var reduceMoves:int = reduceKeyOverKeyTerms(rootCopy);// This will cancel any X terms in numerator and denom of same fraction i.e. x*x*a / a*x -> x; d*x / (x * x * x) -> d/x^2  
        
        var subtractNonKeyMoves : Int = subtractNonKeyTermsFromBothSides(rootCopy);
        if (TRACE_STEPS) {trace("After subtract b terms:" + Std.string(rootCopy));
        }
        var assocMoves : Int = reduceKeyAssociativeTerms(rootCopy);
        if (TRACE_STEPS) {trace("Key associative Terms reduced:" + Std.string(rootCopy));
        }
        var reduceMoves : Int = reduceYOverYTerms(rootCopy);
        if (TRACE_STEPS) {trace("Y/Y Terms reduced:" + Std.string(rootCopy));
        }
        subtractNonKeyMoves = subtractNonKeyTermsFromBothSides(rootCopy);
        if (TRACE_STEPS) {trace("After subtract b terms:" + Std.string(rootCopy));
        }
        var cancelMoves : Int = cancelYMinusYTerms(rootCopy);
        if (TRACE_STEPS) {trace("Y-Y canceled:" + Std.string(rootCopy));
        }
        var removeZeroesMoves : Int = removeZeroes(rootCopy);
        if (TRACE_STEPS) {trace("0's removed:" + Std.string(rootCopy));
        }
        var keyInNumer : Bool = areKeyTermsInNumerator(rootCopy);
        var keyInDenom : Bool = areKeyTermsInDenominator(rootCopy);
        var multiplyMoves : Int = 0;
        if (keyInNumer && keyInDenom) {
            throw new Error("ExpressionTreeUtility.solveForKey():\n\rAttempting to solve non-linear equation:\n\r" + Std.string(root));
        }
        else if (keyInDenom) {
            // In this case we have: a1 + a2 ... + b1 / x + b2 / x ... = c1 + c2 ... + d1 / x + d2 / x ...
            multiplyMoves = multiplyBothSidesByKey(rootCopy);
            multiplyMoves += reduceKeyOverKeyTerms(rootCopy);
            if (TRACE_STEPS) {trace("After mult by key:" + Std.string(rootCopy));
            }
        }
        var keyOnLeftSide : Bool = containsKey(rootCopy.left);
        var keyOnRightSide : Bool = containsKey(rootCopy.right);
        if (keyOnRightSide && ExpressionUtil.isVariableNode(rootCopy.right)) {  //swap right and left  
            var left : ExpressionNode = rootCopy.left;
            rootCopy.left = rootCopy.right;
            rootCopy.right = left;
            return rootCopy;
        }
        if (keyOnLeftSide && ExpressionUtil.isVariableNode(rootCopy.left)) {
            return rootCopy;
        }  // Now all x terms are in the numerator in the form a1*x + a2*x ... + b1 + b2 ... = c1*x + c2*x ... + d1 + d2 ...  
        
        var subtractNonKeyMoves2 : Int = subtractNonKeyTermsFromBothSides(rootCopy);
        if (TRACE_STEPS) {trace("After subtract b terms (2):" + Std.string(rootCopy));
        }
        var subtractKeyMoves : Int = 0;
        if (keyOnLeftSide && keyOnRightSide) {
            subtractKeyMoves = subtractKeyTermsFromBothSides(rootCopy);
            if (TRACE_STEPS) {trace("After subtract c terms:" + Std.string(rootCopy));
            }
        }
        var cancelTwoMoves : Int = cancelYMinusYTerms(rootCopy);
        if (TRACE_STEPS) {trace("Y-Y canceled (2):" + Std.string(rootCopy));
        }
        var removeTwoMoves : Int = removeZeroes(rootCopy);
        if (TRACE_STEPS) {trace("0's removed (2):" + Std.string(rootCopy));
        }
        var divideMoves : Int = divideBothSidesByKeyCoefficients(rootCopy);
        if (TRACE_STEPS) {trace("After divide by terms:" + Std.string(rootCopy));
        }
        var finalReduceMoves : Int = reduceYOverYTerms(rootCopy);
        if (TRACE_STEPS) {trace("After final reduce Y/Y:" + Std.string(rootCopy));
        }
        var finalCancelMoves : Int = cancelYMinusYTerms(rootCopy);
        if (TRACE_STEPS) {trace("Final Y-Y canceled:" + Std.string(rootCopy));
        }
        var finalRemoveZeroesMoves : Int = removeZeroes(rootCopy);
        if (TRACE_STEPS) {trace("Final 0's removed:" + Std.string(rootCopy));
        }
        
        if (TRACE_STEPS) {trace("Total number of moves: " + Std.parseFloat(assocMoves + reduceMoves + cancelMoves + removeZeroesMoves + multiplyMoves + subtractNonKeyMoves + subtractNonKeyMoves2 + subtractKeyMoves + cancelTwoMoves + removeTwoMoves + divideMoves + finalReduceMoves + finalCancelMoves + finalRemoveZeroesMoves));
        }  // At this point X should be alone  
        
        if (keyOnLeftSide) {
            return rootCopy;
        }
        else {  //swap right and left  
            left = rootCopy.left;
            rootCopy.left = rootCopy.right;
            rootCopy.right = left;
            return rootCopy;
        }
    }
    
    // SOLVER helper functions:
    /**
     * Takes any 1's or -1's in an equation and forces them to use "N1" or "-N1" (dropping any suffix)
     * @param    root Root of expression/subexpression to standardize
     */
    private function standardizeOnes(root : ExpressionNode) : Void
    {
        // Standardize all 1's, -1's to be "N1" and "-N1"
        var leafNodes : Array<ExpressionNode> = new Array<ExpressionNode>();
        ExpressionUtil.getLeafNodes(root, leafNodes);
        for (leaf in leafNodes){
            if ((leaf.data == "N1L") || (leaf.data == "N1T")) {
                leaf.data = "N1";
            }
            else if ((leaf.data == "-N1L") || (leaf.data == "-N1T")) {
                leaf.data = "-N1";
            }
        }
    }
    
    /**
     * Cancel any terms in the expression of the form a - a and replace with a single zero term
     * @param    root
     * @return Number of moves needed
     */
    public function cancelYMinusYTerms(root : ExpressionNode) : Int
    {
        var moves : Int = 0;
        var leftTerms : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(root.left, leftTerms);
        var rightTerms : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(root.right, rightTerms);
        
        // Search thru b1 -> b4 terms by checking pairwise: [b1, b2], [b1, b3], [b1, b4], [b2, b3], [b2, b4], [b3, b4]
        var i : Int;
        var j : Int;
        var termOne : ExpressionNode;
        var termTwo : ExpressionNode;
        for (i in 0...leftTerms.length - 1){
            termOne = leftTerms[i];
            if (termOne.isOperator()) {  // || termOne.removedFromTree) {  
                continue;
            }
            for (j in i + 1...leftTerms.length){
                termTwo = leftTerms[j];
                if (termTwo.isOperator()) {  // || termTwo.removedFromTree) {  
                    continue;
                }
                if (isOppositeSign(termOne.data, termTwo.data)) {
                    // Drag/cancel these terms, removing one and turning other into zero = 1 move, cancel zero = 2 moves
                    ExpressionUtil.removeNode(root, termOne);
                    ExpressionUtil.removeNode(root, termTwo);
                    moves += 2;
                    break;
                }
            }
        }
        for (i in 0...rightTerms.length - 1){
            termOne = rightTerms[i];
            if (termOne.isOperator()) {  //|| termOne.removedFromTree) {  
                continue;
            }
            for (j in i + 1...rightTerms.length){
                termTwo = rightTerms[j];
                if (termTwo.isOperator()) {  //|| termTwo.removedFromTree) {  
                    continue;
                }
                if (isOppositeSign(termOne.data, termTwo.data)) {
                    // Drag/cancel these terms, removing one and turning other into zero = 1 move, cancel zero = 2 moves
                    ExpressionUtil.removeNode(root, termOne);
                    ExpressionUtil.removeNode(root, termTwo);
                    moves += 2;
                    break;
                }
            }
        }
        return moves;
    }
    
    /**
     * Remove any zero terms from the given expression's root
     * @param    root
     * @return Number of moves needed
     */
    public function removeZeroes(root : ExpressionNode) : Int
    {
        var moves : Int = 0;
        
        var additiveTerms : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(root, additiveTerms);
        
        for (termToCheck in additiveTerms){
            var removeMe : Bool = false;
            var allLeafNodes : Array<ExpressionNode> = new Array<ExpressionNode>();
            if (termToCheck.data == root.vectorSpace.getDivisionOperator()) {
                ExpressionUtil.getLeafNodes(termToCheck.left, allLeafNodes);
            }
            else if (termToCheck.data == root.vectorSpace.getMultiplicationOperator())                 { }
            else if (termToCheck.data == root.vectorSpace.zero()) {
                removeMe = true;
            }
            
            if (allLeafNodes.length > 0) {
                for (leafNode in allLeafNodes){
                    if (leafNode.data == root.vectorSpace.zero()) {
                        removeMe = true;
                        break;
                    }
                }
            }
            
            if (removeMe) {
                ExpressionUtil.removeNode(root, termToCheck);
                moves++;
            }
        }
        
        return moves;
    }
    
    /**
     * Reduces any terms of the form Key/Key to be 1, also simplifies any 1's created such that a * Key / Key -> a * 1 -> a
     * @param    root
     * @return Number of moves needed
     */
    private function reduceKeyOverKeyTerms(root : ExpressionNode) : Int
    {
        return reduceYOverYTerms(root, true);
    }
    
    /**
     * Reduces/removes any terms of the form Y/Y, i.e a*x*b/a*b + c/c = f -> x + 1 = f
     * @param    root
     * @param    keyOnly True if only key terms are reduced, leaving others alone
     * @return Number of moves needed
     */
    public function reduceYOverYTerms(root : ExpressionNode, keyOnly : Bool = false) : Int
    {
        var moves : Int = 0;
        var additiveTerms : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(root, additiveTerms);
        for (additiveTerm in additiveTerms){
            // Only need to worry about terms of the form a*x/c*d
            if (additiveTerm.data != "/") {  //ExpressionOperator.DIVIDE) {  
                continue;
            }
            if (keyOnly && !containsKey(additiveTerm)) {
                continue;
            }
            if ((additiveTerm.left == null) || (additiveTerm.right == null)) {
                throw new Error("ExpressionTreeUtility.reduceXTerms(): Unexpected expression of the form div(null;null)");
            }
            var numeratorNodes : Array<ExpressionNode> = new Array<ExpressionNode>();
            ExpressionUtil.getLeafNodes(additiveTerm.left, numeratorNodes);
            var numTerm : ExpressionNode;
            var denomTerm : ExpressionNode;
            for (numTerm in numeratorNodes){
                if (keyOnly && !isKey(numTerm)) {
                    continue;
                }
                if (additiveTerm.right == null) {
                    break;
                }
                var denomNodes : Array<ExpressionNode> = new Array<ExpressionNode>();
                ExpressionUtil.getLeafNodes(additiveTerm.right, denomNodes);
                for (denomTerm in denomNodes){
                    if (denomTerm.data == numTerm.data) {
                        // Remove the denominator, set the numerator to one (one move)
                        ExpressionUtil.removeNode(root, denomTerm);
                        numTerm.data = "1";  // setValue(1, NodeType.NORMAL);  
                        moves++;
                        break;
                    }
                }
            }
        }  // Replace a*1 terms with a  
        
        
        
        moves += simplifyYtimesOneTerms(root);
        
        return moves;
    }
    
    /**
     * Simplifies any Key*a + Key*b pairs of terms to Key*(a+b)
     * @param    root
     * @return Number of moves needed
     */
    
    public function reduceKeyAssociativeTerms(root : ExpressionNode) : Int{
        var moves : Int = 2;
        
        var keyOnLeftSide : Bool = containsKey(root.left);
        var gatherNode : ExpressionNode;
        if (keyOnLeftSide) {
            gatherNode = root.left;
        }
        else {
            gatherNode = root.right;
        }
        
        var additiveTerms : Array<ExpressionNode> = new Array<ExpressionNode>();
        var additiveTermsWithKey : Array<ExpressionNode> = new Array<ExpressionNode>();
        var additiveFactors : Array<ExpressionNode> = new Array<ExpressionNode>();
        var keyTerm : ExpressionNode;
        getAdditiveTerms(gatherNode, additiveTerms);
        for (i in 0...additiveTerms.length){
            var term : ExpressionNode = additiveTerms[i];
            if (containsKey(term) && term.data == root.vectorSpace.getMultiplicationOperator()) {
                additiveTermsWithKey.push(term);
                var termOnLeftSide : Bool = containsKey(term.left);
                if (termOnLeftSide) {
                    additiveFactors.push(term.right);
                    keyTerm = term.left;
                }
                else {
                    additiveFactors.push(term.left);
                    keyTerm = term.right;
                }
            }
            else {
                additiveFactors.push(term);
            }
        }
        if (additiveTermsWithKey.length == 2) {
            var newAddNode : ExpressionNode = applyOperation(root.vectorSpace.getAdditionOperator(), additiveFactors[0].data, additiveFactors[1], true).parent;  //new ExpressionNode(root.vectorSpace, key + "*(" + additiveFactors[0] + "+" + additiveFactors[1] + ")" );  
            newAddNode.wrapInParentheses = true;
            var newMultNode : ExpressionNode = applyOperation(root.vectorSpace.getMultiplicationOperator(), keyTerm.data, newAddNode, true).parent;
            newMultNode.parent = root;
            if (keyOnLeftSide) {
                root.left = newMultNode;
            }
            else {
                root.right = newMultNode;
            }
        }
        return moves;
    }
    
    
    /**
     * Simplifies any a*1/b terms to be a/b
     * @param    root
     * @return Number of moves needed
     */
    public function simplifyYtimesOneTerms(root : ExpressionNode) : Int
    {
        var moves : Int = 0;
        
        var additiveTerms : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(root, additiveTerms);
        for (additiveTerm in additiveTerms){
            if ((additiveTerm.data != root.vectorSpace.getMultiplicationOperator())
                && (additiveTerm.data != root.vectorSpace.getDivisionOperator())) {
                continue;
            }  // Now cancel all the ones we can in the numerator  
            
            var numeratorNodes : Array<ExpressionNode> = new Array<ExpressionNode>();
            if (additiveTerm.data == root.vectorSpace.getMultiplicationOperator()) {
                ExpressionUtil.getLeafNodes(additiveTerm, numeratorNodes);
            }
            else {
                // Must be divide, gather numerator terms
                ExpressionUtil.getLeafNodes(additiveTerm.left, numeratorNodes);
            }
            
            var onesRemoved : Int = 0;
            for (i in 0...numeratorNodes.length){
                if ((i == numeratorNodes.length - 1) && (onesRemoved == numeratorNodes.length - 1)) {
                    // Don't remove the last term if we've removed all the rest (have to leave at least one)
                    break;
                }
                if (numeratorNodes[i].data == root.vectorSpace.identity()) {
                    // Simplify 1*a -> a, one move
                    ExpressionUtil.removeNode(root, numeratorNodes[i]);
                    onesRemoved++;
                    moves++;
                }
            }
        }
        
        return moves;
    }
    
    /**
     * Returns true if there are terms of positive power (x^y where y > 0) in the equation 
     * @param    root
     * @return
     */
    public function areKeyTermsInNumerator(root : ExpressionNode) : Bool
    {
        var additiveTerms : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(root, additiveTerms);
        var keysInNumerator : Bool = false;
        for (additiveTerm in additiveTerms){
            if (additiveTerm.data == root.vectorSpace.getDivisionOperator()) {
                keysInNumerator = containsKey(additiveTerm.left);
            }
            else if (additiveTerm.data == root.vectorSpace.getMultiplicationOperator()) {
                keysInNumerator = containsKey(additiveTerm);
            }
            else if (isKey(additiveTerm)) {
                keysInNumerator = true;
            }
            if (keysInNumerator) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Returns true if there are terms of negative power (x^y where y < 0) in the equation 
     * @param    root
     * @return
     */
    public function areKeyTermsInDenominator(root : ExpressionNode) : Bool
    {
        var additiveTerms : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(root, additiveTerms);
        var keysInDenominator : Bool = false;
        for (additiveTerm in additiveTerms){
            if (additiveTerm.data == "/") {  //ExpressionOperator.DIVIDE) {  
                keysInDenominator = containsKey(additiveTerm.right);
                if (keysInDenominator) {
                    return true;
                }
            }
        }
        return false;
    }
    
    /**
     * Multiply both sides of the equation by Key
     * @param    root
     * @return Number of moves needed (this should = 1)
     */
    private function multiplyBothSidesByKey(root : ExpressionNode) : Int
    {
        var keyData : String = "Key";
        var allKeys : Array<ExpressionNode> = new Array<ExpressionNode>();
        getKeys(root, allKeys);
        // If there are keys in this equation, match the type of Key they are using (maybe "KeyL" or "KeyT" ... or "x" or "y")
        if (allKeys.length > 0) {
            keyData = allKeys[0].data;
        }
        
        var additiveTerms : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(root, additiveTerms);
        for (additiveTerm in additiveTerms){
            if (additiveTerm.data == root.vectorSpace.getDivisionOperator()) {
                applyOperation(root.vectorSpace.getMultiplicationOperator(), keyData, additiveTerm.left, false);
            }
            else {
                applyOperation(root.vectorSpace.getMultiplicationOperator(), keyData, additiveTerm, false);
            }
            ExpressionUtil.pushDivisionNodesUpward(root, root.vectorSpace);
        }  // This is trivial, multiplying both sides by X is always one move  
        
        
        
        return 1;
    }
    
    /**
     * Subtracts terms with no Key in them from both sides of the equation, i.e. a*x+b-c=d -> a*x=d-b+c
     * @param    root
     * @return Number of moves needed
     */
    private function subtractNonKeyTermsFromBothSides(root : ExpressionNode) : Int
    {
        // Now all x terms are in the numerator in the form a1*x + a2*x ... + b1 + b2 ... = c1*x + c2*x ... + d1 + d2 ...
        var moves : Int = 0;
        
        var keyOnLeftSide : Bool = containsKey(root.left);
        var keyOnRightSide : Bool = containsKey(root.right);
        var gatherNode : ExpressionNode;
        if (keyOnLeftSide) {
            gatherNode = root.left;
        }
        else {
            gatherNode = root.right;
        }
        
        var termsToCheck : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(gatherNode, termsToCheck);
        var termsToSubtract : Array<ExpressionNode> = new Array<ExpressionNode>();
        for (termToSubtract in termsToCheck){
            if (!containsKey(termToSubtract)) {
                termsToSubtract.push(termToSubtract);
            }
        }
        
        for (subTerm in termsToSubtract){
            // Add (-b) to both sides = one move, eliminate b from left side = 2 moves
            // NOTE: if B contains more than a leaf Node - i.e. b1/b2, etc - this is not a valid move in the game
            var subtractNode : ExpressionNode;
            if (!keyOnLeftSide) {
                subtractNode = root.left;
            }
            else {
                subtractNode = root.right;
            }
            if (subTerm.isOperator()) {
                var termCopy : ExpressionNode = ExpressionUtil.copy(subTerm, subTerm.vectorSpace);
                var leafNodes : Array<ExpressionNode> = new Array<ExpressionNode>();
                if (subTerm.data == root.vectorSpace.getDivisionOperator()) {  //ExpressionOperator.DIVIDE) {  
                    ExpressionUtil.getLeafNodes(termCopy.left, leafNodes);
                }
                else if (subTerm.data == root.vectorSpace.getMultiplicationOperator()) {  //ExpressionOperator.MULTIPLY) {  
                    ExpressionUtil.getLeafNodes(termCopy, leafNodes);
                }
                else {
                    throw new Error("ExpressionTreeUtility.subtractNonKeyTermsFromBothSides():\n\rUnexpected operator in gather terms to subtract: " + subTerm.data);
                }
                var leafNodeToFlip : ExpressionNode = leafNodes[0];
                leafNodeToFlip.data = leafNodeToFlip.getOppositeValue();
                termCopy.parent = null;
                applyOperationWithExistingSiblingNode(root.vectorSpace.getAdditionOperator(), termCopy, subtractNode, false);
            }
            else {
                var negativeData : String = subTerm.getOppositeValue();
                applyOperation(root.vectorSpace.getAdditionOperator(), negativeData, subtractNode, false);
            }
            ExpressionUtil.removeNode(root, subTerm);
            moves = moves + 3;
        }
        
        return moves;
    }
    
    /**
     * Subtracts terms with Key in them from both sides of the equation, i.e. a*x=c*x+d-b -> a*x-c*x=d-b
     * @param    root
     * @return Number of moves needed
     */
    private function subtractKeyTermsFromBothSides(root : ExpressionNode) : Int
    {
        // Now all x terms are in the numerator in the form a1*x + a2*x = c1*x + c2*x ... + d1 + d2 ...
        // NOTE: If there is more than one Key Term (that cannot be canceled or simplified) then this is NOT solvable in the game!
        var moves : Int = 0;
        var termsToCheck : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(root.right, termsToCheck);
        var termsToSubtract : Array<ExpressionNode> = new Array<ExpressionNode>();
        for (termToSubtract in termsToCheck){
            if (containsKey(termToSubtract)) {
                termsToSubtract.push(termToSubtract);
            }
        }
        
        for (subTerm in termsToSubtract){
            // Add (-c1*x) to both sides, one move
            //NOTE: This is not a valid move in the game unless c1 = 1
            if (subTerm.isLeaf()) {
                var negativeData : String = subTerm.getOppositeValue();
                // TODO: complex terms need to invert one of the numerator terms, add (-c1)/x
                applyOperation(root.vectorSpace.getAdditionOperator(), negativeData, root.left, false);
            }
            else {  // the subTerm is an expression like (b*x)  
                var negatedExpression : ExpressionNode = getNegatedExpression(subTerm);
                applyOperationWithExistingSiblingNode(root.vectorSpace.getAdditionOperator(), negatedExpression, root.left, false);
            }
            ExpressionUtil.removeNode(root, subTerm);
            moves++;
        }
        
        return moves;
    }
    
    /**
     * Divides both sides by Key coefficients i.e. a*x/(b*c)=e -> x=e*b*c/a
     * @param    root
     * @return Number of moves needed
     */
    private function divideBothSidesByKeyCoefficients(root : ExpressionNode) : Int
    {
        // Should be of the form a*b * x / d = d1 + d2 + d3 +...
        var moves : Int = 0;
        var termsToDivide : Array<ExpressionNode> = new Array<ExpressionNode>();
        var termsToMultiply : Array<ExpressionNode> = new Array<ExpressionNode>();
        
        var keyOnLeftSide : Bool = containsKey(root.left);
        var keyOnRightSide : Bool = containsKey(root.right);
        if (keyOnLeftSide && keyOnRightSide) {
            throw new Error("ExpressionTreeUtility.divideBothSidesByKeyCoefficient():\n\rUnexpected Key is found on both sides: " + Std.string(root));
        }
        var gatherNode : ExpressionNode;
        if (keyOnLeftSide) {
            gatherNode = root.left;
        }
        else {
            gatherNode = root.right;
        }
        
        var additiveTerms : Array<ExpressionNode> = new Array<ExpressionNode>();
        getAdditiveTerms(gatherNode, additiveTerms);
        if (additiveTerms.length != 1) {
            throw new Error("ExpressionTreeUtility.divideBothSidesByKeyCoefficient():\n\rMultiple terms on Key side, expected only coefficients: " + Std.string(root));
        }
        
        if (gatherNode.data == root.vectorSpace.getDivisionOperator()) {
            ExpressionUtil.getLeafNodes(gatherNode.left, termsToDivide);
            ExpressionUtil.getLeafNodes(gatherNode.right, termsToMultiply);
        }
        else if (gatherNode.data == root.vectorSpace.getMultiplicationOperator()) {
            ExpressionUtil.getLeafNodes(gatherNode, termsToDivide);
        }
        // Perform divides
        else if (isKey(gatherNode)) {
            // Done!
            return moves;
        }
        else {
            throw new Error("ExpressionTreeUtility.divideBothSidesByKeyCoefficient():\n\rUnexpected operation/node on Key side, expected only coefficients: " + Std.string(root));
        }
        
        
        
        for (divTerm in termsToDivide){
            if (isKey(divTerm)) {
                continue;
            }  // Have to re-fetch additive terms after each divide, the terms will change as a result of the divide  
            
            var termsBeingDivided : Array<ExpressionNode> = new Array<ExpressionNode>();
            if (!keyOnLeftSide) {
                getAdditiveTerms(root.left, termsBeingDivided);
            }
            else {
                getAdditiveTerms(root.right, termsBeingDivided);
            }  // Divide by C on both sides = one move, reduce a/a = 1 and 1*x = x = 2 moves  
            
            for (termBeingDivided in termsBeingDivided){
                if (termBeingDivided.data == root.vectorSpace.getDivisionOperator()) {  //ExpressionOperator.DIVIDE) {  
                    applyOperation(root.vectorSpace.getMultiplicationOperator(), divTerm.data, termBeingDivided.right, false);
                }
                else {
                    applyOperation(root.vectorSpace.getDivisionOperator(), divTerm.data, termBeingDivided, false);
                }
                ExpressionUtil.pushDivisionNodesUpward(root, root.vectorSpace);
            }
            ExpressionUtil.removeNode(root, divTerm);
            moves += 3;
        }  // Multiply terms  
        
        
        
        for (multTerm in termsToMultiply){
            if (isKey(multTerm)) {
                continue;
            }  // Have to re-fetch additive terms after each multiply, the terms will change as a result of the divide  
            
            var termsBeingMultiplied : Array<ExpressionNode> = new Array<ExpressionNode>();
            if (!keyOnLeftSide) {  //Direction.LEFT) {  
                getAdditiveTerms(root.left, termsBeingMultiplied);
            }
            else {
                getAdditiveTerms(root.right, termsBeingMultiplied);
            }  // Multiply by C on both sides = one move, reduce a/a = 1 and 1*x = x = 2 moves  
            
            for (termBeingMultiplied in termsBeingMultiplied){
                if (termBeingMultiplied.data == root.vectorSpace.getDivisionOperator()) {  //ExpressionOperator.DIVIDE) {  
                    applyOperation(root.vectorSpace.getMultiplicationOperator(), multTerm.data, termBeingMultiplied.left, false);
                }
                else {
                    applyOperation(root.vectorSpace.getMultiplicationOperator(), multTerm.data, termBeingMultiplied, false);
                }
                ExpressionUtil.pushDivisionNodesUpward(root, root.vectorSpace);
            }
            ExpressionUtil.removeNode(root, multTerm);
            moves += 3;
        }
        
        return moves;
    }
    
    public function containsKey(root : ExpressionNode) : Bool
    {
        var hasKey : Bool = false;
        if (root != null) 
        {
            if (root.isOperator()) 
            {
                hasKey = (containsKey(root.left) || containsKey(root.right));
            }
            else 
            {
                hasKey = isKey(root);
            }
        }
        return hasKey;
    }
    
    
    /** 
     * DragonBox uses the root data with certain encodings that indicate whether a subTree contains the "Key" namely the variable to be solved for.
     * The KeysList is now loaded with the Key variable name using the setKey() function, currently only called when AdLib is initialized.
     */
    public function isKey(root : ExpressionNode) : Bool
    {
        if (root.isNegative()) {
            return root.getOppositeValue() == m_variableToSolveFor;
        }
        else {
            return root.data == m_variableToSolveFor;
        }
    }
    
    /**
     * returns true, if the two strings are opposite signs 
     * eg.     -XXX, XXX
     *         -2, 2
     *         -ABDS, -ABDS
     */
    public function isOppositeSign(v1 : String, v2 : String) : Bool
    {
        if (v1.charAt(0) == "-" && v2.charAt(0) != "-") 
        {
            return (v1.substr(1) == v2);
        }
        else if (v1.charAt(0) != "-" && v2.charAt(0) == "-") 
        {
            return (v1 == v2.substr(1));
        }
        else 
        {
            return false;
        }
    }
    
    public function getNegatedExpression(term : ExpressionNode) : ExpressionNode
    {
        var negatedTerm : ExpressionNode = new ExpressionNode(term.vectorSpace, term.data);
        negatedTerm.left = term.left;
        negatedTerm.right = term.right;
        if (term.left.isLeaf() && isKey(term.right)) 
        {
            negatedTerm.left.data = term.left.getOppositeValue();
            negatedTerm.right = term.right;
        }
        else if (term.right.isLeaf() && isKey(term.left)) 
        {
            negatedTerm.right.data = term.right.getOppositeValue();
            negatedTerm.left = term.left;
        }
        else {
            throw new Error("ExpressionUtil.solveForKey():\n\rAttempting to negate a non-simple expression: " + Std.string(term) + "\n\r");
        }
        
        return negatedTerm;
    }
    
    /**
     * Used to perform a specified operation at a node and creating a new sibling node with data specified
     * @param    operation Operation to perform on target node
     * @param    data Data to create new sibling node with
     * @param    node Target node, operation will become this node's parent and data will become the sibling to this node
     * @param    side Which side of the new operation node to add the new sibling node to
     * @return Newly created sibling node
     */
    public function applyOperation(operation : String, data : String, node : ExpressionNode, onLeftSide : Bool) : ExpressionNode
    {
        var newOperator : ExpressionNode = new ExpressionNode(node.vectorSpace, operation);
        newOperator.position = new Vector3D(node.position.x, node.position.y);
        if (node.parent != null) {
            if (node.parent.left == node) 
            {
                node.parent.left = newOperator;
            }
            else 
            {
                node.parent.right = newOperator;
            }
        }
        
        if (node.parent.data == node.vectorSpace.getDivisionOperator()) {
            newOperator.wrapInParentheses = true;
        }  // Update node's parent  
        
        newOperator.parent = node.parent;
        node.parent = newOperator;
        
        var newSibling : ExpressionNode = new ExpressionNode(node.vectorSpace, data);
        newSibling.parent = newOperator;
        
        if (onLeftSide) 
        {  // newNode goes to the left children  
            newOperator.right = node;
            newOperator.left = newSibling;
        }
        else 
        {
            newOperator.left = node;
            newOperator.right = newSibling;
        }
        
        return newSibling;
    }
    
    
    /**
     * Similar to applyOperation but with newSibling node already created
     * @param    operation Operation to perform on node
     * @param    newSibling Sibling to perform operation with
     * @param    node Node to apply operation to
     * @param    side Side to put the newSibling on
     */
    public function applyOperationWithExistingSiblingNode(operation : String, newSibling : ExpressionNode, node : ExpressionNode, onLeftSide : Bool) : Void
    {
        var newOperator : ExpressionNode = new ExpressionNode(node.vectorSpace, operation);
        newOperator.position = new Vector3D(node.position.x, node.position.y);
        if (node.parent != null) {
            if (node.parent.left == node) 
            {
                node.parent.left = newOperator;
            }
            else 
            {
                node.parent.right = newOperator;
            }
        }  // Update node's parent  
        
        
        
        newOperator.parent = node.parent;
        node.parent = newOperator;
        
        newSibling.parent = newOperator;
        
        if (onLeftSide) 
        {  // newNode goes to the left children  
            newOperator.right = node;
            newOperator.left = newSibling;
        }
        else 
        {
            newOperator.left = node;
            newOperator.right = newSibling;
        }
    }
    
    /**
     * Copy the contents of a targeted to on above it node to another
     * @param    childNode The node that is to be shifted a level up in the tree
     * @param    oldParent Previous parent of the childNode
     */
    private function updateParent(childNode : ExpressionNode, oldParent : ExpressionNode) : Void
    {
        var newParent : ExpressionNode = oldParent.parent;
        
        if (newParent != null) 
        {
            if (newParent.left == oldParent) 
            {
                newParent.left = childNode;
            }
            else 
            {
                newParent.right = childNode;
            }
            childNode.parent = newParent;
            
            // Reset the position to prevent jumping if we eliminated a multiplication
            // or a division operator. Otherwise the position stored in the from node could be far
            // away from the nodes it was attached to
            if (!oldParent.isSpecificOperator(oldParent.vectorSpace.getAdditionOperator())) 
            {
                childNode.position.x = oldParent.position.x;
                childNode.position.y = oldParent.position.y;
            }
        }
    }
    
    /**
     * Returns all terms separated by "+" symbol, i.e. for a*b/x + 3 + c/d = e*f/g it will return [a*b/x, 3, c/d, e*f/g]
     * @param    root
     * @param    outTerms This input vector will be filled by this function with the additive terms within the given root
     */
    public function getAdditiveTerms(root : ExpressionNode, outTerms : Array<ExpressionNode>) : Void
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
    
    /**
     * Get all the key nodes in the current expression tree
     */
    public function getKeys(node : ExpressionNode, outKeyNodes : Array<ExpressionNode>) : Void
    {
        if (node != null) 
        {
            if (isKey(node)) 
            {
                outKeyNodes.push(node);
            }
            else 
            {
                getKeys(node.left, outKeyNodes);
                getKeys(node.right, outKeyNodes);
            }
        }
    }
}
