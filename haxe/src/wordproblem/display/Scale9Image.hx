package wordproblem.display;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * ...
 * @author 
 */
class Scale9Image extends DisposableSprite {

	/**
	 * The scale9Rect passed in the constructor. Used to set properties of the
	 * scale9Rect used for positioning
	 */
	private var m_originalScale9Rect : Rectangle;
	
	private var m_scale9Rect : Rectangle;
	
	/**
	 * The dimensions of the original bitmap data are necessary for calculating the
	 * correct scale factor when the width or height is set
	 */
	private var m_originalWidth : Float;
	private var m_originalHeight : Float;
	
	private var m_center : Bitmap;
	
	private var m_left : Bitmap;
	private var m_right : Bitmap;
	
	private var m_top : Bitmap;
	private var m_bottom : Bitmap;
	
	private var m_topLeft : Bitmap;
	private var m_topRight : Bitmap;
	private var m_bottomLeft : Bitmap;
	private var m_bottomRight : Bitmap;
	
	/**
	 * If the rectangle passed in is meant to be a scale3, this is not null
	 * and is set to either "horizontal" or "vertical"
	 */
	private var m_scale3Mode : String = null;
	
	public function new(bitmapData : BitmapData, scale9Rect : Rectangle) {
		super();
		
		m_originalScale9Rect = new Rectangle();
		m_originalScale9Rect.copyFrom(scale9Rect);
		m_scale9Rect = new Rectangle();
		m_scale9Rect.copyFrom(scale9Rect);
		
		m_originalWidth = bitmapData.width;
		m_originalHeight = bitmapData.height;
		
		// We're always copying pixels into the origin of the new bitmap data
		var origin = new Point(0, 0);
		
		var left = Std.int(scale9Rect.left);
		var top = Std.int(scale9Rect.top);
		var right = Std.int(scale9Rect.right);
		var bottom = Std.int(scale9Rect.bottom);
		
		// If the left or top property is 0, that singles that this is just a scale3Grid
		// and we can do some optimizing
		if (left == 0 || top == 0) {
			// If the y of the rectangle is 0, we have a horizontal scale3; horizontal otherwise
			m_scale3Mode = top == 0 ? "horizontal" : "vertical";
		}
		
		var centerBitmapData = new BitmapData(right - left, bottom - top, false);
		centerBitmapData.copyPixels(bitmapData, scale9Rect, origin);
		m_center = new Bitmap(centerBitmapData);
		addChild(m_center);
		
		// We only need the corners if this is a true scale9
		if (m_scale3Mode == null) {
			var topLeftBitmapData = new BitmapData(left, top, false);
			topLeftBitmapData.copyPixels(bitmapData, new Rectangle(0, 0, left, top), origin);
			m_topLeft = new Bitmap(topLeftBitmapData);
			addChild(m_topLeft);
			
			var topRightBitmapData = new BitmapData(bitmapData.width - right, top, false);
			topRightBitmapData.copyPixels(bitmapData, new Rectangle(right, 0, bitmapData.width - right, top), origin); 
			m_topRight = new Bitmap(topRightBitmapData);
			addChild(m_topRight);
			
			var bottomLeftBitmapData = new BitmapData(left, bitmapData.height - bottom, false);
			bottomLeftBitmapData.copyPixels(bitmapData, new Rectangle(0, bottom, left, bitmapData.height - bottom), origin); 
			m_bottomLeft = new Bitmap(bottomLeftBitmapData);
			addChild(m_bottomLeft);
			
			var bottomRightBitmapData = new BitmapData(bitmapData.width - right, bitmapData.height - bottom, false);
			bottomRightBitmapData.copyPixels(bitmapData, new Rectangle(right, bottom, bitmapData.width - right, bitmapData.height - bottom), origin);
			m_bottomRight = new Bitmap(bottomRightBitmapData);
			addChild(m_bottomRight);
		}
		
		// We only need the left & right edges if this is a scale9 or a horizontal scale3
		if (m_scale3Mode == null || m_scale3Mode == "horizontal") {
			var leftBitmapData = new BitmapData(left, bottom - top, false);
			leftBitmapData.copyPixels(bitmapData, new Rectangle(0, top, left, bottom - top), origin); 
			m_left = new Bitmap(leftBitmapData);
			addChild(m_left);
			
			var rightBitmapData = new BitmapData(bitmapData.width - right, bottom - top, false);
			rightBitmapData.copyPixels(bitmapData, new Rectangle(right, top, bitmapData.width - right, bottom - top), origin);
			m_right = new Bitmap(rightBitmapData);
			addChild(m_right);
		}
		
		// We only need the top & bottom edges if this is a scale9 or a vertical scale3
		if (m_scale3Mode == null || m_scale3Mode == "vertical") {
			var topBitmapData = new BitmapData(right - left, top, false);
			topBitmapData.copyPixels(bitmapData, new Rectangle(left, 0, right - left, top), origin); 
			m_top = new Bitmap(topBitmapData);
			addChild(m_top);
			
			var bottomBitmapData = new BitmapData(right - left, bitmapData.height - bottom, false);
			bottomBitmapData.copyPixels(bitmapData, new Rectangle(left, bottom, right - left, bitmapData.height - bottom), origin);
			m_bottom = new Bitmap(bottomBitmapData);
			addChild(m_bottom);
		}
		
		layoutImages();
	}
	
