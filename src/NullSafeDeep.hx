package;


/**
* Null safety implementation
*
*/
@:genericBuild(nullsafe.NullSafeBuilder.build(true))
class NullSafeDeep<T> {


    /**
    * Description
    *
    */
    public function new<T> (v:T) : Void {
        //this = v;
    }//function new()


}//class NullSafeDeep

