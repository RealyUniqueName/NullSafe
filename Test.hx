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
        var ns : NullSafe<Test> = new Test();

        //write
        trace(ns.q.w = 2);                 //2
        trace(ns.q.q.q.q = new Test());    //Test instance

        //read
        trace(ns);          //Test instance
        trace(ns.w);        //1
        trace(ns.q);        //null
        trace(ns.q.q.q);    //null
        trace(ns.q.w);      //1 - default value for this field

        // (t : NullSafe<Test>).q.q.q = new Test();

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