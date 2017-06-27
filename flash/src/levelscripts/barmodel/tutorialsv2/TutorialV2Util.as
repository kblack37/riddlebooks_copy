package levelscripts.barmodel.tutorialsv2
{
    import flash.geom.Rectangle;
    
    import cgs.overworld.core.engine.avatar.AvatarColors;
    import cgs.overworld.core.engine.avatar.body.AvatarAnimations;
    import cgs.overworld.core.engine.avatar.body.AvatarExpressions;
    import cgs.overworld.core.engine.avatar.data.AvatarSpeciesData;
    
    import dragonbox.common.util.TextToNumber;
    
    import starling.display.Image;
    
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.constants.Direction;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.level.util.AvatarControl;
    import wordproblem.scripts.level.util.TextReplacementControl;

    /**
     * Set of common functions used by multiple level scripts in the revised bar model tutorials
     */
    public class TutorialV2Util
    {
        /*
        Default Settings for the player's avatar
        */
        public static const DEFAULT_CHARACTER_SPECIES:int = AvatarSpeciesData.MAMMAL;
        public static const DEFAULT_CHARACTER_EAR_ID:int = 6;
        
        public static const GENDER_MALE:String = "m";
        public static const GENDER_FEMALE:String = "f";
        public static const JOB_ZOMBIE:String = "zombie";
        public static const JOB_SUPERHERO:String = "superhero";
        public static const JOB_FAIRY:String = "fairy";
        public static const JOB_BASKETBALL_PLAYER:String = "basketball";
        public static const JOB_NINJA:String = "ninja";
        public static const JOBS:Array = [TutorialV2Util.JOB_BASKETBALL_PLAYER, TutorialV2Util.JOB_FAIRY, TutorialV2Util.JOB_NINJA, TutorialV2Util.JOB_SUPERHERO, TutorialV2Util.JOB_ZOMBIE];
        
        public static const m_colorValueToAvatarColor:Object = {
            red:AvatarColors.RED,
            orange:AvatarColors.ORANGE,
            yellow:AvatarColors.YELLOW,
            green:AvatarColors.DARK_GREEN,
            blue:AvatarColors.DARK_BLUE,
            purple:AvatarColors.PURPLE,
            start:AvatarColors.WHITE
        };
        
        public static function addSimpleSumReferenceForModel(validation:ValidateBarModelArea, values:Vector.<int>, bracketValue:String):void
        {
            var referenceBarModels:Vector.<BarModelData> = new Vector.<BarModelData>();
            var correctModel:BarModelData = new BarModelData();
            var correctBarWhole:BarWhole = new BarWhole(true);
            for (var i:int = 0; i < values.length; i++)
            {
                var value:int = values[i];
                correctBarWhole.barSegments.push(new BarSegment(value, 1, 0xFFFFFFFF, null));
                correctBarWhole.barLabels.push(new BarLabel(value + "", i, i, true, false, BarLabel.BRACKET_NONE, null));
            }
            
            if (bracketValue != null)
            {
                correctBarWhole.barLabels.push(new BarLabel(bracketValue, 0, correctBarWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
            }
            correctModel.barWholes.push(correctBarWhole);
            referenceBarModels.push(correctModel);
            
            validation.setReferenceModels(referenceBarModels);
        }
        
        /**
         * The content of several tutorial problems will differ depending on the 'job' a user has
         * picked for his/her character. This function prunes content that do not belong to a selected job.
         */
        public static function clipElementsNotBelongingToJob(selectedPlayerJob:String, 
                                                             textReplacementControl:TextReplacementControl, 
                                                             pageIndex:int):void
        {
            var jobNamesToRemove:Vector.<String> = new Vector.<String>();
            var emptyReplacementContent:Vector.<XML> = new Vector.<XML>();
            var possibleCharacterJobs:Array = TutorialV2Util.JOBS;
            for each (var jobName:String in possibleCharacterJobs)
            {
                if (jobName != selectedPlayerJob)
                {
                    jobNamesToRemove.push(jobName);
                    emptyReplacementContent.push(<p></p>);
                }
            }
            textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(jobNamesToRemove, emptyReplacementContent, pageIndex);
        }
        
        public static function getNumberValueFromDocId(documentId:String, textArea:TextAreaWidget, pageIndex:int=-1):String
        {
            var value:String = null;
            var documentViews:Vector.<DocumentView> = textArea.getDocumentViewsAtPageIndexById(documentId, null, pageIndex);
            if (documentViews.length > 0)
            {
                var textContent:String = documentViews[0].node.getText();
                var textToNumber:TextToNumber = new TextToNumber();
                value = textToNumber.textToNumber(textContent).toString();
            }
            return value;
        }
        
        public static function createAvatarFromChoices(gender:String, 
                                                       color:String,
                                                       job:String,
                                                       useJobSpecificHat:Boolean,
                                                       avatarControl:AvatarControl):Image
        {
            // From the various set of player choices made at the start of a level,
            // create an avatar image.
            // Grab the placeholder for the avatar and inject a blank character
            var avatarColor:int = TutorialV2Util.m_colorValueToAvatarColor[color];
            
            // Have different parts depending job and gender
            var hatId:int = 0;
            if (gender == TutorialV2Util.GENDER_MALE)
            {
                hatId = avatarControl.headItemIds.defaultMaleHair;
            }
            else if (gender == TutorialV2Util.GENDER_FEMALE)
            {
                hatId = avatarControl.headItemIds.defaultFemaleHair;
            }
            
            var shirtId:int = 0;
            if (job == TutorialV2Util.JOB_BASKETBALL_PLAYER)
            {
                if (gender == TutorialV2Util.GENDER_MALE)
                {
                    shirtId = avatarControl.shirtItemIds.jerseyGreen;
                }
                else if (gender == TutorialV2Util.GENDER_FEMALE)
                {
                    shirtId = avatarControl.shirtItemIds.jerseyBlue;
                }
            }
            else if (job == TutorialV2Util.JOB_FAIRY)
            {
                if (gender == TutorialV2Util.GENDER_MALE)
                {
                    shirtId = avatarControl.shirtItemIds.butterflyBlue;
                }
                else if (gender == TutorialV2Util.GENDER_FEMALE)
                {
                    shirtId = avatarControl.shirtItemIds.butterflyBlue;
                }
            }
            else if (job == TutorialV2Util.JOB_NINJA)
            {
                if (gender == TutorialV2Util.GENDER_MALE)
                {
                    shirtId = avatarControl.shirtItemIds.ninjaSashWhite;
                }
                else if (gender == TutorialV2Util.GENDER_FEMALE)
                {
                    shirtId = avatarControl.shirtItemIds.ninjaSashBlack;
                }
            }
            else if (job == TutorialV2Util.JOB_SUPERHERO)
            {
                if (gender == TutorialV2Util.GENDER_MALE)
                {
                    shirtId = avatarControl.shirtItemIds.superSuitGreen;
                }
                else if (gender == TutorialV2Util.GENDER_FEMALE)
                {
                    shirtId = avatarControl.shirtItemIds.superSuitRed;
                }
            }
            else if (job == TutorialV2Util.JOB_ZOMBIE)
            {
                hatId = avatarControl.headItemIds.zombieHead;
                shirtId = avatarControl.shirtItemIds.zombieShirt;
            }
            
            var avatar:Image = avatarControl.createAvatarImage(
                TutorialV2Util.DEFAULT_CHARACTER_SPECIES, 
                TutorialV2Util.DEFAULT_CHARACTER_EAR_ID, 
                avatarColor, hatId, shirtId, 
                AvatarExpressions.NEUTRAL, 
                AvatarAnimations.IDLE, 0, 200, 
                new Rectangle(-10, 185, 145, 205),
                Direction.SOUTH
            );
            return avatar;
        }
    }
}