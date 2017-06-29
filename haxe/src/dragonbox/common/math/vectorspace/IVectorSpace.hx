package dragonbox.common.math.vectorspace;


/**
 * Associativity of addition    u + (v + w) = (u + v) + w
 * Commutativity of addition    u + v = v + u
 * Identity element of addition    There exists an element 0 ∈ V, called the zero vector, such that v + 0 = v for all v ∈ V.
 * Inverse elements of addition    For every v ∈ V, there exists an element −v ∈ V, called the additive inverse of v, such that v + (−v) = 0
 * Distributivity of scalar multiplication with respect to vector addition      a(u + v) = au + av
 * Distributivity of scalar multiplication with respect to field addition    (a + b)v = av + bv
 * Compatibility of scalar multiplication with field multiplication    a(bv) = (ab)v [nb 2]
 * Identity element of scalar multiplication    1v = v, where 1 denotes the multiplicative identity in F.
 * 
 */
interface IVectorSpace
{
    
    var operators(get, never) : Array<String>;

    function add(lhs : Dynamic, rhs : Dynamic) : Dynamic;
    function sub(lhs : Dynamic, rhs : Dynamic) : Dynamic;
    function mul(lhs : Dynamic, rhs : Dynamic) : Dynamic;
    function div(lhs : Dynamic, rhs : Dynamic) : Dynamic;
    function inv(rhs : Dynamic) : Dynamic;
    function zero() : Dynamic;
    function identity() : Dynamic;
    function valueOf(content : String) : Dynamic;
    function getAdditionOperator() : String;
    function getSubtractionOperator() : String;
    function getMultiplicationOperator() : String;
    function getDivisionOperator() : String;
    function getEqualityOperator() : String;
    
    /**
     * @return
     *         True if the operator is valid in this space, false otherwise
     */
    function getContainsOperator(operator : String) : Bool;
    
    /**
     * @param
     *         The string representation of the operator as defined in the
     *         oeprators list in this space
     * @return
     *         The precedence value of the operator is not useful by itself,
     *         it should only be used for comparison. Returns -1 if the operator
     *         is invalid, otherwise it is always a non-negative value.
     */
    function getOperatorPrecedence(operator : String) : Int;
    
    /**
     * http://en.wikipedia.org/wiki/Commutative_property#Mathematical_definitions
     */
    function getOperatorIsCommunative(operator : String) : Bool;
    
    /**
     * http://en.wikipedia.org/wiki/Associative_property
     */
    function getOperatorIsAssociative(operator : String) : Bool;
    
    /**
     * An operator that is left associative means that we can correctly evaluate an expression consisting of just
     * that operator going from left to right. I.e. x-y-z = (x-y)-z
     * 
     * HACK: saying equality is not left associative
     * 
     * @param operator
     *         The string representation of the operator as defined in the
     *         oeprators list in this space
     * @return
     *         True if the given operator is left-associative, false if it is
     *         right associative
     */
    function getOperatorIsLeftAssociative(operator : String) : Bool;
}
