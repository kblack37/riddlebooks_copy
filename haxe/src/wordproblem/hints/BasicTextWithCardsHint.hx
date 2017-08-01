package wordproblem.hints;


import starling.display.DisplayObject;

import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.resource.AssetManager;

/**
 * This hint type is a minor extension of the text hint.
 * 
 * There are locations in the content in which we add new xml tags representing images
 * of cards for a problem. This can only be done after the level data has been read in
 * and we know the exact value of those cards.
 * 
 * This hint relies on a specific pattern in the generated levels where tagged document ids in main level
 * content are labeled unk, a1, b1, a2, etc. Using these mappings we can identify the actual term values
 * specific to the level being played.
 */
class BasicTextWithCardsHint extends BasicTextAndCharacterHint
{
    private var m_descriptionIdToMainDocumentId : Dynamic;
    
    /**
     * Only perform the modification to the xml once on the first draw
     */
    private var m_descriptionXmlModified : Bool;
    
    /**
     *
     * @param descriptionIdToMainDocumentId
     *      This is a mapping from a xml id to a document id in the main text body of the problem.
     *      This is critical to identify the card as the document id has an implicit connection
     *      to a single expression value.
     */
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager,
            characterController : HelperCharacterController,
            textParser : TextParser,
            textViewFactory : TextViewFactory,
            descriptionText : FastXML,
            characterText : FastXML,
            descriptionIdToMainDocumentId : Dynamic,
            descriptionStyle : Dynamic = null,
            characterStyle : Dynamic = null,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, assetManager, characterController, textParser, textViewFactory, descriptionText, characterText, descriptionStyle, characterStyle, false, id, isActive);
        
        m_descriptionIdToMainDocumentId = descriptionIdToMainDocumentId;
        m_descriptionXmlModified = false;
    }
    
    override public function getDescription(width : Float, height : Float) : DisplayObject
    {
        // Replace the description contents in the xml, only need to do this once
        if (!m_descriptionXmlModified) 
        {
            m_descriptionXmlModified = true;
            
            // The xml for hints are shared across level, we apply modification to clones of the xml
            // so changes do not persist across levels.
            m_descriptionOriginalContent = m_descriptionOriginalContent.node.copy.innerData();
            
            // The term values available in the level can be found by seeing what parts of the text are mapped directly
            // to an expression value
            var documentIdInMainTextToTermValue : Dynamic = { };
            var textAreaWidget : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
            var expressionComponents : Array<Component> = textAreaWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            var i : Int = 0;
            for (i in 0...expressionComponents.length){
                var expressionComponent : ExpressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
                documentIdInMainTextToTermValue[expressionComponent.entityId] = expressionComponent.expressionString;
            }  // At that element add a new child element    // Go through the xml and find specific tags with a matching id  
            
            
            
            
            
            for (descriptionId in Reflect.fields(m_descriptionIdToMainDocumentId))
            {
                var element : FastXML = _getElementWithId(m_descriptionOriginalContent, descriptionId);
                if (element != null) 
                {
                    // Modify the original description appending a new child that is a picture of the card
                    var newCardImageXML : FastXML = FastXML.parse("<img height=\"32\"/>");
                    var termValue : String = Reflect.field(documentIdInMainTextToTermValue, Std.string(Reflect.field(m_descriptionIdToMainDocumentId, descriptionId)));
                    newCardImageXML.setAttribute("src", "symbol(" + termValue + ")") = "symbol(" + termValue + ")";
                    element.node.appendChild.innerData(newCardImageXML);
                }
            }
        }
        
        return super.getDescription(width, height);
    }
    
    private function _getElementWithId(content : FastXML, id : String) : FastXML
    {
        var element : FastXML = null;
        if (content.node.exists.innerData("@id") && content.att.id == id) 
        {
            element = content;
        }
        else 
        {
            var childElements : FastXMLList = content.node.children.innerData();
            var i : Int = 0;
            var numChildren : Int = childElements.length();
            for (i in 0...numChildren){
                element = _getElementWithId(childElements.get(i), id);
                if (element != null) 
                {
                    break;
                }
            }
        }
        
        return element;
    }
}
