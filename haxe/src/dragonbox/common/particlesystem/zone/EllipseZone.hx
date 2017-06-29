package dragonbox.common.particlesystem.zone;

import dragonbox.common.particlesystem.zone.IZone;

import dragonbox.common.particlesystem.Particle;

import flash.geom.Point;

class EllipseZone implements IZone
{
    public function new()
    {
    }
    
    public function contains(x : Float, y : Float) : Bool
    {
        return false;
    }
    
    public function getLocation() : Point
    {
        return null;
    }
    
    public function getArea() : Float
    {
        return 0;
    }
    
    public function collideParticle(particle : Particle, bounce : Float = 1) : Bool
    {
        return false;
    }
}
