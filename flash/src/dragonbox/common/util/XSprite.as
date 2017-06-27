package dragonbox.common.util
{
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.ColorTransform;

	public class XSprite
	{
		/**
		 * Tiles one sprite onto another according to the dimensions given (no scaling)
		 * @param	ontoSprite Sprite to tile onto.
		 * @param	tileData BitmapData to use for tiling.
		 * @param	startX Starting x coordinate to tile.
		 * @param	startY Starting y coordinate to tile.
		 * @param	widthToTile Overall width of the area to tile.
		 * @param	heightToTile Overall height of the area to tile.
		 * @param	randomizeOffsets Set to non-null to start at a random X,Y offset in the top left corner, set to null to begin at 0,0
		 */
		public static function tileToSprite(ontoSprite:Sprite, tileData:BitmapData, startX:Number, startY:Number, widthToTile:Number, heightToTile:Number, randomizeOffsets:PM_PRNG = null):void
		{
			var curX:Number = Math.floor(startX / tileData.width) * tileData.width;
			var curY:Number = Math.floor(startY / tileData.height) * tileData.height;
			if (randomizeOffsets) {
				curX += Math.floor(-tileData.width * randomizeOffsets.nextDouble());
				curY += Math.floor(-tileData.height * randomizeOffsets.nextDouble());
			}
			
			var origX:Number = curX;
			var origY:Number = curY;
			while (curX - startX < Math.max(tileData.width, widthToTile) + 10) {
				while (curY - startY < Math.max(tileData.height, heightToTile) + 10) {
					var bmp:Bitmap = new Bitmap(tileData);
					bmp.x = curX;
					bmp.y = curY;
					ontoSprite.addChild(bmp);
					
					curY += tileData.height - 1;
				}
				curX += tileData.width - 1;
				curY = origY;
			}
			//scrollRect = new Rectangle(startX, startY, widthToTile, heightToTile);
		}
		
		public static function extractRed(cc:uint):uint
		{
			return ((cc >> 16) & 0xFF);
		}
		
		public static function extractGreen(cc:uint):uint
		{
			return ((cc >> 8) & 0xFF);
		}
		
		public static function extractBlue(cc:uint):uint
		{
			return (cc & 0xFF);
		}
		
		public static function applyColorTransform(obj:DisplayObject, color:uint):void
		{
			var trans:ColorTransform = obj.transform.colorTransform;
			trans.redMultiplier = extractRed(color) / 255.0;
			trans.greenMultiplier = extractGreen(color) / 255.0;
			trans.blueMultiplier = extractBlue(color) / 255.0;
			obj.transform.colorTransform = trans;
		}
				
		public static function removeAllChildren(doc:DisplayObjectContainer):void
		{
			while (doc.numChildren > 0) {
				doc.removeChildAt(0);
			}
		}

		public static function setupDisplayObject(obj:DisplayObject, x:Number, y:Number, sz:Number):void
		{
			obj.x = x;
			obj.y = y;
			obj.scaleX = obj.scaleY = (sz / Math.max(obj.width, obj.height));
		}
		
		public static function selectChild(obj:MovieClip, selectName:String, childNames:Vector.<String>):MovieClip
		{
			for each (var checkChild:String in childNames) {
				if (checkChild != selectName) {
					obj.removeChild(obj[checkChild]);
				}
			}
			return obj;
		}
		
		public static function eventCallbackWrapper(func:Function, arg:*):Function
		{
			return function(ev:Event):void { func.call(null, ev, arg); };
		}
		
		/**
		 * Call a function for each state in a button.
		 * @param	btn Button to call function on.
		 * @param	hitTestState If true, button's hitTestState is included in the list, otherwise, it's not.
		 * @param	func Callback function, called with each button state.
		 */
		public static function forEachButtonState(btn:SimpleButton, hitTestState:Boolean, func:Function):void
		{
			var states:Array;
			if (hitTestState) {
				states = [btn.upState, btn.overState, btn.downState, btn.hitTestState];
			} else {
				states = [btn.upState, btn.overState, btn.downState];
			}
			
			for each (var state:DisplayObject in states) {
				func(state);
			}
		}
	}
}