	override public function dispose() {
		// Get rid of all the custom bitmap data we created
		removeChild(m_center);
		m_center.bitmapData.dispose();
		m_center = null;
		
		if (m_scale3Mode == null) {
			removeChild(m_topLeft);
			removeChild(m_topRight);
			removeChild(m_bottomLeft);
			removeChild(m_bottomRight);
			m_topLeft.bitmapData.dispose();
			m_topRight.bitmapData.dispose();
			m_bottomLeft.bitmapData.dispose();
			m_bottomRight.bitmapData.dispose();
			m_topLeft = null;
			m_topRight = null;
			m_bottomLeft = null;
			m_bottomRight = null;
		}
		
		if (m_scale3Mode == null || m_scale3Mode == "horizontal") {
			removeChild(m_left);
			removeChild(m_right);
			m_left.bitmapData.dispose();
			m_right.bitmapData.dispose();
			m_left = null;
			m_right = null;
		}
		
		if (m_scale3Mode == null || m_scale3Mode == "vertical") {
			removeChild(m_top);
			removeChild(m_bottom);
			m_top.bitmapData.dispose();
			m_bottom.bitmapData.dispose();
			m_top = null;
			m_bottom = null;
		}
	}
	
	public function getScale9Rect() : Rectangle {
		var returnRect = new Rectangle();
		returnRect.copyFrom(m_scale9Rect);
		return returnRect;
	}
	
	private function layoutImages() {
		m_center.x = m_scale9Rect.left;
		m_center.y = m_scale9Rect.top;
		
		if (m_scale3Mode == null) layoutCorners();
		if (m_scale3Mode == null || m_scale3Mode == "horizontal") layoutHorizontal();
		if (m_scale3Mode == null || m_scale3Mode == "vertical") layoutVertical();
	}
	
	private function layoutCorners() {
		var right = m_scale9Rect.right;
		var bottom = m_scale9Rect.bottom;
		
		m_topLeft.x = 0;
		m_topLeft.y = 0;
		
		m_topRight.x = right;
		m_topRight.y = 0;
		
		m_bottomLeft.x = 0;
		m_bottomLeft.y = bottom;
		
		m_bottomRight.x = right;
		m_bottomRight.y = bottom;
	}
	
	private function layoutHorizontal() {
		var top = m_scale9Rect.top;
		var right = m_scale9Rect.right;
		
		m_left.x = 0;
		m_left.y = top;
		
		m_right.x = right;
		m_right.y = top;
	}
	
	private function layoutVertical() {
		var left = m_scale9Rect.left;
		var bottom = m_scale9Rect.bottom;
		
		m_top.x = left;
		m_top.y = 0;
		
		m_bottom.x = left;
		m_bottom.y = bottom;
	}
	
	// When the x scaling is changed, we only want to change the center, top, & bottom
	override function set_scaleX(scaleX : Float) : Float {
		if (m_scale3Mode == null || m_scale3Mode == "vertical") {
			m_top.scaleX = scaleX;
			m_bottom.scaleX = scaleX;
		}
		m_center.scaleX = scaleX;
		m_scale9Rect.width = m_originalScale9Rect.width * scaleX;
		layoutImages();
		return scaleX;
	}
	
	override function get_scaleX() : Float {
		return m_center.scaleX;
	}
	
	// When the y scaling is changed, we only want to change the center, left, & right
	override function set_scaleY(scaleY : Float) : Float {
		if (m_scale3Mode == null || m_scale3Mode == "horizontal") {
			m_left.scaleY = scaleY;
			m_right.scaleY = scaleY;
		}
		m_center.scaleY = scaleY;
		m_scale9Rect.height = m_originalScale9Rect.height * scaleY;
		layoutImages();
		return scaleY;
	}
	
	override function get_scaleY() : Float {
		return m_center.scaleY;
	}
	
	override function set_width(width : Float) : Float {
		this.scaleX = (width / m_originalWidth);
		return width;
	}
	
	override function get_width() : Float {
		return m_originalWidth * m_center.scaleX;
	}
	
	override function set_height(height : Float) : Float {
		this.scaleY = (height / m_originalHeight);
		return height;
	}
	
	override function get_height() : Float {
		return m_originalHeight * m_center.scaleY;
	}
	
}