package wordproblem.scripts.equationtotext;


import dragonbox.common.math.vectorspace.RealsVectorSpace;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.WildCardNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.vectorspace.IVectorSpace;

import starling.display.DisplayObject;
import wordproblem.resource.AssetManager;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.widget.EquationToTextWidget;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.scripts.BaseGameScript;

class EquationToText extends BaseGameScript
{
    private var m_termAreas : Array<TermAreaWidget>;
    private var m_equationToTextWidget : EquationToTextWidget;
    private var m_regexRoots : Array<ExpressionNode>;
    private var m_templateList : Array<String>;
    private var m_vectorSpace : RealsVectorSpace;
    private var m_symbolMap : ExpressionSymbolMap;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        var currentLevel : WordProblemLevelData = m_gameEngine.getCurrentLevel();
        
        var termAreaDisplays : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
        m_termAreas = new Array<TermAreaWidget>();
        for (termAreaDisplay in termAreaDisplays)
        {
            m_termAreas.push(try cast(termAreaDisplay, TermAreaWidget) catch(e:Dynamic) null);
        }
        
        m_equationToTextWidget = try cast(m_gameEngine.getUiEntity("equationToText"), EquationToTextWidget) catch(e:Dynamic) null;
        m_vectorSpace = m_expressionCompiler.getVectorSpace();
        m_symbolMap = m_gameEngine.getExpressionSymbolResources();
        
        var regexList : Array<String> = new Array<String>();  //currentLevel.getEquationTextRegexList();  
        var regexRoots : Array<ExpressionNode> = new Array<ExpressionNode>();
        for (i in 0...regexList.length){
            var regexRoot : ExpressionNode = m_expressionCompiler.compile(regexList[i]);
            regexRoots.push(regexRoot);
        }
        
        m_regexRoots = regexRoots;
        m_templateList = new Array<String>();  //currentLevel.getEquationTextTemplateList();  
        
        setIsActive(m_isActive);
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            var i : Int = 0;
            var termArea : TermAreaWidget = null;
            for (i in 0...m_termAreas.length){
                termArea = m_termAreas[i];
                termArea.removeEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
                termArea.removeEventListener(GameEvent.TERM_AREA_RESET, onTermAreaReset);
            }
            
