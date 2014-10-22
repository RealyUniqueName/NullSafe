package;


/**
* Description
*
*/
class Test {
    public var q : Test;
    public var w : Int = 1;


    /**
    * Description
    *
    */
    static public function main () : Void {
        var t : TDef = {w:1};
        // trace(t);

        var ns : NullSafe<Test> = null;

        trace(ns);
        trace(ns.q);
        trace(ns.q.q);
        trace(ns.q.q.q);
        trace(ns.q.w);      //"Null object reference" error, since basic types can't be set to null

        var tt : Test = ns;
        // var ns : NullSafe<Int>;
        // var ns : NullSafe<Array<Int>>;
        // var ns : NullSafe<Dynamic>;
        // var ns : NullSafe<AbsTest>;

    }//function main()


    /**
    * Description
    *
    */
    public function new () : Void {
        // q = {w:1}
    }//function new()

}//class Test


abstract AbsTest(Int) from Int to Int { function new(t) this = t; }
typedef TDef = {w:Int}