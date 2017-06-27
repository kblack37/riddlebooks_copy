package wordproblem.creator
{
    public class ProblemCreateData
    {
        /**
         * Each highlighted part of the text needs to map to an alias name that
         * the application uses to create the mathematical model for a level.
         * (Namely the correct reference bar model and equation)
         * In most, but not all, cases the alias should be a number. The unknown
         * variable is one instant where it is usually not.
         * 
         * TODO: the user can type spaces in the alias, which are ignored
         * when parsing the expression. The name and expression value thus need to be kept
         * separate (just remove the spaces when 
         * 
         * External scripts should populate this
         * Have a mapping from an id in a bar model template to another data block of all user data
         * when they set configurations for that id.
         * The value is another object
         * {
         *      value:<String value>,
         *      highlighted:<true/false>
         * }
         */
        public var elementIdToDataMap:Object;
        
        /**
         * The currently selected background and style information
         */
        public var currentlySelectedBackgroundData:Object;
        
        private var m_barModelType:String;
        
        private var m_prepopulatedTextBlocks:Vector.<XML>;
        
        /**
         * This is the mapping from the id name of each part to a vector of string ids
         * assigned each bar model element
         */
        private var m_partNamesToIdsForCurrentModel:Object;
        
        public function ProblemCreateData()
        {
            this.elementIdToDataMap = {};
            m_prepopulatedTextBlocks = new Vector.<XML>();
        }
        
        public function get barModelType():String
        {
            return m_barModelType;
        }
        
        /**
         * Get back a list of xml elements representing the text content that should be displayed
         * at the start. (useful for scaffolded levels so the user only needs to finish a partially completed
         * part of the problem)
         */
        public function getPrepopulatedTextBlocks():Vector.<XML>
        {
            return m_prepopulatedTextBlocks;
        }
        
        public function setPartNameToIdsMap(value:Object):void
        {
            m_partNamesToIdsForCurrentModel = value;
        }
        
        public function getPartNameToIdsMap():Object
        {
            // TODO: The current model may be redrawn several times, whenever a redraw occurs this mapping needs to updated
            // The game state seems like the incorrect place to hold this information
            return m_partNamesToIdsForCurrentModel;
        }
        
        /**
         * Parse the xml representation of the problem
         * (What are all the fields)
         */
        public function parseFromXml(levelConfig:XML):void
        {
            var barModelType:String = levelConfig.@barModelType;
            m_barModelType = barModelType;
            
            // If the wordproblem tag is present, it means there is content that should pre-populate the text area
            var prepopulatedTextElement:XML = levelConfig.elements("wordproblem")[0];
            if (prepopulatedTextElement != null)
            {
                // Get all of the paragraph elements (these will represent the text blocks)
                var paragraphElements:XMLList = prepopulatedTextElement.elements("p");
                var i:int;
                var numParagraphs:int = paragraphElements.length();
                for (i = 0; i < numParagraphs; i++)
                {
                    m_prepopulatedTextBlocks.push(paragraphElements[i]);
                }
            }
        }
    }
}