            if (value) 
            {
                for (i in 0...m_termAreas.length){
                    termArea = m_termAreas[i];
                    termArea.addEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
                    termArea.addEventListener(GameEvent.TERM_AREA_RESET, onTermAreaReset);
                }
            }
        }
    }
    
    private function onTermAreaChanged() : Void
    {
        var i : Int = 0;
        var termAreasReady : Bool = true;
        for (i in 0...m_termAreas.length){
            if (!m_termAreas[i].isReady) 
            {
                termAreasReady = false;
                break;
            }
        }
        
        if (termAreasReady) 
        {
            var subtrees : Array<ExpressionNode> = new Array<ExpressionNode>();
            for (termArea in m_termAreas)
            {
                if (termArea.getWidgetRoot() != null) 
                {
                    subtrees.push(termArea.getWidgetRoot().getNode());
                }
            }
            
            var root : ExpressionNode = ExpressionUtil.compressToSingleTree(subtrees, m_vectorSpace);
            this.setEquationText(root);
        }
    }
    
    private function onTermAreaReset() : Void
    {
        var subtrees : Array<ExpressionNode> = new Array<ExpressionNode>();
        for (termArea in m_termAreas)
        {
            if (termArea.getWidgetRoot() != null) 
            {
                subtrees.push(termArea.getWidgetRoot().getNode());
            }
        }
        
        var root : ExpressionNode = ExpressionUtil.compressToSingleTree(subtrees, m_vectorSpace);
        this.setEquationText(root);
    }
    
    public function setEquation(root : ExpressionNode) : Void
    {
        // Search through every regex for a match
        var resultingText : String = null;
        var regexMatched : Bool = false;
        var i : Int = 0;
        var wildCardId : String = null;
        var wildCardToValueMap : Map<String, ExpressionNode> = new Map();
        var numRegexElements : Int = m_regexRoots.length;
        for (i in 0...numRegexElements){
            var regexElement : ExpressionNode = m_regexRoots[i];
            
            regexMatched = getExpressionMatchesRegex(regexElement, root, m_vectorSpace, wildCardToValueMap);
            if (regexMatched) 
            {
                break;
            }
            else 
            {                
				// Clean out the map for the next search
				wildCardToValueMap = new Map();
            }
        }
        
        if (regexMatched) 
        {
            // The index will give the proper textual template to display to the player.
            resultingText = m_templateList[i];
            
            // If the template has wild card values to fill, we pull the values from the dictionary
            // and use those to replace the spots in the string.
            for (wildCardId in Reflect.fields(wildCardToValueMap))
            {
                if (Std.is(Reflect.field(wildCardToValueMap, wildCardId), ExpressionNode)) 
                {
                    // If the matched node is a leaf, just pull its data directly, otherwise we need
                    // to build the tree using the default wordings
                    var expressionNode : ExpressionNode = Reflect.field(wildCardToValueMap, wildCardId);
                    
                    var replacementText : String = null;
                    if (expressionNode.isLeaf()) 
                    {
                        replacementText = m_symbolMap.getSymbolName(expressionNode.data);
                    }
                    else 
                    {
                        replacementText = getStringFromSubtree(root);
                    }
                    
                    resultingText = StringTools.replace(resultingText, wildCardId, replacementText);
                }
                // TODO:
                // If its not a node then it is a list of expression nodes with a common operator
                // The main task is to compress the nodes as small as possible
                else 
                {
                    var expressionNodes : Array<ExpressionNode> = Reflect.field(wildCardToValueMap, wildCardId);
                    if (expressionNodes.length == 1) {  //the wild card can be replaced by evaluating a simple expression  
                        resultingText = StringTools.replace(resultingText, wildCardId, Std.string(expressionNodes[0]));
                    }
                    else {  // TODO: The more complex case  
                        resultingText = StringTools.replace(resultingText, wildCardId, "48");
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
    public function setEquationText(root : ExpressionNode) : Void
    {
        // Search through every regex for a match
        var resultingText : String = null;
        resultingText = getStringFromSubtree(root);
        
        m_equationToTextWidget.setText(resultingText, root);
    }
    
    private function getStringFromSubtree(root : ExpressionNode) : String
    {
        var stringBuffer : Array<Dynamic> = new Array<Dynamic>();
        buildDefaultString(stringBuffer, root);
        
        var i : Int = 0;
        var resultingText : String = "";
        for (i in 0...stringBuffer.length){
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
    public function getExpressionMatchesRegex(regexNode : ExpressionNode,
            expressionNode : ExpressionNode,
            vectorSpace : RealsVectorSpace,
            outRegexIdToNodeMap : Map<String, ExpressionNode>) : Bool
    {
        var match : Bool = false;
        if (regexNode == null && expressionNode == null) 
        {
            match = true;
        }
        else if (regexNode != null && expressionNode != null) 
        {
            // Attempt to match the data with each other
            // Use a regex matching function
            var doesDataMatch : Bool = false;
            var isRegexAWildCard : Bool = Std.is(regexNode, WildCardNode);
            var isRegexMatchAny : Bool = false;
            if (isRegexAWildCard) 
            {
                var wildCardNode : WildCardNode = try cast(regexNode, WildCardNode) catch(e:Dynamic) null;
                var wildCardType : String = wildCardNode.wildCardType;
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
                }  // about the contents further down    // that allowed a match for any subtree we can quit immediately since we don't care    // We now check children nodes with on exception. If the regex had a wildcard  
                
                
                
                
                
                
                
                if (!isRegexMatchAny) 
                {
                    // If the node is communative then ordering at which we check further nodes is not
                    // important.
                    var isAddition : Bool = expressionNode.isSpecificOperator(vectorSpace.getAdditionOperator());
                    var isMultiplication : Bool = expressionNode.isSpecificOperator(vectorSpace.getMultiplicationOperator());
                    var isEquality : Bool = expressionNode.isSpecificOperator(vectorSpace.getEqualityOperator());
                    if (isAddition || isMultiplication || isEquality) 
                    {
                        var operatorType : String = regexNode.data;
                        var regexNodeGroups : Array<ExpressionNode> = new Array<ExpressionNode>();
                        ExpressionUtil.getCommutativeGroupRoots(regexNode, operatorType, regexNodeGroups);
                        var expressionNodeGroups : Array<ExpressionNode> = new Array<ExpressionNode>();
                        ExpressionUtil.getCommutativeGroupRoots(expressionNode, operatorType, expressionNodeGroups);
                        
                        match = this.getExpressionSetMatchesRegexSet(regexNodeGroups, expressionNodeGroups, vectorSpace, outRegexIdToNodeMap);
                    }
                    else 
                    {
                        var leftSidesMatch : Bool = this.getExpressionMatchesRegex(
                                regexNode.left,
                                expressionNode.left,
                                vectorSpace,
                                outRegexIdToNodeMap);
                        var rightSidesMatch : Bool = this.getExpressionMatchesRegex(
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
    public function getExpressionSetMatchesRegexSet(regexSet : Array<ExpressionNode>,
            expressionSet : Array<ExpressionNode>,
            vectorSpace : RealsVectorSpace,
            outRegexIdToNodeMap : Map<String, ExpressionNode>) : Bool
    {
        // Do an insertion sort on the regex set based on priority
        var i : Int = 0;
        var currentNode : ExpressionNode = null;
        var prevNode : ExpressionNode = null;
        var holeIndex : Int = 0;
        var numRegexElements : Int = regexSet.length;
        for (i in 1...numRegexElements){
            prevNode = regexSet[i - 1];
            currentNode = regexSet[i];
            holeIndex = i;
            
            // If current is higher priority than previous, then keep shifting
            // the previous over until we find the proper index
            var currentPriorityValue : Int = WildCardNode.getTypePriority(currentNode);
            var prevPriorityValue : Int = WildCardNode.getTypePriority(prevNode);
            while (holeIndex > 0 && currentPriorityValue > prevPriorityValue)
            {
                regexSet[holeIndex] = prevNode;
                holeIndex--;
                
                var nextHoleIndex : Int = holeIndex - 1;
                if (nextHoleIndex > -1) 
                {
                    prevNode = regexSet[nextHoleIndex];
                    prevPriorityValue = WildCardNode.getTypePriority(prevNode);
                }
            }
            
            regexSet[holeIndex] = currentNode;
        }  // Do a brute force sweep of matching subtrees after sorting  
        
        
        
        var numExpressionElements : Int = expressionSet.length;
        var consumedIndices : Map<Int, Bool> = new Map();
        var expressionRoot : ExpressionNode = null;
        var j : Int = 0;
        for (i in 0...numRegexElements){
            var regexRoot : ExpressionNode = regexSet[i];
            var itemMatched : Bool = false;
            
            // If we come across a regex that matches any subtree it will attempt to
            // gather as many nodes as possible. Note that since we sorted already we know that
            // that all remaining regex node are also of type subree match any since that is the
            // lowest priority node possible at this moment
            // Simple method is to equaly distribute as many of the expression nodes
            // into the regex nodes.
            if ((Std.is(regexRoot, WildCardNode)) && (try cast(regexRoot, WildCardNode) catch(e:Dynamic) null).wildCardType == WildCardNode.TYPE_SUBTREE_ANY) 
            {
                // Gather all remaining regex nodes and remaining expression node
                var currentRegexCounter : Int = i;
                var numberRegexElementsRemaining : Int = numRegexElements - i;
                var numberExpressionElementsRemaining : Int = numExpressionElements - Lambda.count(consumedIndices);
                
                if (numberRegexElementsRemaining >= numberExpressionElementsRemaining) 
                {
                    // Loop through each expression element and keep a counter of the current regex it should be assigned to
                    // The regex counter should loop back to the start eventually
                    for (j in 0...numExpressionElements){
                        var regexToBindToValue : WildCardNode = try cast(regexSet[currentRegexCounter], WildCardNode) catch(e:Dynamic) null;
                        expressionRoot = expressionSet[j];
                        if (consumedIndices.get(j) == null) 
                        {
                            consumedIndices.set(j, true);
                            if (outRegexIdToNodeMap.exists(regexToBindToValue.wildCardId)) 
                            {
                                (try cast(outRegexIdToNodeMap[regexToBindToValue.wildCardId], Array<Dynamic>) catch(e:Dynamic) null).push(expressionRoot);
                            }
                            else 
                            {
								Reflect.setField(outRegexIdToNodeMap, regexToBindToValue.data, [expressionRoot]);
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
                for (j in 0...numExpressionElements){
                    expressionRoot = expressionSet[j];
                    
                    // We want to prevent duplicate checking of items. Once an item in setB
                    // has been matched with an item in setA both need to removed from any
                    // further comparisons.
                    if (consumedIndices.get(j) == null) 
                    {
                        if (this.getExpressionMatchesRegex(regexRoot, expressionRoot, vectorSpace, outRegexIdToNodeMap)) 
                        {
                            itemMatched = true;
                            consumedIndices.set(j, true);
                            break;
                        }
                    }
                }
            }  // fail immediately    // If no subtree in setB was able to match with an item in setA we can  
            
            
            
            
            
            if (!itemMatched) 
            {
                break;
            }
        }
        
        var setsIdentical : Bool = (Lambda.count(consumedIndices) == numRegexElements);
        return setsIdentical;
    }
    
    private function buildDefaultString(buffer : Array<Dynamic>, root : ExpressionNode) : Void
    {
        if (root != null) 
        {
            if (root.isLeaf()) 
            {
                var symbolName : String = m_symbolMap.getSymbolName(root.data);
                if (symbolName == null) 
                {
                    symbolName = root.data;
                }
                buffer.push(symbolName);
            }
            else 
            {
                buildDefaultString(buffer, root.left);
                
                var operatorName : String = root.data;
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
