package cgs.teacherportal.data;

import com.adobe.serialization.json.JSON;

class GameOptions
{
    private var m_obj : Dynamic;
    
    public function new(obj : Dynamic)
    {
        m_obj = clone(obj);
    }
    
    public function containsProperty(name : String) : Bool
    {
        return (getProperty(name) != null);
    }
    
    public function getProperty(name : String) : Dynamic
    {
        var result : Dynamic = null;
        if (name != null && name.length > 0)
        {
            result = m_obj;
            var path : Array<Dynamic> = name.split(".");
            while (result != null && path.length > 0)
            {
                var prop : String = path.shift();
                if (Reflect.hasField(result, prop))
                {
                    result = Reflect.field(result, prop);
                }
                else
                {
                    result = null;
                }
            }
        }
        return (result);
    }
    
    private static function clone(obj : Dynamic) : Dynamic
    {
        var json : String = com.adobe.serialization.json.JSON.encode(obj);
        return (com.adobe.serialization.json.JSON.decode(json));
    }
}
