package hxparse;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using haxe.macro.Tools;

#if !macro
@:autoBuild(hxparse.RuleBuilderImpl.build())
#end
interface RuleBuilder { }

class RuleBuilderImpl {
	macro static public function build():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			if (!field.access.exists(function(a) return a == AStatic))
				continue;
			switch(field.kind) {
				case FVar(_, e) if (e != null):
					switch(e.expr) {
						case EMeta({name: ":rule"}, e):
							transformRule(field,e);
						case EMeta({name: ":mapping"}, e):
							transformMapping(field,e);
						case _:
					}
				case _:
			}
		}
		return fields;
	}
	
	#if macro
	static function transformRule(field:Field, e:Expr) {
		var el = switch(e.expr) {
			case EArrayDecl(el): el;
			case _: Context.error("Expected pattern => function map declaration", e.pos);
		}
		var el = el.map(function(e) {
			return switch(e) {
				case macro $rule => $e:
					macro  @:pos(e.pos) $rule => function(lexer:hxparse.Lexer) return $e;
				case _:
					Context.error("Expected pattern => function", e.pos);
			}
		});
		var e = macro $a{el};
		var e = macro hxparse.Lexer.build($e);
		field.kind = FVar(null, e);
	}
	
	static function transformMapping(field:Field, e:Expr) {
		var t = Context.typeof(e).follow();
		var sl = [];
		switch(t) {
			case TAnonymous(a):
				for (f in a.get().fields) {
					var name = macro $i{f.name};
					sl.push(macro $v{f.name.toLowerCase()} => $name);
				}
			case _:
				Context.error("Invalid mapping type", e.pos);
		}
		var e = macro $a{sl};
		field.kind = FVar(null, e);
	}
	
	#end
}