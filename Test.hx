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
        var t  : Test = new Test();
        var ns : NullSafe<Test> = t;

        //write
        trace(ns.w = 2);                   //2
        trace(ns.q.q.q.q = new Test());    //null

        //read
        trace(ns);          //test instance
        trace(ns.w);        //2
        trace(ns.q);        //null
        trace(ns.q.q.q);    //null
        trace(ns.q.w);      //"Null object reference" error, since basic types can't be set to null



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