package nullsafe;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

using StringTools;
using haxe.macro.Tools;


typedef TClassFields = {fields:Array<ClassField>}


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
        return buildAbstract(Context.getLocalType(), recursive);
    }//function build()


    /**
    * Description
    *
    */
    static private function buildAbstract (type:Type, recursive:Bool) : Type {
        switch (type) {
            //classes
            case TInst(_,[TInst(t, params)]):
                type = defineType(t.toString(), t.get().fields.get(), t.toString().toComplex(), recursive);

            //abstracts
            case TInst(_,[TAbstract(t, params)]):
                if (t.get().impl == null) {
                    return t.toString().toComplex().toType();
                }

                type = defineType(t.toString(), t.get().impl.get().fields.get(), t.toString().toComplex(), recursive);

            //typedefs
            case TInst(ns,[TType(t,params)]):
                type = buildAbstract(TInst(ns, [t.get().type]), recursive);

            //anonymous
            case TInst(_, [TAnonymous(t)]):
                Context.error("Can't implement null safety for anonymous structures.", Context.currentPos());

            //typedefs
            case TInst(ns,[TDynamic(t)]):
                Context.error("Can't implement null safety for Dynamic.", Context.currentPos());

            case _:
                #if NS_DEBUG
                    trace ("Can't implement null safety for this type:", Context.getLocalType(), type);
                    type = null;
                #else
                    Context.error("Can't implement null safety for this type.", Context.currentPos());
                #end

        }

        return type;
    }//function buildAbstract()


    /**
    * Description
    *
    */
    static private function typeName (name:String, recursive:Bool) : String {
        return name.replace('.', '_').replace('<', '_').replace('>', '_') + '_' + (recursive ? 'R' : '') + 'Abstract';
    }//function typeName()


    /**
    * Description
    *
    */
    static private function generateName (fields:Array<ClassField>) : String {
        var name : String = 'A';
        for (f in fields) {
            name += f.name;
            name += switch (f.type) {
                case TAnonymous(t) : generateName(t.get().fields);
                case _             : f.type.toString();
            }
        }

        return haxe.crypto.Md5.encode(name);
    }//function generateName()


    /**
    * Description
    *
    */
    static private function defineType (srcName:Null<String>, fields:Array<ClassField>, complex:ComplexType, recursive:Bool) : Type {
        //return underlying type for code completion
        if (Context.defined('display')) {
            return complex.toType();
        }

        if (srcName == null) srcName = generateName(fields);

        var abstractName : String = typeName(srcName, recursive);

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
            fields   : buildClassFields(fields, recursive) //Array<Field>
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
    static private function buildClassFields (classFields:Array<ClassField>, recursive:Bool) : Array<Field> {
        var fields   : Array<Field> = [];
        var pos      : Position = Context.currentPos();
        var nosafety : Bool = false;

        for (f in classFields) {
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
