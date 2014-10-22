package nullsafe;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

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
    macro static public function buildInstance () : Type {
        // trace(Context.getLocalType());

        var pos   : Position = Context.currentPos();
        var tpath : ComplexType = null;

        switch (Context.getLocalType()) {
            //classes
            case TInst(_,[TInst(t, params)]):
                var type         : ClassType    = t.get();
                var complex      : ComplexType  = t.toString().toComplex();
                var abstractName : String       = t.toString().replace('.', '_') + '_Abstract';

                var defined : Type = getDefined('nullsafe.$abstractName');
                if (defined != null) return defined;

                var td : TypeDefinition = {
                    pos      : pos, //Position
                    params   : null, //Null<Array<TypeParamDecl>>
                    pack     : ['nullsafe'], //Array<String>
                    name     : abstractName, //String
                    meta     : null, //Null<Metadata>
                    kind     : TDAbstract(complex, [complex], [complex]), //TDAbstract (tthis:Null<ComplexType>, from:Array<ComplexType>, to:Array<ComplexType>)
                    isExtern : false, //Null<Bool>
                    fields   : buildClassFields(type) //Array<Field>
                }

                Context.defineType(td);

                tpath = TPath({pack: td.pack, name: td.name, params: []});

            //abstracts
            case TInst(_,[TAbstract(t, params)]):
                if (t.get().impl == null) {
                    return t.toString().toComplex().toType();
                }

                var type         : ClassType    = t.get().impl.get();
                var complex      : ComplexType  = t.toString().toComplex();
                var abstractName : String       = t.toString().replace('.', '_') + '_Abstract';

                var defined : Type = getDefined('nullsafe.$abstractName');
                if (defined != null) return defined;

                var td : TypeDefinition = {
                    pos      : pos, //Position
                    params   : null, //Null<Array<TypeParamDecl>>
                    pack     : ['nullsafe'], //Array<String>
                    name     : abstractName, //String
                    meta     : null, //Null<Metadata>
                    kind     : TDAbstract(complex, [complex], [complex]), //TDAbstract (tthis:Null<ComplexType>, from:Array<ComplexType>, to:Array<ComplexType>)
                    isExtern : false, //Null<Bool>
                    fields   : buildClassFields(type) //Array<Field>
                }

                Context.defineType(td);

                tpath = TPath({pack: td.pack, name: td.name, params: []});

            case _:
                #if nullsafe_debug
                    trace ("Can't implement null safety for this type:", Context.getLocalType());
                #else
                    Context.error("Can't implement null safety for this type.", pos);
                #end

        }

        return tpath.toType();
    }//function buildInstance()


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
                case TPath({name:'StdTypes', sub:t}) : (t == 'Int' || t == 'Float' || t == 'Bool');
                case _: false;
            }

            var nstype : ComplexType = (
                nosafety
                    ? type
                    : TPath({
                        sub    : null, //Null<Null<String>>
                        params : [TPType(type)], //Null<Array<TypeParam>>
                        pack   : [], //Array<String>
                        name   : 'NullSafe' //String
                    })
            );

            switch (f.kind) {
                case FVar(_,_) :
                    //property
                    fields.push({
                        pos    : pos, //Position
                        name   : f.name, //String
                        meta   : null, //Null<Metadata>
                        kind   : FProp('get', 'set', nstype), //FieldType
                        doc    : f.doc, //Null<Null<String>>
                        access : [(f.isPublic ? APublic : APrivate)] //Null<Array<Access>>
                    });

                    //getter
                    fields.push({
                        pos    : pos, //Position
                        name   : 'get_${f.name}', //String
                        meta   : null, //Null<Metadata>
                        kind   : buildGetter(f, nstype, nosafety),
                        doc    : f.doc, //Null<Null<String>>
                        access : [APrivate, AInline] //Null<Array<Access>>
                    });

                    //setter
                    fields.push({
                        pos    : pos, //Position
                        name   : 'set_${f.name}', //String
                        meta   : null, //Null<Metadata>
                        kind   : buildSetter(f, nstype, nosafety),
                        doc    : f.doc, //Null<Null<String>>
                        access : [APrivate, AInline] //Null<Array<Access>>
                    });

                case FMethod(k) :
                    throw "not implemented";
            }
        }

        return fields;
    }//function buildClassFields()


    /**
    * Build getter for specified field
    *
    */
    static private function buildGetter (f:ClassField, type:ComplexType, nosafety:Bool) : FieldType {
        var egetter : Expr = (
            nosafety
                ? Context.parse('return this.${f.name}', Context.currentPos())
                : Context.parse('return (this == null ? null : this.${f.name})', Context.currentPos())
        );

        return FFun({
            ret    : type, //Null<ComplexType>
            params : null, //Null<Array<TypeParamDecl>>
            expr   : egetter, //Null<Expr>
            args   : []//Array<FunctionArg>
        });
    }//function buildGetter()


    /**
    * Build setter for specified field
    *
    */
    static private function buildSetter (f:ClassField, type:ComplexType, nosafety:Bool) : FieldType {
        var esetter : Expr = (
            nosafety
                ? Context.parse('return this.${f.name} = p', Context.currentPos())
                : Context.parse('return (this == null ? null : this.${f.name} = p)', Context.currentPos())
        );

        return FFun({
            ret    : type, //Null<ComplexType>
            params : null, //Null<Array<TypeParamDecl>>
            expr   : esetter, //Null<Expr>
            args   : [{
                value : null, //Null<Null<Expr>>
                type  : f.type.toComplexType(), //Null<ComplexType>
                opt   : false, //Null<Bool>
                name  : 'p' //String
            }]
        });
    }//function buildSetter()

}//class NullSafeBuilder
