package cgs.server.abtesting;

import haxe.Constraints.Function;
import cgs.server.logging.requests.IServerRequest;

interface IAbTestingServerApi
{

    function requestUserTestConditions(
            existing : Bool = false, callback : Function = null) : Void
    ;
    
    function noUserConditions() : Void
    ;
    
    function logTestStart(
            testID : Int, conditionID : Int,
            detail : Dynamic = null, callback : Function = null) : Void
    ;
    
    function logTestEnd(
            testID : Int, conditionID : Int,
            detail : Dynamic = null, callback : Function = null) : Void
    ;
    
    function logConditionVariableStart(
            testID : Int, conditionID : Int, varID : Int, resultID : Int,
            time : Float = -1, detail : Dynamic = null, callback : Function = null) : Void
    ;
    
    function logConditionVariableResults(
            testID : Int, conditionID : Int, variableID : Int, resultID : Int,
            time : Float = -1, detail : Dynamic = null, callback : Function = null) : Void
    ;
    
    function abRequest(
            method : String, callback : Function = null, data : Dynamic = null,
            params : Dynamic = null, extraData : Dynamic = null, responseClass : Class<Dynamic> = null,
            dataFormat : String = "TEXT", uidRequired : Bool = false) : Void
    ;
    
    function createAbRequest(
            method : String, callback : Function = null, data : Dynamic = null,
            params : Dynamic = null, extraData : Dynamic = null, responseClass : Class<Dynamic> = null,
            dataFormat : String = "TEXT", uidRequired : Bool = false) : IServerRequest
    ;
}
