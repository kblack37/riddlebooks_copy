package wordproblem.engine.widget
{
    import flash.geom.Rectangle;
    
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.textures.Texture;
    
    import wordproblem.engine.animation.CardShiftAnimation;
    import wordproblem.engine.animation.ColorChangeAnimation;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.tree.ExpressionTree;
    import wordproblem.engine.expression.widget.ExpressionTreeWidget;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.resource.AssetManager;
    
    /**
     * It is important to note that any ui related operations like determining a drag
     * is actually a simplify should be handled by systems. For example the modeling system
     * determines that dragging a card is removing it from the expression.
     */
    public class TermAreaWidget extends ExpressionTreeWidget implements IBaseWidget
    {
        /**
         * Keep track of the number of cards (which we interpret as the number of
         * leaves in the expression) allowed at any moment.
         * 
         * Used primarily for tutorials that only allow for one card to be placed on one side and to prevent
         * the player from crashing the game with an infinite number of pieces on one side.
         * 
         * If less than zero, no limit is placed.
         * (Not placed in AddTermScript because different widgets might have different settings)
         */
        public var maxCardAllowed:int = 12;
        
        /**
         * This contains the expression values that are acceptable in this termarea.
         */
        public var restrictedValues:Vector.<String>;
        
        /**
         * If true, should use the restricted value list to determine which expression cards are
         * allowed to be added to this widget.
         */
        public var restrictValues:Boolean;
        
        /**
         * Keep track of dynamic data properties for objects within the set of term areas.
         * 
         * The entity id of something in the term area is the id of an expression node represented
         * in one of the term areas.
         */
        private var m_componentManager:ComponentManager;
        
        /**
         * Flag to indicate whether the player can apply manual changes to the
         * contents of this term area.
         */
        private var m_interactable:Boolean;
        
        /**
         * Animation for changing colors of the background
         */
        private var m_colorChangeAnimation:ColorChangeAnimation;
        
        /**
         * A preview that lies on top to show how a change to the expression tree would change the appearance
         */
        private var m_previewExpressionTreeWidget:ExpressionTreeWidget;
        
        /**
         * Flag mainly to indicate that the widget is in the middle of some animation or other
         * change in which its data is in an invalid state.
         */
        private var m_ready:Boolean;
        
        /**
         * Use a scale9 image to prevent background distortion when resizing the term
         * areas
         */
        private var m_bgImage:Scale9Image;
        
        public function TermAreaWidget(tree:ExpressionTree, 
                                       expressionSymbolResources:ExpressionSymbolMap, 
                                       assetManager:AssetManager,
                                       backgroundTexture:Texture,
                                       constraintWidth:Number, 
                                       constraintHeight:Number,
                                       allowConstraintPadding:Boolean=true)
        {
            // Prepare the term area to be able to add dynamic properties
            m_componentManager = new ComponentManager();
            
            // Since set constraints is set in the super constructor we need to initialize the background
            // texture first.
            const imageCenterX:Number = 30;
            const imageCenterY:Number = 20;
            const imageCenterWidth:Number = backgroundTexture.width - imageCenterX * 2;
            const imageCenterHeight:Number = backgroundTexture.height - imageCenterY * 2;
            const bgImage:Scale9Image = new Scale9Image(new Scale9Textures(backgroundTexture, new Rectangle(imageCenterX, imageCenterY, imageCenterWidth, imageCenterHeight)));
            m_bgImage = bgImage;
            
            super(tree, expressionSymbolResources, assetManager, constraintWidth, constraintHeight, allowConstraintPadding);
            
            m_colorChangeAnimation = new ColorChangeAnimation();
            m_interactable = true;
            addChildAt(bgImage, 0);
            m_ready = true;
            
            m_previewExpressionTreeWidget = new ExpressionTreeWidget(
                tree, 
                m_expressionSymbolResources, 
                m_assetManager,
                m_contraintsBox.width, 
                m_contraintsBox.height);
            this.restrictValues = false;
            this.restrictedValues = new Vector.<String>();
        }
        
        public function get componentManager():ComponentManager
        {
            return m_componentManager;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_componentManager.clear();
        }
        
        /**
         * Get whether the preview is current visible (if so the original term widgets are not)
        */
        public function getPreviewShowing():Boolean
        {
            return m_previewExpressionTreeWidget.parent != null;
        }
        
        /**
         * Get back the preview (which is more a way to get the model data of that
         * preview so that various scripts can modify it)
         * 
         * A preview copy of the tree is also necessary for smooth transitions as this
         * tree's state is being modified. This copy shares the exact same backing expression tree.
         * Proper usage is to first update the layout for the preview when the expression tree changes.
         * The preview now has updated positions we can use to transition this widget to the updated state.
         * 
         * @param doCloneData
         *      If true the preview returned should take a snapshot, otherwise it uses the same backing tree
         * @return
         *      The preview view
         */
        public function getPreviewView(doClone:Boolean):ExpressionTreeWidget
        {
            
            if (doClone)
            {
                m_previewExpressionTreeWidget.setTree(this.getTree().clone());
            }
            else
            {
                m_previewExpressionTreeWidget.setTree(this.getTree());
            }
            
            return m_previewExpressionTreeWidget;
        }
        
        /**
         * Show the preview
         * 
         * @param value
         *      True if the preview should be displayed, false if the preview should be hidden and the
         *      regular bar model images should show up.
         */
        public function showPreview(value:Boolean):void
        {
            // Copy properties of this widget to the preview so they line up correctly
            m_previewExpressionTreeWidget.setConstraints(this.getConstraintsWidth(), this.getConstraintsHeight(), super.m_allowConstraintPadding, false);
            
            if (value)
            {
                m_objectLayer.visible = false;
                
                // Must add to display list for rebuild to correctly be applied
                this.addChild(m_previewExpressionTreeWidget);
                m_previewExpressionTreeWidget.refreshNodes(true, true);
                m_previewExpressionTreeWidget.buildTreeWidget();
                if (m_previewExpressionTreeWidget.parent == null)
                {
                    // Add preview on top and hide the current
                    addChild(m_previewExpressionTreeWidget);
                }
            }
            else
            {
                m_objectLayer.visible = true;
                if (m_previewExpressionTreeWidget.parent != null)
                {
                    m_previewExpressionTreeWidget.removeFromParent();
                }
            }
        }
        
        override public function setConstraints(constraintWidth:Number, 
                                                constraintHeight:Number, 
                                                allowConstraintPadding:Boolean, 
                                                rebuildTree:Boolean):void
        {
            super.setConstraints(constraintWidth, constraintHeight, allowConstraintPadding, rebuildTree);
            
            // Need to explicitly reset the width and height to use the scale 9 properties
            m_bgImage.width = constraintWidth;
            m_bgImage.height = constraintHeight;
        }
        
        override public function setTree(tree:ExpressionTree):void
        {
            if (m_tree != null)
            {
                m_tree.removeEventListeners()
            }
            var previousTree:ExpressionTree = m_tree;
            
            super.setTree(tree);
            
            // Do not dispatch reset event if the tree did not change
            var doDispatchReset:Boolean = true;
            if (previousTree == null)
            {
                doDispatchReset = tree.getRoot() != null;
            }
            else
            {
                doDispatchReset = previousTree.getRoot() != tree.getRoot();
            }
            
            if (doDispatchReset)
            {
                this.dispatchEventWith(GameEvent.TERM_AREA_RESET);
            }
        }
        
        /**
         * Resize the term area in an animation.
         */
        public function setConstraintsAnimated(constraintWidth:Number, 
                                               constraintHeight:Number,
                                               newX:Number,
                                               newY:Number,
                                               allowConstraintPadding:Boolean,
                                               duration:Number):void
        {
            // The reason why we do not just apply a scale to the entire
            // term area is that we do not want to necessarily scale the widgets
            // by the same factor.
            // For example, suppose the widgets have a default max size and we expand the
            // size of term area. The widgets should be kept at the same size.
            
            // Set the preview to the new constraints first to find the expected positions of everything
            this.getPreviewView(false);
            this.showPreview(true);
            this.showPreview(false);
            
            // Shift contents of current tree to match the positions in the preview
            var cardShiftComplete:Boolean = false;
            const cardShiftAnimation:CardShiftAnimation = new CardShiftAnimation();
            cardShiftAnimation.play(this, m_previewExpressionTreeWidget, onShiftComplete, duration);
            function onShiftComplete():void
            {
                cardShiftComplete = true;
                checkAnimationComplete();
            }
            
            // While the shifting is occuring also apply a scale to the bg image of the current tree
            var scaleImageComplete:Boolean = false;
            const tween:Tween = new Tween(m_bgImage, duration);
            tween.animate("width", constraintWidth);
            tween.animate("height", constraintHeight);
            tween.onComplete = function():void
            {
                scaleImageComplete = true;
                checkAnimationComplete();
            }
            Starling.juggler.add(tween);
            
            const moveTween:Tween = new Tween(this, duration);
            moveTween.animate("x", newX);
            moveTween.animate("y", newY);
            Starling.juggler.add(moveTween);
            
            // At the end we actaully reset the constraints of the tree
            function checkAnimationComplete():void
            {
                if (cardShiftComplete && scaleImageComplete)
                {
                    setConstraints(constraintWidth, constraintHeight, allowConstraintPadding, true);
                }
            }
        }
        
        /**
         * Used by other classes to detect whether this term area is in a state
         * where its widgets are ready to be interacted with or read.
         * 
         * @return
         *      True if its ok to call functions for this term area. False if the area
         *      is currently in a transient state, like when animations are playing and
         *      parts of the system must wait before using this area.
         */
        public function get isReady():Boolean
        {
           return m_ready; 
        }
        
        /**
         * Allowing outside classes to modify the ready flag because we want to push all the
         * logic that modifies the tree out into scripts RATHER than baked into here.
         * 
         * This shift will help improve modularity, in addition several of these functions are
         * just an extra function call layer without doing anything meaningful
         */
        public function set isReady(value:Boolean):void
        {
            m_ready = value;
        }
        
        /**
         * Get whether this term area has been marked as interactable
         * 
         * @return
         *      False if the user should not be able to make changes to this term area
         */
        public function get isInteractable():Boolean
        {
            return m_interactable;
        }
        
        /**
         * Allow outside scripts to set whether this term area should allow for gestures
         * 
         * @param value
         *      Set to false if the user should not be able to make modifications to the
         *      expression in this component.
         */
        public function set isInteractable(value:Boolean):void
        {
            m_interactable = value;
        }
        
        public function fadeOutBackground(color:uint):void
        {
            // Need to interpolate the color from the given starting value back to its original color
            m_colorChangeAnimation.play(color, 0xFFFFFF, 1.0, m_bgImage);
            Starling.juggler.add(m_colorChangeAnimation);
        }
        
        public function redrawAfterModification(triggeredByUndo:Boolean=false):void
        {
            this.refreshNodes();
            this.buildTreeWidget();
            
            // Callback when tree modified
            m_ready = true;
            
            // Look through all term area components and re-assign views
            // We are primarily just looking for the set of entity ids within the
            // component manager
            // For each entity id check if a render component is present for it, if not
            // create a new one. Then go through the term areas and find matching widgets
            createRenderComponentForTermAreaEntityId();
            
            var param:Object = null;
            if (triggeredByUndo)
            {
                param = {undo:true};
            }
            this.dispatchEventWith(GameEvent.TERM_AREA_CHANGED, false, param);
        }
        
        private function createRenderComponentForTermAreaEntityId():void
        {
            // Get all the current entites within the term area, they are identified by their
            // node id and NOT the expression value
            var entityIds:Vector.<String> = new Vector.<String>();
            m_componentManager.getEntityIds(entityIds);
            
            // Get all the entities (cards) that exist in the term area, need these to compore later
            var outWidgetLeaves:Vector.<BaseTermWidget> = new Vector.<BaseTermWidget>();
            this.getWidgetLeaves(outWidgetLeaves);
            
            // For every entity id in the current manager, check if there is a matching
            // entity within the term area widget
            const numEntityIds:int = entityIds.length;
            var entityId:String;
            var i:int;
            for (i = 0; i < numEntityIds; i++)
            {
                entityId = entityIds[i];
                
                const numTermAreaEntities:int = outWidgetLeaves.length;
                var foundMatch:Boolean = false;
                var termAreaEntity:BaseTermWidget;
                var j:int;
                for (j = 0; j < numTermAreaEntities; j++)
                {
                    termAreaEntity = outWidgetLeaves[j];
                    if (termAreaEntity.getNode().id.toString() == entityId)
                    {
                        // IMPORTANT we must always rebind the the view in the term area to the existing
                        // render component. This is because on a redraw of the term area (which occurs on reset or undo)
                        // a new view is created but the old components want to be maintained
                        var renderComponent:RenderableComponent = m_componentManager.getComponentFromEntityIdAndType(
                            entityId, 
                            RenderableComponent.TYPE_ID
                        ) as RenderableComponent;
                        renderComponent.view = termAreaEntity;
                        
                        foundMatch = true;
                        outWidgetLeaves.splice(j, 1);
                        break;
                    }
                }
                
                // If an entity id within the component manager is not found in the term areas,
                // then we have a card that must be removed
                if (!foundMatch)
                {
                    m_componentManager.removeAllComponentsFromEntity(entityId);
                }
            }
            
            // For each leaf in the term area that did not match with an id the previous snapshot of the component
            // manager we need to create a new batch of data for that card.
            var numNewWidgets:int = outWidgetLeaves.length;
            for (i = 0; i< numNewWidgets; i++)
            {
                termAreaEntity = outWidgetLeaves[i];
                
                // Only base component we need to create for it is the render component
                entityId = termAreaEntity.getNode().id.toString();
                
                renderComponent = new RenderableComponent(entityId);
                renderComponent.view = termAreaEntity;
                m_componentManager.addComponentToEntity(renderComponent);
            }
        }
    }
}