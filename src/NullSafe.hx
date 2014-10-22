package;


/**
* Null safety implementation
*
*/
@:genericBuild(nullsafe.NullSafeBuilder.buildInstance())
class NullSafe<T> {


    /**
    * Description
    *
    */
    public function new<T> (v:T) : Void {
        //this = v;
    }//function new()


}//class NullSafe

