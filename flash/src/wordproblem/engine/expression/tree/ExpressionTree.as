package wordproblem.engine.expression.tree
{
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.expressiontree.WildCardNode;
    import dragonbox.common.math.util.MathUtil;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    import dragonbox.common.system.Map;
    
    import starling.events.EventDispatcher;
    
    import wordproblem.engine.expression.event.ExpressionTreeEvent;
    
    /**
     * One important note about coupling
     * 
     * Every node that is created needs to have its status adjusted to CREATED
     * in order for the rendering widget to identify whether it has already created
     * an widget for that node.
     * 
     * Also the tree will dispatch events as pieces of it are modified, these are especially useful
     * for animations involving the visual representation of the tree. For example suppose we want to
     * show an animation for substitution, the backing data gets modified first and sends of an event
     * with key information about how the tree structure has changed and the operation that changed it.
     * The visual representation is fully responsible for interpreting the data into the correct animation
     * and in the will need to figure out how to transition its old visuals into the new one, the simplest way
     * just being an entire rebuild of the tree.
     */
    public class ExpressionTree extends EventDispatcher
    {
        private static var TREE_COUNTER:int = 0;
        
        private var m_id:int;
        private var m_root:ExpressionNode;
        private var m_vectorSpace:IVectorSpace;
        
        public function ExpressionTree(vectorSpace:IVectorSpace, root:ExpressionNode)
        {
            m_id = TREE_COUNTER++;
            m_vectorSpace = vectorSpace;
            m_root = root;
        }
        
        public function getId():int
        {
            return m_id;
        }
        
        public function getVectorSpace():IVectorSpace
        {
            return m_vectorSpace;
        }
        
        public function getRoot():ExpressionNode
        {
            return m_root;
        }
        
        public function clone():ExpressionTree
        {
            return new ExpressionTree(m_vectorSpace, ExpressionUtil.copy(m_root, m_vectorSpace));
        }
        
        /**
         * Perform a batch addition of nodes
         */
        public function addLeafNodeBatch(operators:Vector.<String>, 
                                         newLeafSymbols:Vector.<String>, 
                                         givenNodes:Vector.<ExpressionNode>,
                                         areNewLeavesLeft:Vector.<Boolean>,
                                         xPositions:Vector.<Number>, 
                                         yPositions:Vector.<Number>):void
        {
            const addedNodes:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            const initialXPositions:Vector.<Number> = xPositions.concat();
            const initialYPositions:Vector.<Number> = yPositions.concat();
            
            var i:int;
            var numNodesToAdd:int = operators.length;
            for (i = 0; i < numNodesToAdd; i++)
            {
                const addedNode:ExpressionNode = _addLeafNode(
                    operators[i],
                    newLeafSymbols[i],
                    areNewLeavesLeft[i],
                    givenNodes[i],
                    xPositions[i],
                    yPositions[i]
                );
                addedNodes.push(addedNode);
            }
            
            dispatchEventWith(ExpressionTreeEvent.ADD_BATCH, false,
                {nodesAdded:addedNodes, initialXPositions:initialXPositions, initialYPositions:initialYPositions}
            );
        }
        
        /**
         * Add a brand new terminal node to this tree with the appropriate operator
         * 
         * @param operator
         *      The operator that will be the parent of the node
         * @param newLeafSymbol
         *      The data field to place inside the new node
         * @param isNewLeafLeft
         *      Should the new symbol be the left child
         * @param givenNode
         *      The node in which to attach the new operator to. The operator becomes
         *      its parent and the new symbol its sibling
         * @param xPosition
         *      The x position of the new node to add in global space
         * @param yPosition
         *      The y position of the new node to add in global space
         * @return
         *      A reference to the leaf node that was just added
         */
        public function addLeafNode(operator:String, 
                                    newLeafSymbol:String, 
                                    isNewLeafLeft:Boolean, 
                                    givenNode:ExpressionNode, 
                                    xPosition:Number, 
                                    yPosition:Number):void
        {
            
            const newNode:ExpressionNode = _addLeafNode(operator, newLeafSymbol, isNewLeafLeft, givenNode, xPosition, yPosition);
            dispatchEventWith(
                ExpressionTreeEvent.ADD, 
                false, 
                {nodeAdded:newNode, initialXPosition:xPosition, initialYPosition:yPosition}
            );
        }
        
        /**
         * Internal function that adds a single new leaf node into this tree
         */
        private function _addLeafNode(operator:String, 
                                      newLeafSymbol:String, 
                                      isNewLeafLeft:Boolean, 
                                      givenNode:ExpressionNode, 
                                      xPosition:Number, 
                                      yPosition:Number):ExpressionNode
        {
            // If new symbol is part of a wild card we use the wild card creation function to parse it out
            var i:int;
            var createWildCard:Boolean = false;
            const wildCardSymbols:Vector.<String> = WildCardNode.WILD_CARD_SYMBOLS;
            for (i = 0; i < wildCardSymbols.length; i++)
            {
                if (newLeafSymbol.charAt(0) == wildCardSymbols[i])
                {
                    createWildCard = true;
                    break;
                }
            }
            
            const newLeafNode:ExpressionNode = (createWildCard) ?
                WildCardNode.createWildCardNode(m_vectorSpace, newLeafSymbol) : new ExpressionNode(m_vectorSpace, newLeafSymbol);
            newLeafNode.position.x = xPosition;
            newLeafNode.position.y = yPosition;
            this.addOperatorToNewNode(newLeafNode, givenNode, operator, isNewLeafLeft);
            
            return newLeafNode;
        }
        
        /**
         * Internal function when given an already created nodes, correctly re-arrange the links to make sure
         * a node becomes the sibling
         */
        private function addOperatorToNewNode(newNode:ExpressionNode, 
                                              existingNode:ExpressionNode, 
                                              operator:String, 
                                              isNewNodeLeft:Boolean):void
        {
            // If the root is null the new becomes the new root and exit
            // there is nothing to apply the operator to anyways
            if (m_root == null)
            {
                m_root = newNode;
            }
            else
            {
                var newOperatorNode:ExpressionNode = new ExpressionNode(m_vectorSpace, operator);
                
                // Link the old parent to the new operator
                var oldParentOfGivenNode:ExpressionNode = existingNode.parent;
                if (oldParentOfGivenNode == null)
                {
                    // The new operator node will become the new root
                    m_root = newOperatorNode;
                }
                else
                {
                    var wasGivenNodeLeft:Boolean = (oldParentOfGivenNode.left == existingNode);
                    if (wasGivenNodeLeft) 
                    {
                        oldParentOfGivenNode.left = newOperatorNode;
                    }
                    else
                    {
                        oldParentOfGivenNode.right = newOperatorNode;
                    }
                }
                newOperatorNode.parent = oldParentOfGivenNode;
                existingNode.parent = newOperatorNode;
                
                
                newNode.parent = newOperatorNode;
                if (isNewNodeLeft)
                {
                    newOperatorNode.left = newNode;
                    newOperatorNode.right = existingNode;
                }
                else
                {
                    newOperatorNode.left = existingNode;
                    newOperatorNode.right = newNode;
                }
            }
        }
        
        /**
         * Given two nodes, treat the pair as defining the righmost and leftmost terms of a subexpression
         * to be wrapped in parenthesis.
         * 
         * @param nodeA
         * @param nodeB
         */
        public function addParenenthesis(nodeA:ExpressionNode, 
                                         nodeB:ExpressionNode):void
        {
            var commonParent:ExpressionNode = ExpressionUtil.findLowestCommonAncestor(nodeA, nodeB);

            /*
            FOR ADDING PARENS (Removing parens is generally going to be more difficult)
            Our main goal is to manipulate the existing tree such that we create a subtree
            such that the left to right ordering of the terms is kept the same as before
            BUT the two selected terms are the left most and right most leaves of that subtree.
            */
            
            // First get the common parent that is the operator to be parenthesized
            // Figure out which of the given nodes is the left most and which is the right most.
            // From each node trace up the parent until we see it is the left or right child
            // Just picking nodeA arbitrarily, could easily pick nodeB
            var nodeTracker:ExpressionNode = nodeA;
            while (nodeTracker.parent != null && nodeTracker.parent != commonParent)
            {
                nodeTracker = nodeTracker.parent;
            }
            
            var leftMostNode:ExpressionNode = (commonParent.left == nodeTracker) ? nodeA : nodeB;
            var rightMostNode:ExpressionNode = (commonParent.right == nodeTracker) ? nodeA : nodeB;
            
            /*
            Suppose we trace a path up from each node to the common parent. Going up there will be segments of the path tilting
            left or right at small angle.
            
            Looking at the left most node, the simplest scenario has path segments always tilting to the right since this
            would indicate that nothing outside the left paren get evaluated before the terms inside the parens.
            However, if we do get a path tilting left then we need to disconnect the parent and child joined by that path.
            
            Remember that the common parent is the 'root' of the new parenthesized sub expression. It's left child is the combination
            of children whose parent path was a direction change and pointing left
            
            Similar rules apply to the right most node, where a path tilting right requires disconnecting the parent and child.
            The resulting child becomes the right child of the common parent. The resulting parent if it exists has as its left child
            either the common parent or the parent we got from tracing up the left most.
            */
            
            // Figure out which nodes should become the children of the previous common parent
            // These are the terms to be parenthesized.
            var parentPathTiltRight:Boolean = true;
            
            // You will want to think about the continous segment after the links have been severed
            // In some cases the links may not exist if there is a change in direction every time
            var topMostNodeTiltLeftA:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            var topMostNodeTiltRightA:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            var bottomMostNodeTiltLeftA:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            var bottomMostNodeTiltRightA:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            
            var leftNodeTracker:ExpressionNode = leftMostNode;
            while (leftNodeTracker != commonParent)
            {
                // If the tracker is a right child, the path is tilting left
                var leftNodeTrackerParent:ExpressionNode = leftNodeTracker.parent;
                if (leftNodeTrackerParent.right == leftNodeTracker)
                {
                    // On a change of direction, we add the topmost node of the previous path
                    // that tilted in the same direction
                    // AND the bottommost of the node going in the new direction.
                    if (parentPathTiltRight)
                    {
                        topMostNodeTiltRightA.push(leftNodeTracker);
                        bottomMostNodeTiltLeftA.push(leftNodeTrackerParent);
                        parentPathTiltRight = false;
                        
                    }
                }
                // If the tracker is a left child, the path is tilting right
                else
                {
                    if (!parentPathTiltRight)
                    {
                        topMostNodeTiltLeftA.push(leftNodeTracker);
                        bottomMostNodeTiltRightA.push(leftNodeTrackerParent);
                        parentPathTiltRight = true;
                    }
                }
                
                leftNodeTracker = leftNodeTrackerParent;
            }
            
            parentPathTiltRight = false;
            var topMostNodeTiltLeftB:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            var topMostNodeTiltRightB:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            var bottomMostNodeTiltLeftB:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            var bottomMostNodeTiltRightB:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            
            // Do mostly the same thing we did with the right side of the common parent as we did
            // with the left side
            var rightNodeTracker:ExpressionNode = rightMostNode;
            while (rightNodeTracker != commonParent)
            {
                var rightNodeTrackerParent:ExpressionNode = rightNodeTracker.parent;
                if (rightNodeTrackerParent.right == rightNodeTracker)
                {
                    // On a change of direction, we add the topmost node of the previous path
                    // that tilted in the same direction
                    // AND the bottommost of the node going in the new direction.
                    if (parentPathTiltRight)
                    {
                        topMostNodeTiltRightB.push(rightNodeTracker);
                        bottomMostNodeTiltLeftB.push(rightNodeTrackerParent);
                        parentPathTiltRight = false;
                    }
                }
                else
                {
                    if (!parentPathTiltRight)
                    {
                        topMostNodeTiltLeftB.push(rightNodeTracker);
                        bottomMostNodeTiltRightB.push(rightNodeTrackerParent);
                        parentPathTiltRight = true;
                    }
                }
                
                rightNodeTracker = rightNodeTrackerParent;
            }
            
            // Do not modify the tree structures until the end
            // For the left most node, the top most nodes of the continuous segments ended tilting right join
            // together with the bottom most nodes of the continuous segments that start tilting right
            // This forms the left side of the parenthesized operator
            // Similarly the top most of segment tilting left join with the bottom most that start tilting left
            // This forms the subtree that now gets evaluated before the parenthesis
            var i:int;
            for (i = 0; i < topMostNodeTiltRightA.length; i++)
            {
                var newChild:ExpressionNode = topMostNodeTiltRightA[i];
                var newParent:ExpressionNode = bottomMostNodeTiltRightA[i];
                newChild.parent = newParent;
                newParent.left = newChild;
            }
            
            for (i = 0; i < topMostNodeTiltLeftA.length; i++)
            {
                newChild = topMostNodeTiltLeftA[i];
                newParent = bottomMostNodeTiltLeftA[i];
                newChild.parent = newParent;
                newParent.right = newChild;
            }
            
            for (i = 0; i < topMostNodeTiltRightB.length; i++)
            {
                newChild = topMostNodeTiltRightB[i];
                newParent = bottomMostNodeTiltRightB[i];
                newChild.parent = newParent;
                newParent.left = newChild;
            }
            
            for (i = 0; i < topMostNodeTiltLeftB.length; i++)
            {
                newChild = topMostNodeTiltLeftB[i];
                newParent = bottomMostNodeTiltLeftB[i];
                newChild.parent = newParent;
                newParent.right = newChild;
            }
            
            // Special ending case, the common ancestor may need to become the child of the very first node
            // in which the tilt to the left started.
            // I.e. if bottomMostNodeTiltLeft has at least one element, that first element is the parent
            // of the common ancestor.
            // If this happens the last element of of topMostNodeTiltLeft becomes the new subtree root
            var leftNodeToAttachToCommonParent:ExpressionNode = null;
            var newSubtreeRootOfLeft:ExpressionNode = null;
            if (bottomMostNodeTiltLeftA.length > 0)
            {
                leftNodeToAttachToCommonParent = bottomMostNodeTiltLeftA[0];
                newSubtreeRootOfLeft = topMostNodeTiltLeftA[topMostNodeTiltLeftA.length - 1];
            }
            
            // NOTE: the right side subtree overrides the left as being the new root if applicable
            var rightNodeToAttachToCommonParent:ExpressionNode = null;
            var newSubtreeRootOfRight:ExpressionNode = null;
            if (bottomMostNodeTiltRightB.length > 0)
            {
                rightNodeToAttachToCommonParent = bottomMostNodeTiltRightB[0];
                newSubtreeRootOfRight = topMostNodeTiltRightB[topMostNodeTiltRightB.length - 1];
            }
            
            // If the common parent had a parent we need to reattach the pointers to the new subtree root
            var oldSubtreeParent:ExpressionNode = commonParent.parent;
            var wasCommonParentLeft:Boolean = (oldSubtreeParent != null) ? oldSubtreeParent.left == commonParent : false;
            
            // Move the common parent to its correct new position, any missing children at the very
            // 'bottom' of the trees that were formed while links were severed by changes in direction
            // need to be filled in. Due to evaluation ordering, the left is always processed first.
            if (leftNodeToAttachToCommonParent != null)
            {
                leftNodeToAttachToCommonParent.right = commonParent;
                commonParent.parent = leftNodeToAttachToCommonParent;
            }
            
            if (rightNodeToAttachToCommonParent != null)
            {
                if (newSubtreeRootOfLeft != null)
                {
                    rightNodeToAttachToCommonParent.left = newSubtreeRootOfLeft;
                    newSubtreeRootOfLeft.parent = rightNodeToAttachToCommonParent;
                }
                else
                {
                    rightNodeToAttachToCommonParent.left = commonParent;
                    commonParent.parent = rightNodeToAttachToCommonParent;
                }
            }
            
            // Fix up the old parent links of the previous common parent so it points to the correct new subtree.
            // Note that the right subtree takes priority this time since we want any left subtree to
            // be evaluated first
            if (oldSubtreeParent != null)
            {
                if (newSubtreeRootOfRight != null)
                {
                    if (wasCommonParentLeft)
                    {
                        oldSubtreeParent.left = newSubtreeRootOfRight;
                    }
                    else
                    {
                        oldSubtreeParent.right = newSubtreeRootOfRight;
                    }
                    newSubtreeRootOfRight.parent = oldSubtreeParent;
                }
                else if (newSubtreeRootOfLeft != null)
                {
                    if (wasCommonParentLeft)
                    {
                        oldSubtreeParent.left = newSubtreeRootOfLeft;
                    }
                    else
                    {
                        oldSubtreeParent.right = newSubtreeRootOfRight;   
                    }
                    newSubtreeRootOfLeft.parent = oldSubtreeParent;
                }
            }
            else
            {
                // The common parent was the root, re-assign the root
                if (newSubtreeRootOfRight != null)
                {
                    m_root = newSubtreeRootOfRight;
                    newSubtreeRootOfRight.parent = null;
                }
                else if (newSubtreeRootOfLeft != null)
                {
                    m_root = newSubtreeRootOfLeft;
                    newSubtreeRootOfLeft.parent = null;
                }
            }
            
            commonParent.wrapInParentheses = true;
        }
        
        public function removeParenthesis(nodeWithParenthesis:ExpressionNode):void
        {
            if (nodeWithParenthesis.wrapInParentheses)
            {
                /*
                In certain cases we cannot simply turn off the parenthesis for a node since it will
                introduce ambiguity in the left to right rendering of a expression.
                
                This occurs if the node is an operator and has a parent operator which has higher evaluation precedence
                than the node itself.
                The cases would be:
                add/subtract is the right child of an add/subtract
                multiply/divide is the right child of a multiply/divide
                add/subtract is a child of a multiply/divide
                */
                nodeWithParenthesis.wrapInParentheses = false;
                if (nodeWithParenthesis.parent != null && nodeWithParenthesis.isOperator())
                {
                    var nodeWithParenthesisParent:ExpressionNode = nodeWithParenthesis.parent;
                    var isNodeLeftChild:Boolean = (nodeWithParenthesisParent.left == nodeWithParenthesis);
                    
                    // Shift links if node is to the right but the operators have the same precedence OR
                    // The node has a lower operator precedence so without the parenthesis we want this operator to
                    // now be evaluated first.
                    var nodePrecedence:int = m_vectorSpace.getOperatorPrecedence(nodeWithParenthesis.data);
                    var parentPrecedence:int = m_vectorSpace.getOperatorPrecedence(nodeWithParenthesisParent.data);
                    var doReorganizeTree:Boolean = (nodePrecedence == parentPrecedence && !isNodeLeftChild) || (nodePrecedence < parentPrecedence);
                    if (doReorganizeTree)
                    {
                        var nodeWithParenthesisGrandparent:ExpressionNode = nodeWithParenthesis.parent.parent;
                        var isParentLeftChild:Boolean = (nodeWithParenthesisGrandparent != null) ? nodeWithParenthesisGrandparent.left == nodeWithParenthesisParent : false;
                        
                        // If we need to shift around the tree, the node operator will always become the new parent
                        if (isNodeLeftChild)
                        {
                            var oldRightChild:ExpressionNode = nodeWithParenthesis.right;
                            
                            nodeWithParenthesis.right = nodeWithParenthesisParent;
                            nodeWithParenthesisParent.parent = nodeWithParenthesis;
                            
                            nodeWithParenthesisParent.left = oldRightChild;
                            oldRightChild.parent = nodeWithParenthesisParent;
                        }
                        else
                        {
                            var oldLeftChild:ExpressionNode = nodeWithParenthesis.left;
                            
                            nodeWithParenthesis.left = nodeWithParenthesisParent;
                            nodeWithParenthesisParent.parent = nodeWithParenthesis;
                            
                            nodeWithParenthesisParent.right = oldLeftChild;
                            oldLeftChild.parent = nodeWithParenthesisParent;
                        }
                        
                        if (nodeWithParenthesisGrandparent != null)
                        {
                            if (isParentLeftChild)
                            {
                                nodeWithParenthesisGrandparent.left = nodeWithParenthesis;
                                nodeWithParenthesis.parent = nodeWithParenthesisGrandparent;
                            }
                            else
                            {
                                nodeWithParenthesisGrandparent.right = nodeWithParenthesis;
                                nodeWithParenthesis.parent = nodeWithParenthesisGrandparent; 
                            }
                        }
                        else
                        {
                            nodeWithParenthesis.parent = null;
                            m_root = nodeWithParenthesis;
                        }
                    }
                    
                    // After finish need to re-add any implicit parens since we may again have a situation where
                    // even after moving things around one time leaves subtrees where the order of operations is important
                    ExpressionUtil.addImplicitParentheses(m_root, m_vectorSpace);
                }
            }
        }
        
        /**
         * Take a node in the existing tree and move it to a new neighbor
         * 
         * @param nodeToMove
         *      Reference to the node to move to a new position
         * @param neighborNode
         *      Reference to the new neighbor node the nodeToMove should now be positioned
         *      next to
         * @param leftOfNeighbor
         *      True if the nodeToMove should be the left sibling, false if it should be the right sibling
         * 
         */
        public function moveNode(nodeToMove:ExpressionNode, 
                                 neighborNode:ExpressionNode,
                                 operator:String,
                                 leftOfNeighbor:Boolean):void
        {
            this._removeNode(nodeToMove);
            this.addOperatorToNewNode(nodeToMove, neighborNode, operator, leftOfNeighbor);
            
            dispatchEventWith(ExpressionTreeEvent.MOVE, false);
        }
        
        /**
         * Note that if the given node is a subtree, that entire subtree will be removed along with
         * the given node and its parent operator if that exists as well. (This is because we assume
         * non-leaf nodes to be binary operators)
         * 
         * @return
         *         The new root of the tree
         */
        public function removeNode(node:ExpressionNode):void
        {
            _removeNode(node);
            
            // Dispatch a removal event
            dispatchEventWith(ExpressionTreeEvent.REMOVE, false, {nodeId:node.id});
        }
        
        /**
         * Replace a given node in this tree with a replacement subtree.
         * Note that any children belonging to the node to the replace will be removed as well.
         * 
         * A copy of the given replacement tree is made so the structure passed in will be left
         * unmodified after this function call.
         * 
         * @param nodeToReplace
         *      Reference to the node to be pruned out and replaced
         * @param replacementRoot
         *      Tree structure of the expression to be injected into the tree. A copy is added to 
         *      the actual tree
         * @return
         *         The replacement subtree that has been embedded in the tree structure
         */
        public function replaceNode(nodeToReplace:ExpressionNode, 
                                    replacementRoot:ExpressionNode):ExpressionNode
        {
            // For each of replacement nodes create a new copy following the same structure.
            const replacementRootCopy:ExpressionNode = ExpressionUtil.copy(replacementRoot, m_vectorSpace);
            this._replaceNode(nodeToReplace, replacementRootCopy);
            dispatchEventWith(
                ExpressionTreeEvent.SUBSTITUTE, 
                false, 
                {nodeIdToReplace:nodeToReplace.id, subtreeToReplace:replacementRootCopy}
            );
            
            // Replacement might cause new parentheses to crop up, we need to explicitly insert them
            ExpressionUtil.addImplicitParentheses(m_root, m_vectorSpace);
            
            return replacementRootCopy;
        }
        
        private function _removeNode(node:ExpressionNode):void
        {
            var newRoot:ExpressionNode = ExpressionUtil.removeNode(m_root, node);
            m_root = newRoot;
        }
        
        /**
         * Internal function to replace a subtree with another subtree
         * 
         * @return
         *      The reference to the replacement subtree, right now the routine uses 
         */
        private function _replaceNode(nodeToReplace:ExpressionNode, 
                                      replacementRoot:ExpressionNode):void
        {
            // Replacing the tree root
            if (nodeToReplace == m_root)
            {
                m_root = replacementRoot;
            }
            else
            {
                var nodeToReplaceParent:ExpressionNode = nodeToReplace.parent;
                var isNodeToReplaceLeft:Boolean = (nodeToReplaceParent.left == nodeToReplace);
                if (isNodeToReplaceLeft)
                {
                    nodeToReplaceParent.left = replacementRoot;
                }
                else
                {
                    nodeToReplaceParent.right = replacementRoot;    
                }
                replacementRoot.parent = nodeToReplaceParent;
            }
        }
        
        /**
         * Given an existing operator node, change it's data to a new value
         */
        public function changeOperatorOnNode(nodeToChange:ExpressionNode, 
                                             newOperatorValue:String):void
        {
            // Make sure the node to change is actually an operator and the new value
            // is also an operator, prevent the expression tree from being malformed
            if (nodeToChange != null && nodeToChange.isOperator())
            {
                var newOperatorNode:ExpressionNode = new ExpressionNode(m_vectorSpace, newOperatorValue);
                
                var leftChild:ExpressionNode = nodeToChange.left;
                leftChild.parent = newOperatorNode;
                newOperatorNode.left = leftChild;
                
                var rightChild:ExpressionNode = nodeToChange.right;
                rightChild.parent = newOperatorNode;
                newOperatorNode.right = rightChild;
                
                _replaceNode(nodeToChange, newOperatorNode);
                
                // If node to change was wrapped in parenthesis then the new node should be as well
                newOperatorNode.wrapInParentheses = nodeToChange.wrapInParentheses;
                
                // Clean up old link on the replaced operator
                nodeToChange.left = null;
                nodeToChange.right = null;
                nodeToChange.parent = null;
                
                // Replacement might cause new parentheses to crop up, we need to explicitly insert them
                ExpressionUtil.addImplicitParentheses(m_root, m_vectorSpace);
            }
        }
        
        /**
         * Simplify just a single node. This type of simplification just encompasses the
         * removal of zero added to something or a one multiplied by something.
         */
        public function simplifyNode(node:ExpressionNode):Boolean
        {
            var canSimplify:Boolean = false;
            
            // Don't allow for removal of zero if it is the last thing on the board.
            if (node.parent == null)
            {
                return false;
            }
            
            var numericRegex:RegExp = ExpressionUtil.NUMERIC_REGEX;
            var nodeNumeric:Boolean = node.data.search(ExpressionUtil.NUMERIC_REGEX) == 0;
            if (nodeNumeric)
            {
                var nodeValue:int = parseInt(node.data);
                if (nodeValue == m_vectorSpace.zero())
                {
                    if (node.parent.isSpecificOperator(m_vectorSpace.getAdditionOperator()) ||
                        node.parent.isSpecificOperator(m_vectorSpace.getSubtractionOperator()))
                    {
                        canSimplify = true;
                        _removeNode(node);
                    }
                }
                else if (nodeValue == m_vectorSpace.identity())
                {
                    if (node.parent.isSpecificOperator(m_vectorSpace.getMultiplicationOperator()) ||
                        node.parent.isSpecificOperator(m_vectorSpace.getDivisionOperator()) && 
                        ExpressionUtil.isNodePartOfDenominator(m_vectorSpace, node))
                    {
                        canSimplify = true;
                        _removeNode(node);
                    }
                }
            }
            
            if (canSimplify)
            {
                var nodeIdsToSimplify:Vector.<int> = new Vector.<int>();
                nodeIdsToSimplify.push(node.id);
                dispatchEventWith(ExpressionTreeEvent.SIMPLIFY_SINGLE, false, {nodeIds:nodeIdsToSimplify});
            }
            
            return canSimplify
        }
        
        /**
         * TODO: Needs to deal with which side needs to be replaced
         * Is a specific case of the function to simplify a pair of subtrees?
         * 
         * @param nodeA
         * @param nodeB
         * @return
         *      True is a simplification occured
         */
        public function simplifyNodes(nodeA:ExpressionNode, 
                                      nodeB:ExpressionNode):Boolean
        {
            var canSimplify:Boolean = false;
            
            // The two nodes need to be leaves
            if (nodeA.isLeaf() && nodeB.isLeaf())
            {
                if (simplifyNode(nodeA) || simplifyNode(nodeB))
                {
                    return true;
                }
                
                var numericRegex:RegExp = ExpressionUtil.NUMERIC_REGEX;
                var nodeANumeric:Boolean = nodeA.data.search(numericRegex) == 0;
                var nodeBNumeric:Boolean = nodeB.data.search(numericRegex) == 0;
                var nodeAValue:int = parseInt(nodeA.data);
                var nodeBValue:int = parseInt(nodeB.data);
                if (ExpressionUtil.canAddNode(nodeA, nodeB, m_vectorSpace, true))
                {
                    // Two numeric values simply produces another value that is the sum
                    if (nodeANumeric && nodeBNumeric)
                    {
                        canSimplify = true;
                        var sumValue:int = m_vectorSpace.add(nodeAValue, nodeBValue);
                        _replaceNode(nodeA, new ExpressionNode(m_vectorSpace, sumValue + ""));
                        _removeNode(nodeB);
                    }
                    // Two symbols can simplify if its the inverse plus normal to produce zero
                    // or possibly two nodes of the same symbol adding to produce 2*symbol
                    else if (!nodeANumeric && !nodeBNumeric)
                    {
                        canSimplify = simplifyPairOfSubtrees(nodeA, nodeB, m_vectorSpace);
                    }
                }
                else if (ExpressionUtil.canDivideNode(nodeA, nodeB, m_vectorSpace, true))
                {
                    var nodeAIsDenominator:Boolean = ExpressionUtil.isNodePartOfDenominator(m_vectorSpace, nodeA);
                    var numerator:ExpressionNode = (nodeAIsDenominator) ? nodeB : nodeA;
                    var denominator:ExpressionNode = (nodeAIsDenominator) ? nodeA : nodeB;
                    
                    // Two symbols dividing each other only makes sense if its the same symbol to produce 1
                    // or opposite symbols to produce -1
                    if (numerator.data == denominator.data)
                    {
                        canSimplify = true;
                        _replaceNode(numerator, new ExpressionNode(m_vectorSpace, m_vectorSpace.identity() + ""));
                        _removeNode(denominator);
                    }
                    else if (nodeANumeric && nodeBNumeric)
                    {
                        // Find the greatest common denominator between the two values
                        var gcd:int = MathUtil.greatestCommonDivisor(nodeAValue, nodeBValue);
                        if (gcd != m_vectorSpace.identity())
                        {
                            canSimplify = true;
                            nodeAValue = nodeAValue / gcd;
                            const newNodeA:ExpressionNode = new ExpressionNode(m_vectorSpace, nodeAValue + "")
                            _replaceNode(nodeA, newNodeA);
                            nodeA = newNodeA;
                            
                            nodeBValue = nodeBValue / gcd;
                            const newNodeB:ExpressionNode = new ExpressionNode(m_vectorSpace, nodeBValue + "");
                            _replaceNode(nodeB, newNodeB);
                            nodeB = newNodeB;
                        }
                    }
                    
                    // Check if you can eliminate a one in the denominator
                    if (nodeAValue == m_vectorSpace.identity() && ExpressionUtil.isNodePartOfDenominator(m_vectorSpace, nodeA))
                    {
                        canSimplify = true;
                        _removeNode(nodeA);
                    }
                    else if (nodeBValue == m_vectorSpace.identity() && ExpressionUtil.isNodePartOfDenominator(m_vectorSpace, nodeB))
                    {
                        canSimplify = true;
                        _removeNode(nodeB);
                    }
                }
                else if (ExpressionUtil.canMultiplyNode(nodeA, nodeB, m_vectorSpace, true))
                {
                    if (nodeANumeric && nodeBNumeric)
                    {
                        canSimplify = true;
                        var multiplyValue:int = m_vectorSpace.mul(nodeAValue, nodeBValue);
                        _replaceNode(nodeA, new ExpressionNode(m_vectorSpace, multiplyValue + ""));
                        _removeNode(nodeB);
                    }
                    
                    // Two symbols multiplying only make sense if they are the same value and we have exponents
                }
            }
            
            if (canSimplify)
            {
                var nodeIdsToSimplify:Vector.<int> = new Vector.<int>();
                nodeIdsToSimplify.push(nodeA.id, nodeB.id);
                dispatchEventWith(ExpressionTreeEvent.SIMPLIFY_PAIR, false, {nodeIds:nodeIdsToSimplify});
            }
            
            return canSimplify;
        }
        
        /**
         * Given a node get the other nodes in this expression that it can distribute with.
         * 
         * Here are the restrictions that we enforce:
         * The node to distribute cannot be wrapped in parentheses
         * (BUG: need to handle distributing a denominator)
         * 
         * @param nodeToDistribute
         * @param outDistributionOptions
         *      An output of the nodes that it is possible to distribute to
         * @param outDistributionOperators
         *      An output of the operator for the distribution (either mult or div) with items indexed
         *      exactly the same as the list of nodes.
         * @return
         *      true if the target node can distribute with something
         */
        public function getDistributionOptions(nodeToDistribute:ExpressionNode, 
                                               outDistributionOptions:Vector.<ExpressionNode>, 
                                               outDistributionOperators:Vector.<String>):Boolean
        {
            // Gather all parentheses terms in the expression.
            const nodesWrappedInParens:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            ExpressionUtil.getNodesWrappedInParentheses(m_root, nodesWrappedInParens);
            
            // For each one get the lowest common ancestor and the path to that ancestor 
            // for both the paren node and the picked node.
            for (var i:int = 0; i < nodesWrappedInParens.length; i++)
            {
                const nodeWrappedInParen:ExpressionNode = nodesWrappedInParens[i];
                
                if (!ExpressionUtil.containsNode(nodeWrappedInParen, nodeToDistribute))
                {
                    var ancestor:ExpressionNode = ExpressionUtil.findLowestCommonAncestor(nodeToDistribute, nodeWrappedInParen);
                    
                    // If ancestor is a division then the node to distribute must be part of the denominator
                    if (ancestor.isSpecificOperator(m_vectorSpace.getMultiplicationOperator()) ||
                        ancestor.isSpecificOperator(m_vectorSpace.getDivisionOperator()) &&
                        ExpressionUtil.isNodePartOfDenominator(m_vectorSpace, nodeToDistribute))
                    {
                        // Analyzing the path, if any of the operators up to the ancestor are wrapped 
                        // in parens then the search fails immediately as it indicates that the nodes are 
                        // in separate parentheses group. It should also fail if any node along the path is 
                        // not a multiplication operator.
                        var nodeToDistributePath:Vector.<ExpressionNode> = ExpressionUtil.getPathUpToNode(nodeToDistribute, ancestor);
                        var nodeInParensPath:Vector.<ExpressionNode> = ExpressionUtil.getPathUpToNode(nodeWrappedInParen, ancestor);
                        const allowDistribution:Boolean = nodesInPathAllowDistribution(nodeToDistributePath, m_vectorSpace) && 
                            nodesInPathAllowDistribution(nodeInParensPath, m_vectorSpace);
                        
                        // If the distribution is valid, the operator of the ancestor will tell 
                        // us if the distribution should be a multiplication or a division.
                        if (allowDistribution)
                        {
                            outDistributionOptions.push(nodeWrappedInParen);
                            outDistributionOperators.push(ancestor.data);
                        }
                    }
                }
            }
            
            return outDistributionOptions.length > 0;
        }
        
        private function nodesInPathAllowDistribution(path:Vector.<ExpressionNode>, vectorSpace:IVectorSpace):Boolean
        {
            var allowDistribution:Boolean = true;
            for (var j:int = 0; j < path.length - 1; j++)
            {
                const nodeInPath:ExpressionNode = path[j];
                if (nodeInPath.wrapInParentheses || 
                    !nodeInPath.isSpecificOperator(vectorSpace.getMultiplicationOperator()))
                {
                    allowDistribution = false;
                    break;
                }
            }
            return allowDistribution;
        }
        
        /**
         * Attempt to distribute the given node to the target
         */
        public function distribute(nodeToDistribute:ExpressionNode, targetNode:ExpressionNode):void
        {
            // Perform a check whether the given distribution is valid
            const distributionOptions:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            const distributionOperators:Vector.<String> = new Vector.<String>();
            if (getDistributionOptions(nodeToDistribute, distributionOptions, distributionOperators))
            {
                var matchedDistributionTarget:Boolean = false;
                for (var distributionIndex:int = 0; distributionIndex < distributionOptions.length; distributionIndex++)
                {
                    const nodeToDistributeTo:ExpressionNode = distributionOptions[distributionIndex];
                    if (nodeToDistributeTo == targetNode)
                    {
                        matchedDistributionTarget = true;
                        break;
                    }
                }
                
                if (matchedDistributionTarget)
                {
                    const operatorToDistribute:String = distributionOperators[distributionIndex];
                    
                    // Within the target node we must find all groups of nodes that joined together by
                    // a top level addition node. Note it is possible we just have one such group in which
                    // case no top level addition is even found.
                    // We first need to ignore the wrapping parentheses around the target, we will need to
                    // remember to add it back later. If we didn't do this we would not be able to correctly fetch
                    // the additive groups in the target node, it would always just return the target.
                    targetNode.wrapInParentheses = false;
                    var additiveRoots:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
                    ExpressionUtil.getCommutativeGroupRoots(
                        targetNode, 
                        m_vectorSpace.getAdditionOperator(), 
                        additiveRoots);
                    
                    // For each additive root, create a copy of the node to distribute
                    for (var i:int = 0; i < additiveRoots.length; i++)
                    {
                        var additiveRoot:ExpressionNode = additiveRoots[i];
                        
                        // We want the newly distributed node to appear to the left of any subexpression
                        // that it attaches itself to.
                        
                        // If the additive root has a parentheses we apply the operator directly on it
                        // Also do this if the root is just a leaf.
                        var nodeToAttachTo:ExpressionNode;
                        var operatorToAttachTo:String;
                        var attachToLeft:Boolean;
                        
                        // If the root is in parentheses OR it is not a division we apply the operation
                        // directly on the root.
                        const rootIsDivision:Boolean = additiveRoot.isSpecificOperator(m_vectorSpace.getDivisionOperator());
                        if (additiveRoot.wrapInParentheses && additiveRoots.length >= 1 || 
                            !rootIsDivision)
                        {
                            nodeToAttachTo = additiveRoot;
                            operatorToAttachTo = operatorToDistribute;
                            
                            // If operator is multiplication we add it to the furthest left of the tree
                            if (operatorToDistribute == m_vectorSpace.getMultiplicationOperator())
                            {
                                nodeToAttachTo = additiveRoot.left;
                                attachToLeft = true;
                            }
                            else if (operatorToDistribute == m_vectorSpace.getDivisionOperator())
                            {
                                // If operator is division we add the node to the right
                                attachToLeft = false;
                            }
                        }
                        else
                        {
                            // Otherwise it is a division, we need to take the correct path to the node to attach it to
                            // If the operator is multiplication we use the left child of the root.
                            
                            if (operatorToDistribute == m_vectorSpace.getMultiplicationOperator())
                            {
                                nodeToAttachTo = additiveRoot.left;
                            }
                            // If the operator is division we use the right child of the root.
                            else if (operatorToDistribute == m_vectorSpace.getDivisionOperator())
                            {
                                nodeToAttachTo = additiveRoot.right;
                            }
                            // In both cases the operator we are adding is a multiplication
                            operatorToAttachTo = m_vectorSpace.getMultiplicationOperator();
                            attachToLeft = true;
                        }
                        
                        // If the node to distribute to is a leaf we have no choice but to attach to it
                        if (additiveRoot.isLeaf())
                        {
                            nodeToAttachTo = additiveRoot;
                        }
                        
                        _addLeafNode(operatorToAttachTo, nodeToDistribute.data, attachToLeft, nodeToAttachTo, 0, 0);
                    }
                    
                    // Put the parentheses back
                    // TODO: NEED TO FIX THIS may not be the correct spot to do so.
                    // Edge case the target is a single node with parens, the paren needs to expand to fit in
                    // the distributed value (the target node no longer has the parens in this case)
                    if (additiveRoots.length == 1)
                    {
                        targetNode.parent.wrapInParentheses = true;
                    }
                    else
                    {
                        targetNode.wrapInParentheses = true;
                    }
                    
                    // Prune the node to distribute
                    _removeNode(nodeToDistribute);
                    
                    this.dispatchEventWith(ExpressionTreeEvent.DISTRIBUTE);
                }
            }
        }
        
        /**
         * Simplify a set of nodes, we assume that the nodes in the set can be perfectly
         * separated into two clusters which are added or subtracted with each other
         * 
         * @param nodes
         *         List of leafs nodes
         */
        public function simplifyCluster(nodes:Vector.<ExpressionNode>, 
                                        vectorSpace:IVectorSpace):Boolean
        {
            var canSimplify:Boolean = false;
            
            // Pick some node, like the first, and check whether the lowest common ancestor between it and
            // others is an addition or a subtraction operator. 
            var nodeA:ExpressionNode = nodes[0];
            for (var i:int = 1; i < nodes.length; i++)
            {
                var nodeB:ExpressionNode = nodes[i];
                var lca:ExpressionNode = ExpressionUtil.findLowestCommonAncestor(nodeA, nodeB);
                if (lca.isSpecificOperator(vectorSpace.getAdditionOperator()))
                {
                    // If we identify one of those operators then check if the tree rooted at that node contains every node in the cluster.
                    var containsAllNodes:Boolean = true;
                    for (var j:int = 0; j < nodes.length; j++)
                    {
                        if (!ExpressionUtil.containsNode(lca, nodes[j]))
                        {
                            containsAllNodes = false;
                            break;
                        }
                    }
                    
                    // If it does then we can now find the two groups. Looking at the two nodes, we trace up to the node whose
                    // parent is an addition or subtraction. This gives us the two groups. Assume that groups are composed
                    // entirely of products and quotients, can enforce this by taking the group root and tracing even
                    // further up until we reach the ancestor. Each operator along this path needs to be an addition or subtraction
                    if (containsAllNodes)
                    {
                        var nodeATrace:ExpressionNode = nodeA;
                        while (nodeATrace.parent != null)
                        {
                            if (nodeATrace.parent.isSpecificOperator(vectorSpace.getAdditionOperator()))
                            {
                                break;
                            }
                            nodeATrace = nodeATrace.parent;
                        }
                        var nodeARoot:ExpressionNode = nodeATrace;
                        
                        var nodeBTrace:ExpressionNode = nodeB;
                        while (nodeBTrace.parent != null)
                        {
                            if (nodeBTrace.parent.isSpecificOperator(vectorSpace.getAdditionOperator()))
                            {
                                break;
                            }
                            nodeBTrace = nodeBTrace.parent;
                        }
                        var nodeBRoot:ExpressionNode = nodeBTrace;
                        
                        // Need a perform the check that the addition parent is not part of a parentheses,
                        // if it is we immediately give up
                        var nodeRootIsParen:Boolean = false;
                        while (nodeATrace != lca && !nodeRootIsParen)
                        {
                            if (nodeATrace.parent.isSpecificOperator(vectorSpace.getAdditionOperator()))
                            {
                                nodeATrace = nodeATrace.parent;
                            }
                            else
                            {
                                nodeRootIsParen = true;
                            }
                        }
                        
                        while (nodeBTrace != lca && !nodeRootIsParen)
                        {
                            if (nodeBTrace.parent.isSpecificOperator(vectorSpace.getAdditionOperator()))
                            {
                                nodeBTrace = nodeBTrace.parent;
                            }
                            else
                            {
                                nodeRootIsParen = true;
                            }
                        }
                        
                        if (!nodeRootIsParen)
                        {
                            canSimplify = simplifyPairOfSubtrees(nodeARoot, nodeBRoot, vectorSpace);
                            break;
                        }
                    }
                }
            }
            
            if (canSimplify)
            {
                const nodeIds:Vector.<int> = new Vector.<int>();
                for each (var node:ExpressionNode in nodes)
                {
                    nodeIds.push(node.id);
                }
                dispatchEventWith(ExpressionTreeEvent.SIMPLIFY_CLUSTER, false, {nodeIds:nodeIds});
            }
            
            return canSimplify;
        }
        
        /**
         * Function to simplify a pair of groups
         */
        public function simplifyPairOfSubtrees(groupRootA:ExpressionNode, 
                                       groupRootB:ExpressionNode, 
                                       vectorSpace:IVectorSpace):Boolean
        {
            var canSimplify:Boolean = false;
            // Assuming that both groups roots are separate additive terms
            // We also force that all variables are part of a product or quotient
            
            // Create two copies of the subtree per each group
            // In one of them we will completely strip out variables and in the other we will strip out literals
            // Need to maintain integer values, so if we have numerators and denominators
            // we may need to keep them separate
            
            var variablesA:ExpressionNode = getStrippedTree(groupRootA, true);
            var variablesB:ExpressionNode = getStrippedTree(groupRootB, true);
            
            // Groups must contain at least one variable each
            if (variablesA == null || variablesB == null)
            {
                return false;
            }
            
            // Need to check whether the structure of the variables in both groups are semantically
            // identical. A simple way to do this with our current assumptions is to keep a tally of the symbols
            // in the numerator and denominator of each group. The tallies for both need to exactly match
            // Also it is important that we strip out any negative values in the variables and apply them to the
            // literals
            var numeratorTallyMap:Map = new Map();
            var denominatorTallyMap:Map = new Map();
            var leafNodesA:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            ExpressionUtil.getLeafNodes(variablesA, leafNodesA);
            
            var negativeBitA:Number = 1;
            for each (var leafNode:ExpressionNode in leafNodesA)
            {
                var leafData:String = leafNode.data;
                
                if (leafData.charAt(0) == vectorSpace.getSubtractionOperator())
                {
                    negativeBitA *= -1;
                    leafData = leafData.substr(1);
                    leafNode.data = leafData;
                }
                
                if (ExpressionUtil.isNodePartOfDenominator(vectorSpace, variablesA))
                {
                    if (denominatorTallyMap.contains(leafData))
                    {
                        var denomTally:int = denominatorTallyMap.get(leafData);
                        denominatorTallyMap.put(leafData, denomTally + 1);
                    }
                    else
                    {
                        denominatorTallyMap.put(leafData, 1);
                    }
                }
                else
                {
                    if (numeratorTallyMap.contains(leafData))
                    {
                        var numeratorTally:int = numeratorTallyMap.get(leafData);
                        numeratorTallyMap.put(leafData, numeratorTally + 1);
                    }
                    else
                    {
                        numeratorTallyMap.put(leafData, 1);
                    }
                }
            }
            
            // Look through the numerator and denominator symbols in the other group.
            // For each symbol we take away one from the tally to indicate a match was found
            // If we find a symbol in this group that wasn't in the other then we can exit early
            var variableStructureMatches:Boolean = true;
            var leafNodesB:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            ExpressionUtil.getLeafNodes(variablesB, leafNodesB);
            
            var negativeBitB:Number = 1;
            for each (leafNode in leafNodesB)
            {
                leafData = leafNode.data;
                
                if (leafData.charAt(0) == vectorSpace.getSubtractionOperator())
                {
                    negativeBitB *= -1;
                    leafData = leafData.substr(1);
                    leafNode.data = leafData;
                }
                
                if (ExpressionUtil.isNodePartOfDenominator(vectorSpace, variablesA))
                {
                    if (denominatorTallyMap.contains(leafData))
                    {
                        denomTally = denominatorTallyMap.get(leafData);
                        denominatorTallyMap.put(leafData, denomTally - 1);
                    }
                    else
                    {
                        variableStructureMatches = false;
                        break;
                    }
                }
                else
                {
                    if (numeratorTallyMap.contains(leafData))
                    {
                        numeratorTally = numeratorTallyMap.get(leafData);
                        numeratorTallyMap.put(leafData, numeratorTally - 1);
                    }
                    else
                    {
                        variableStructureMatches = false;
                        break;
                    }
                }
            }
            
            if (variableStructureMatches)
            {
                // If they match then all the keys in the maps should have a tally of zero
                var numeratorSymbols:Array = numeratorTallyMap.getKeys();
                for each (var numeratorSymbol:String in numeratorSymbols)
                {
                    numeratorTally = numeratorTallyMap.get(numeratorSymbol);
                    if (numeratorTally != 0)
                    {
                        variableStructureMatches = false;
                        break;
                    }
                }
                
                var denominatorSymbols:Array = denominatorTallyMap.getKeys();
                for each (var denominatorSymbol:String in denominatorSymbols)
                {
                    denomTally = denominatorTallyMap.get(denominatorSymbol);
                    if (denomTally != 0)
                    {
                        variableStructureMatches = false;
                        break;
                    }
                }
                
                if (variableStructureMatches)
                {
                    canSimplify = true;
                    var literalsA:ExpressionNode = getStrippedTree(groupRootA, false);
                    var literalsB:ExpressionNode = getStrippedTree(groupRootB, false);
                    
                    // Figure out the numerator and denominator values for each
                    var valueA:Number = (literalsA != null) ? ExpressionUtil.evaluateWithVariableReplacement(literalsA, null, vectorSpace) : vectorSpace.identity();
                    valueA *= negativeBitA;
                    var valueB:Number = (literalsB != null) ? ExpressionUtil.evaluateWithVariableReplacement(literalsB, null, vectorSpace) : vectorSpace.identity();
                    valueB *= negativeBitB;
                    var newValue:Number = vectorSpace.add(valueA, valueB);
                    
                    // Delete one root and replace the other one with a compression tree
                    var newValueNode:ExpressionNode = new ExpressionNode(vectorSpace, newValue + "");
                    
                    // If new value is zero, the replacement node will be a zero
                    // otherwise use the replacement tree.
                    var newGroupRoot:ExpressionNode = (newValue != vectorSpace.zero()) ? ExpressionUtil.createOperatorTree(
                        newValueNode,
                        variablesA, 
                        vectorSpace, 
                        vectorSpace.getMultiplicationOperator()) : newValueNode;
                    this._replaceNode(groupRootA, newGroupRoot);
                    this._removeNode(groupRootB);
                }
            }
            
            return canSimplify;
        }
        
        /**
         * Get back a copy of the subtree with either the variables or literals completely stripped
         * away
         * 
         * @return
         *         null root if the stripped tree has no literals or variables
         */
        public function getStrippedTree(originalRoot:ExpressionNode, stripLiterals:Boolean):ExpressionNode
        {
            var strippedRoot:ExpressionNode = ExpressionUtil.copy(originalRoot, m_vectorSpace);
            var leafNodes:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            var nodesToRemove:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            ExpressionUtil.getLeafNodes(strippedRoot, leafNodes);
            for each (var leafNode:ExpressionNode in leafNodes)
            {
                // If we want to strip variables then remove nodes that are not literals
                var isLiteral:Boolean = leafNode.data.search(ExpressionUtil.NUMERIC_REGEX) == 0
                if (isLiteral && stripLiterals || !isLiteral && !stripLiterals)
                {
                    nodesToRemove.push(leafNode);
                }
            }
            
            for each (var nodeToRemove:ExpressionNode in nodesToRemove)
            {
                // There are a couple of edge cases to deal with,
                // if the node is the lone left child of a subtraction the negative sign needs to
                // get pushed to the right child
                // if the node is the lone left child of a divison, it should be replaced by the identity
                // value since the right child needs to be maintained as the denominator
                var parentNode:ExpressionNode = nodeToRemove.parent;
                if (parentNode != null &&
                    parentNode.isSpecificOperator(m_vectorSpace.getDivisionOperator()) &&
                    parentNode.left == nodeToRemove)
                {
                    nodeToRemove.data = m_vectorSpace.identity() + "";
                }
                else
                {
                    strippedRoot = ExpressionUtil.removeNode(strippedRoot, nodeToRemove);
                }
            }
            
            return strippedRoot;
        }
    }
}