package;


/**
* Description
*
*/
class Test {
    static public var st : Map<String,Test> = new Map();

    public var q : Test;

    public var intWithDefault   : Int = 1;
    public var intNoDefault     : Int;
    public var boolWithDefault  : Bool = true;
    public var boolNoDefault    : Bool;
    public var floatWithDefault : Float = 10.5;
    public var floatNoDefault   : Float;


    /**
    * Description
    *
    */
    static public function main () : Void {
        //NullSafeDeep makes nested fields safe too
        var ns : NullSafeDeep<Test> = null;

        //write
        trace(ns.q.intWithDefault = 2);                 //2
        trace(ns.q.q.q.q = new Test());    //Test instance

        //read
        trace(ns);          //Test instance
        trace(ns.intWithDefault);        //1
        trace(ns.q);        //null
        trace(ns.q.q.q);    //null
        trace(ns.q.intWithDefault);      //1 - default value for this field
        trace(ns.q.intNoDefault);        //0 - default value for integers
        trace(ns.q.boolWithDefault);     //true - default value for this field
        trace(ns.q.boolNoDefault);       //false - default value for booleans
        trace(ns.q.floatWithDefault);    //10.5    - default value for floats
        trace(ns.q.floatNoDefault);      //0    - default value for floats

        //NullSafe affects first level object only
        var ns : NullSafe<Test> = null;
        trace(ns.q);                //null
        trace(ns.intWithDefault);   // 1
        trace(ns.q.q);              //"Null object reference" error, because only `ns` is null-safe

        // var ns : NullSafe<Int>;
        // var ns : NullSafe<Array<Int>>;
        // var ns : NullSafe<Dynamic>;
        // var ns : NullSafe<AbsTest>;

        ns.method();
        // ns.q.method();

    }//function main()


    /**
    * Description
    *
    */
    public function new () : Void {
        // q = {w:1}
    }//function new()


    /**
    * Description
    *
    */
    public function method () : Void {
        trace('method executed');
    }//function method()

}//class Test


abstract AbsTest(Int) from Int to Int { function new(t) this = t; }
typedef TDef = {w:Int}