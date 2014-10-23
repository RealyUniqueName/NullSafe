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
    macro static public function build (recursive:Bool = false) : Type {


        var pos  : Position = Context.currentPos();
        var type : Type = null;

        switch (Context.getLocalType()) {
            //classes
            case TInst(_,[TInst(t, params)]):
                type = defineType(t.get(), t.toString().toComplex(), recursive);

            //abstracts
            case TInst(_,[TAbstract(t, params)]):
                if (t.get().impl == null) {
                    return t.toString().toComplex().toType();
                }

                type = defineType(t.get().impl.get(), t.toString().toComplex(), recursive);
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
    static private function typeName (t:ClassType, recursive:Bool) : String {
        return t.pack.join('_') + '_' + t.module + '_' + t.name + '_' + (recursive ? 'R' : '') + 'RAbstract';
    }//function typeName()


    /**
    * Description
    *
    */
    static private function defineType (type:ClassType, complex:ComplexType, recursive:Bool) : Type {
        //return underlying type for code completion
        if (Context.defined('display')) {
            return complex.toType();
        }

        var abstractName : String = typeName(type, recursive);

        var defined : Type = getDefined('nullsafe.$abstractName');
        if (defined != null) return defined;

        var td : TypeDefinition = {
            pos      : Context.currentPos(), //Position
            params   : null, //Null<Array<TypeParamDecl>>
            pack     : ['nullsafe'], //Array<String>
            name     : abstractName, //String
            meta     : [{name:':forward', params:null, pos:Context.currentPos()}], //Null<Metadata>
            kind     : TDAbstract(complex, [complex], [complex]), //TDAbstract (tthis:Null<ComplexType>, from:Array<ComplexType>, to:Array<ComplexType>)
            isExtern : false, //Null<Bool>
            fields   : buildClassFields(type, recursive) //Array<Field>
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
    static private function buildClassFields (type:ClassType, recursive:Bool) : Array<Field> {
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

            var nstype : ComplexType = (nosafety || !recursive ? type : macro:NullSafeDeep<$type>);

            switch (f.kind) {
                case FVar(_,_) :
                    fields = fields.concat(buildProperty(f, nstype));

                case FMethod(k) :
                    //throw "not implemented";
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
                ? defaultValue(type)
                : typedExprToExpr(f.expr())
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


    /**
    * Description
    *
    */
    static private function defaultValue (type:ComplexType) : Expr {
        return switch (type) {
            case macro:StdTypes.Int     : macro 0;
            case macro:StdTypes.Float   : macro 0.0;
            case macro:StdTypes.Bool    : macro false;
            case _: macro null;
        }
    }//function defaultValue()


    /**
    * Description
    *
    */
    static private function typedExprToExpr (texpr:TypedExpr) : Expr {
        return switch (texpr.expr) {
            case TConst(TFloat(v)):
                {expr:EConst(CFloat(v)), pos:texpr.pos};
            case _:
                Context.parse(TypedExprTools.toString(texpr, true), texpr.pos);
        }
    }//function typedExprToExpr()

}//class NullSafeBuilder
