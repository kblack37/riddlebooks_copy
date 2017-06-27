package wordproblem.scripts.equationtotext
{
    import flash.utils.Dictionary;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.expressiontree.WildCardNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    import dragonbox.common.system.Map;
    
    import starling.display.DisplayObject;
    import wordproblem.resource.AssetManager
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.widget.EquationToTextWidget;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.scripts.BaseGameScript;
    
    public class EquationToText extends BaseGameScript
    {
        private var m_termAreas:Vector.<TermAreaWidget>;
        private var m_equationToTextWidget:EquationToTextWidget;
        private var m_regexRoots:Vector.<ExpressionNode>;
        private var m_templateList:Vector.<String>;
        private var m_vectorSpace:IVectorSpace;
        private var m_symbolMap:ExpressionSymbolMap;
        
        public function EquationToText(gameEngine:IGameEngine, 
                                       expressionCompiler:IExpressionTreeCompiler, 
                                       assetManager:AssetManager, 
                                       id:String=null, 
                                       isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            var currentLevel:WordProblemLevelData = m_gameEngine.getCurrentLevel();
            
            var termAreaDisplays:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
            m_termAreas = new Vector.<TermAreaWidget>();
            for each (var termAreaDisplay:DisplayObject in termAreaDisplays)
            {
                m_termAreas.push(termAreaDisplay as TermAreaWidget);
            }
            
            m_equationToTextWidget = m_gameEngine.getUiEntity("equationToText") as EquationToTextWidget;
            m_vectorSpace = m_expressionCompiler.getVectorSpace();
            m_symbolMap = m_gameEngine.getExpressionSymbolResources();
            
            var regexList:Vector.<String> = new Vector.<String>();//currentLevel.getEquationTextRegexList();
            const regexRoots:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            for (var i:int = 0; i < regexList.length; i++)
            {
                const regexRoot:ExpressionNode = m_expressionCompiler.compile(regexList[i]).head;
                regexRoots.push(regexRoot);
            }
            
            m_regexRoots = regexRoots;
            m_templateList = new Vector.<String>();//currentLevel.getEquationTextTemplateList();
            
            setIsActive(m_isActive);
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_ready)
            {
                var i:int;
                var termArea:TermAreaWidget;
                for (i = 0; i < m_termAreas.length; i++)
                {
                    termArea = m_termAreas[i];
                    termArea.removeEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
                    termArea.removeEventListener(GameEvent.TERM_AREA_RESET, onTermAreaReset);
                }
                
                if (value)
                {
                    for (i = 0; i < m_termAreas.length; i++)
                    {
                        termArea = m_termAreas[i];
                        termArea.addEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
                        termArea.addEventListener(GameEvent.TERM_AREA_RESET, onTermAreaReset);
                    }
                }
            }
        }
        
        private function onTermAreaChanged():void
        {
            var i:int;
            var termAreasReady:Boolean = true;
            for (i = 0; i < m_termAreas.length; i++)
            {
                if (!m_termAreas[i].isReady)
                {
                    termAreasReady = false;
                    break;
                }
            }
            
            if (termAreasReady)
            {
                const subtrees:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
                for each (var termArea:TermAreaWidget in m_termAreas)
                {
                    if (termArea.getWidgetRoot() != null)
                    {
                        subtrees.push(termArea.getWidgetRoot().getNode());
                    }
                }
                
                const root:ExpressionNode = ExpressionUtil.compressToSingleTree(subtrees, m_vectorSpace);
                this.setEquationText(root);
            }
        }
        
        private function onTermAreaReset():void
        {
            const subtrees:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            for each (var termArea:TermAreaWidget in m_termAreas)
            {
                if (termArea.getWidgetRoot() != null)
                {
                    subtrees.push(termArea.getWidgetRoot().getNode());
                }
            }
            
            const root:ExpressionNode = ExpressionUtil.compressToSingleTree(subtrees, m_vectorSpace);
            this.setEquationText(root);
        }
        
        public function setEquation(root:ExpressionNode):void
        {
            // Search through every regex for a match
            var resultingText:String;
            var regexMatched:Boolean = false;
            var i:int;
            var wildCardId:String;
            var wildCardToValueMap:Dictionary = new Dictionary();
            const numRegexElements:int = m_regexRoots.length;
            for (i = 0; i < numRegexElements; i++)
            {
                var regexElement:ExpressionNode = m_regexRoots[i];
                
                regexMatched = getExpressionMatchesRegex(regexElement, root, m_vectorSpace, wildCardToValueMap);
                if (regexMatched)
                {
                    break;
                }
                else
                {
                    // Clean out the map for the next search
                    for (wildCardId in wildCardToValueMap)
                    {
                        delete wildCardToValueMap[wildCardId];
                    }
                }
            }
            
            if (regexMatched)
            {
                // The index will give the proper textual template to display to the player.
                resultingText = m_templateList[i];
                
                // If the template has wild card values to fill, we pull the values from the dictionary
                // and use those to replace the spots in the string.
                for (wildCardId in wildCardToValueMap)
                {
                    if (wildCardToValueMap[wildCardId] is ExpressionNode)
                    {
                        // If the matched node is a leaf, just pull its data directly, otherwise we need
                        // to build the tree using the default wordings
                        const expressionNode:ExpressionNode = wildCardToValueMap[wildCardId];
                        
                        var replacementText:String;
                        if (expressionNode.isLeaf())
                        {
                            replacementText = m_symbolMap.getSymbolName(expressionNode.data);
                        }
                        else
                        {
                            replacementText = getStringFromSubtree(root);
                        }
                        
                        resultingText = resultingText.replace(wildCardId, replacementText);
                    }
                        // TODO:
                        // If its not a node then it is a list of expression nodes with a common operator
                        // The main task is to compress the nodes as small as possible
                    else
                    {
                        var expressionNodes:Vector.<ExpressionNode> = wildCardToValueMap[wildCardId];
                        if (expressionNodes.length == 1) { //the wild card can be replaced by evaluating a simple expression
                            resultingText = resultingText.replace(wildCardId, expressionNodes[0].toString());
                        }
                        else { // TODO: The more complex case
                            resultingText = resultingText.replace(wildCardId, "48");
                        }
                    }
                }
            }
            else
            {
                resultingText = getStringFromSubtree(root);
            }
            
            m_equationToTextWidget.setText(resultingText, root);
        }
        
        /**
         * setEq(node) is an alternative version of setEquation(node) for generating test to describe the equation that has just been changed in the Term Area.
         * Called by onTermAreaChanged event.
         * Maintains the same basic form of the older setEquation(), which is to search through a list of template descriptions for the expression node for the new equation and
         * upon finding a match, replace "wildcards" with text that expresses the particular values that appear in the equation.
         * 
         * The older version did this matching and substitution on a textual basis, using "regEx"'s and text replacement for "wildcard" text markers. 
         * The newer version will attempt to be more propositional and semantic, that is, the templates will have a set of "propositions" which if true when evaluated on the root node
         * will indicate a match. Similarly, when replacing "wildcards" there will be a more propositional (first order logic) matching done so that descriptive words and phrases can be substituted
         * that are sematically related to the subtrees in the expression which match.
         * 
         * At least that's the hope.
         * 
         * The scheme will involve tables of functions (defined in dragonbox.common.ExpressionUtil.as) to evaluate on trees and subtrees that are mapped by propositions about the equation and its parts. 
         */
        public function setEquationText(root:ExpressionNode):void
        {
            // Search through every regex for a match
            var resultingText:String;
            var i:int;
            var wildCardId:String;
            var wildCardToValueMap:Dictionary = new Dictionary();
            resultingText = getStringFromSubtree(root);
            
            m_equationToTextWidget.setText(resultingText, root);
        }
        
        private function getStringFromSubtree(root:ExpressionNode):String
        {
            const stringBuffer:Array = new Array();
            buildDefaultString(stringBuffer, root);
            
            var i:int;
            var resultingText:String = "";
            for (i = 0; i < stringBuffer.length; i++)
            {
                resultingText += stringBuffer[i] + " ";
            }
            
            return resultingText;
        }
        
        
        /**
         * Get whether a given expression subtree matches a regex format subtree
         * Note that this comparison automatically uses communativity.
         * 
         * Wild cards are place holder values that can match with multiple values. As the function
         * runs we will need to bind the wildcards to the values they match in the other tree.
         * 
         * @param outRegexIdToNodeMap
         *      Output object will contain a mapping from the data value of the regex node
         *      the actual expression node object that it binds to. This only gets filled
         *      if the regex node has a dynamic value (i.e. it is some wildcard)
         * @return
         *      True if the given trees are structurally identical
         */
        public function getExpressionMatchesRegex(regexNode:ExpressionNode, 
                                                  expressionNode:ExpressionNode,
                                                  vectorSpace:IVectorSpace, 
                                                  outRegexIdToNodeMap:Dictionary):Boolean
        {
            var match:Boolean = false;
            if (regexNode == null && expressionNode == null)
            {
                match = true;
            }
            else if (regexNode != null && expressionNode != null)
            {
                // Attempt to match the data with each other
                // Use a regex matching function
                var doesDataMatch:Boolean;
                var isRegexAWildCard:Boolean = regexNode is WildCardNode;
                var isRegexMatchAny:Boolean = false;
                if (isRegexAWildCard)
                {
                    const wildCardNode:WildCardNode = regexNode as WildCardNode;
                    const wildCardType:String = wildCardNode.wildCardType;
                    if (wildCardType == WildCardNode.TYPE_SUBTREE_ANY)
                    {
                        isRegexMatchAny = true;
                        doesDataMatch = true;
                    }
                    else if (wildCardType == WildCardNode.TYPE_TERMINAL_ANY)
                    {
                        doesDataMatch = expressionNode.isLeaf();
                    }
                    else if (wildCardType == WildCardNode.TYPE_TERMINAL_NUMBER)
                    {
                        doesDataMatch = expressionNode.isLeaf() && ExpressionUtil.isNodeNumeric(expressionNode);
                    }
                    else if (wildCardType == WildCardNode.TYPE_TERMINAL_VARIABLE)
                    {
                        doesDataMatch = expressionNode.isLeaf() && !ExpressionUtil.isNodeNumeric(expressionNode);
                    }
                }
                else
                {
                    doesDataMatch = (regexNode.data == expressionNode.data);
                }
                
                match = doesDataMatch;
                if (doesDataMatch)
                {
                    // If the data matches and the regexNode is not a concrete value we dynamically
                    // bind its value to that of the expression subtree
                    if (isRegexAWildCard)
                    {
                        outRegexIdToNodeMap[regexNode.data] = expressionNode;
                    }
                    
                    // We now check children nodes with on exception. If the regex had a wildcard
                    // that allowed a match for any subtree we can quit immediately since we don't care
                    // about the contents further down
                    if (!isRegexMatchAny)
                    {
                        // If the node is communative then ordering at which we check further nodes is not
                        // important.
                        const isAddition:Boolean = expressionNode.isSpecificOperator(vectorSpace.getAdditionOperator());
                        const isMultiplication:Boolean = expressionNode.isSpecificOperator(vectorSpace.getMultiplicationOperator());
                        const isEquality:Boolean = expressionNode.isSpecificOperator(vectorSpace.getEqualityOperator());
                        if (isAddition || isMultiplication || isEquality)
                        {
                            const operatorType:String = regexNode.data;
                            var regexNodeGroups:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
                            ExpressionUtil.getCommutativeGroupRoots(regexNode, operatorType, regexNodeGroups);
                            var expressionNodeGroups:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
                            ExpressionUtil.getCommutativeGroupRoots(expressionNode, operatorType, expressionNodeGroups);
                            
                            match = this.getExpressionSetMatchesRegexSet(regexNodeGroups, expressionNodeGroups, vectorSpace, outRegexIdToNodeMap);
                        }
                        else
                        {
                            const leftSidesMatch:Boolean = this.getExpressionMatchesRegex(
                                regexNode.left, 
                                expressionNode.left, 
                                vectorSpace, 
                                outRegexIdToNodeMap);
                            const rightSidesMatch:Boolean = this.getExpressionMatchesRegex(
                                regexNode.right, 
                                expressionNode.right,
                                vectorSpace, 
                                outRegexIdToNodeMap);
                            match = leftSidesMatch && rightSidesMatch;
                        }
                    }
                }
            }
            return match;
        }
        
        /**
         * Get whether a set of expression nodes matches a set of nodes representing a regex
         * 
         * The key difference occurs when wildcards are present is that the sets do not
         * need to be of equal length since the match any wild card can basically consume
         * several nodes at once
         * 
         * Any we need to first apply a sort on wildcard and make sure the most specific
         * ones get applied first to prevent the case where the more generic ones consume
         * a value that prevents a more specific one from using it.
         * 
         * If the match any wildcard consumes multiple nodes we return a list of nodes
         * in the output dictionary. A match any must consume at least one node.
         */
        public function getExpressionSetMatchesRegexSet(regexSet:Vector.<ExpressionNode>, 
                                                        expressionSet:Vector.<ExpressionNode>,
                                                        vectorSpace:IVectorSpace,
                                                        outRegexIdToNodeMap:Dictionary):Boolean
        {
            // Do an insertion sort on the regex set based on priority
            var i:int;
            var currentNode:ExpressionNode;
            var prevNode:ExpressionNode;
            var holeIndex:int;
            const numRegexElements:int = regexSet.length;
            for (i = 1; i < numRegexElements; i++)
            {
                prevNode = regexSet[i - 1];
                currentNode = regexSet[i];
                holeIndex = i;
                
                // If current is higher priority than previous, then keep shifting
                // the previous over until we find the proper index
                const currentPriorityValue:int = WildCardNode.getTypePriority(currentNode);
                var prevPriorityValue:int = WildCardNode.getTypePriority(prevNode);
                while (holeIndex > 0 && currentPriorityValue > prevPriorityValue)
                {
                    regexSet[holeIndex] = prevNode;
                    holeIndex--;
                    
                    const nextHoleIndex:int = holeIndex - 1;
                    if (nextHoleIndex > -1)
                    {
                        prevNode = regexSet[nextHoleIndex];
                        prevPriorityValue = WildCardNode.getTypePriority(prevNode);
                    }
                }
                
                regexSet[holeIndex] = currentNode;
            }
            
            // Do a brute force sweep of matching subtrees after sorting
            const numExpressionElements:int = expressionSet.length;
            const consumedIndices:Map = new Map();
            var expressionRoot:ExpressionNode;
            var j:int = 0;
            for (i = 0; i < numRegexElements; i++)
            {
                const regexRoot:ExpressionNode = regexSet[i];
                var itemMatched:Boolean = false;
                
                // If we come across a regex that matches any subtree it will attempt to
                // gather as many nodes as possible. Note that since we sorted already we know that
                // that all remaining regex node are also of type subree match any since that is the
                // lowest priority node possible at this moment
                // Simple method is to equaly distribute as many of the expression nodes
                // into the regex nodes.
                if ((regexRoot is WildCardNode) && (regexRoot as WildCardNode).wildCardType == WildCardNode.TYPE_SUBTREE_ANY)
                {
                    // Gather all remaining regex nodes and remaining expression node
                    var currentRegexCounter:int = i;
                    const numberRegexElementsRemaining:int = numRegexElements - i;
                    const numberExpressionElementsRemaining:int = numExpressionElements - consumedIndices.size();
                    
                    if (numberRegexElementsRemaining >= numberExpressionElementsRemaining)
                    {
                        // Loop through each expression element and keep a counter of the current regex it should be assigned to
                        // The regex counter should loop back to the start eventually
                        for (j = 0; j < numExpressionElements; j++)
                        {
                            const regexToBindToValue:WildCardNode = regexSet[currentRegexCounter] as WildCardNode;
                            expressionRoot = expressionSet[j];
                            if (consumedIndices.get(j) == null)
                            {
                                consumedIndices.put(j, true);
                                if (outRegexIdToNodeMap.hasOwnProperty(regexToBindToValue.wildCardId))
                                {
                                    (outRegexIdToNodeMap[regexToBindToValue.wildCardId] as Vector.<ExpressionNode>).push(expressionRoot);
                                }
                                else
                                {
                                    outRegexIdToNodeMap[regexToBindToValue.data] = Vector.<ExpressionNode>([expressionRoot]);
                                }
                                
                                currentRegexCounter++;
                                if (currentRegexCounter >= numRegexElements)
                                {
                                    currentRegexCounter = i;
                                }
                            }
                        }
                    }
                }
                else
                {
                    for (j = 0; j < numExpressionElements; j++)
                    {
                        expressionRoot = expressionSet[j];
                        
                        // We want to prevent duplicate checking of items. Once an item in setB
                        // has been matched with an item in setA both need to removed from any
                        // further comparisons.
                        if (consumedIndices.get(j) == null)
                        {
                            if (this.getExpressionMatchesRegex(regexRoot, expressionRoot, vectorSpace, outRegexIdToNodeMap))
                            {
                                itemMatched = true;
                                consumedIndices.put(j, true);
                                break;
                            }
                        }
                    }
                }
                
                // If no subtree in setB was able to match with an item in setA we can
                // fail immediately
                if (!itemMatched)
                {
                    break;
                }
            }
            
            const setsIdentical:Boolean = (consumedIndices.size() == numRegexElements)
            return setsIdentical;
        }
        
        private function buildDefaultString(buffer:Array, root:ExpressionNode):void
        {
            if (root != null)
            {
                if (root.isLeaf())
                {
                    var symbolName:String = m_symbolMap.getSymbolName(root.data);
                    if (symbolName == null)
                    {
                        symbolName = root.data;
                    }
                    buffer.push(symbolName);
                }
                else
                {
                    buildDefaultString(buffer, root.left);
                    
                    const operatorName:String = root.data;
                    if (operatorName == m_vectorSpace.getAdditionOperator())
                    {
                        buffer.push("plus");
                    }
                    else if (operatorName == m_vectorSpace.getSubtractionOperator())
                    {
                        buffer.push("minus");
                    }
                    else if (operatorName == m_vectorSpace.getMultiplicationOperator())
                    {
                        buffer.push("multiplied by");
                    }
                    else if (operatorName == m_vectorSpace.getEqualityOperator())
                    {
                        buffer.push("is equal to");
                    }
                    else if (operatorName == m_vectorSpace.getDivisionOperator())
                    {
                        buffer.push("divided by");
                    }
                    
                    buildDefaultString(buffer, root.right);
                }
            }
        }
    }
}