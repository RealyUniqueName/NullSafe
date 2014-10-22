package nullsafe;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

using StringTools;
using haxe.macro.Tools;


/**
* Description
*
*/
class NullSafeBuilder {


    /**
    * Description
    *
    */
    macro static public function build () : Type {


        var pos  : Position = Context.currentPos();
        var type : Type = null;

        switch (Context.getLocalType()) {
            //classes
            case TInst(_,[TInst(t, params)]):
                type = defineType(t.get(), t.toString().toComplex());

            //abstracts
            case TInst(_,[TAbstract(t, params)]):
                if (t.get().impl == null) {
                    return t.toString().toComplex().toType();
                }

                type = defineType(t.get().impl.get(), t.toString().toComplex());
            case _:
                #if nullsafe_debug
                    trace ("Can't implement null safety for this type:", Context.getLocalType());
                #else
                    Context.error("Can't implement null safety for this type.", pos);
                #end

        }

        return type;
    }//function build()


    /**
    * Description
    *
    */
    static private function typeName (t:ClassType) : String {
        return t.pack.join('_') + '_' + t.module + '_' + t.name + '_Abstract';
    }//function typeName()


    /**
    * Description
    *
    */
    static private function defineType (type:ClassType, complex:ComplexType) : Type {
        //return underlying type for code completion
        if (Context.defined('display')) {
            return complex.toType();
        }

        var abstractName : String = typeName(type);

        var defined : Type = getDefined('nullsafe.$abstractName');
        if (defined != null) return defined;

        var td : TypeDefinition = {
            pos      : Context.currentPos(), //Position
            params   : null, //Null<Array<TypeParamDecl>>
            pack     : ['nullsafe'], //Array<String>
            name     : abstractName, //String
            meta     : null, //Null<Metadata>
            kind     : TDAbstract(complex, [complex], [complex]), //TDAbstract (tthis:Null<ComplexType>, from:Array<ComplexType>, to:Array<ComplexType>)
            isExtern : false, //Null<Bool>
            fields   : buildClassFields(type) //Array<Field>
        }

        Context.defineType(td);

        return TPath({pack: td.pack, name: td.name, params: []}).toType();
    }//function defineType()

    /**
    * Description
    *
    */
    static private function getDefined (type:String) : Null<Type> {
        try {
            return Context.getType(type);
        } catch(e:Dynamic) {
            return null;
        }
    }//function getDefined()


    /**
    * Description
    *
    */
    static private function buildClassFields (type:ClassType) : Array<Field> {
        var fields   : Array<Field> = [];
        var pos      : Position = Context.currentPos();
        var nosafety : Bool = false;

        for (f in type.fields.get()) {
            var type   : ComplexType = f.type.toComplexType();

            nosafety = switch (type) {
                case macro:StdTypes.Int     : true;
                case macro:StdTypes.Float   : true;
                case macro:StdTypes.Bool    : true;
                case _: false;
            }

            var nstype : ComplexType = (nosafety ? type : macro:NullSafe<$type>);

            switch (f.kind) {
                case FVar(_,_) :
                    fields = fields.concat(buildProperty(f, nstype));

                case FMethod(k) :
                    throw "not implemented";
            }
        }

        return fields;
    }//function buildClassFields()


    /**
    * Description
    *
    */
    static private function buildProperty (f:ClassField, type:ComplexType) : Array<Field> {
        var field : String = f.name;
        var get   : String = 'get_${f.name}';
        var set   : String = 'set_${f.name}';
        var def : Expr = (
            f.expr() == null
                ? macro null
                : Context.parse(TypedExprTools.toString(f.expr(), true), f.expr().pos)
        );

        var dummy : TypeDefinition = macro class Dummy {
            var $field (get,set) : $type;
            inline function $get() : $type return (this == null ? $def : this.$field);
            inline function $set(v:$type) : $type return (this == null ? v : this.$field = v);
        }

        if (f.isPublic) {
            dummy.fields[0].access = [APublic];
        }

        return dummy.fields;
    }//function buildProperty()


}//class NullSafeBuilder
