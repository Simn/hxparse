package hxparse;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using haxe.macro.Tools;

/**
	The RuleBuilder interfaces provides syntactic shortcuts for writing lexer
	rules.
**/
#if !macro
@:autoBuild(hxparse.RuleBuilderImpl.build())
#end
interface RuleBuilder { }

class RuleBuilderImpl {
	macro static public function build():Array<Field> {
		var fields = Context.getBuildFields();
		var fieldExprs = new Map();
		var delays = [];
		var ret = [];
		for (field in fields) {
			if (field.access.exists(function(a) return a == AStatic))
				switch(field.kind) {
					case FVar(t, e) if (e != null):
						switch(e.expr) {
							case EMeta({name: ":rule"}, e):
								delays.push(transformRule.bind(field, e, t, fieldExprs));
							case EMeta({name: ":mapping", params: args}, e):
								var offset = switch(args) {
									case [{expr: EConst(CInt(i))}]: Std.parseInt(i);
									case _: 0;
								}
								delays.push(transformMapping.bind(field, e, offset));
							case _:
								fieldExprs.set(field.name, e);
						}
					case _:
				}
			if (!field.meta.exists(function(m) return m.name == ":ruleHelper")) {
				ret.push(field);
			}
		}
		for (delay in delays)
			delay();
		return ret;
	}
	
	#if macro
	
	static function makeRule(fields:Map<String,Expr>, rule:Expr):String {
		return switch(rule.expr) {
			case EConst(CString(s)): s;
			case EConst(CIdent(i)): makeRule(fields, fields.get(i));
			case EBinop(OpAdd,e1,e2): "(" + makeRule(fields, e1) +")(" + makeRule(fields, e2) +")";
			case _: Context.error("Invalid rule", rule.pos);
		}
	}
	
	static function transformRule(field:Field, e:Expr, t:ComplexType, fields:Map<String,Expr>) {
		var el = switch(e.expr) {
			case EArrayDecl(el): el;
			case _: Context.error("Expected pattern => function map declaration", e.pos);
		}
		var el = el.map(function(e) {
			function loop(e:Expr) {
				return switch(e.expr) {
					case EBinop(OpArrow, rule, e):
						macro @:pos(e.pos) {rule:$v{makeRule(fields, rule)}, func:function(lexer:hxparse.Lexer):$t return $e};
					case EConst(CIdent(s)) if (fields.exists(s)):
						loop(fields.get(s));
					case _:
						Context.error("Expected pattern => function", e.pos);
				}
			}
			return loop(e);
		});
		var e = macro $a{el};
		var e = macro hxparse.Lexer.buildRuleset($e);
		field.kind = FVar(null, e);
		return e;
	}
	
	static function transformMapping(field:Field, e:Expr, offset:Int) {
		var t = Context.typeof(e).follow();
		var sl = [];
		switch(t) {
			case TAnonymous(a):
				for (f in a.get().fields) {
					var name = macro @:pos(e.pos) $i{f.name};
					var cName = f.name.charAt(offset).toLowerCase() + f.name.substr(offset + 1);
					sl.push(macro $v{cName} => $name);
				}
			case _:
				Context.error("Invalid mapping type", e.pos);
		}
		var e = macro $a{sl};
		field.kind = FVar(null, e);
		return e;
	}
	
	#end
}