package;


/**
* Null safety implementation
*
*/
@:genericBuild(nullsafe.NullSafeBuilder.build())
class NullSafe<T> {


    /**
    * Description
    *
    */
    public function new<T> (v:T) : Void {
        //this = v;
    }//function new()


}//class NullSafe

