package hxparse;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

class ParserBuilder {
	static public function build():Array<haxe.macro.Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch(field.kind) {
				case FFun(fun) if (fun.expr != null):
					fun.expr = map(true, fun.expr);
				case _:
			}
		}
		return fields;
	}
	
	static function punion(p1:Position, p2:Position) {
		var p1 = Context.getPosInfos(p1);
		var p2 = Context.getPosInfos(p2);
		return Context.makePosition({
			file: p1.file,
			min: p1.min < p2.min ? p1.min : p2.min,
			max: p1.max > p2.max ? p1.max : p2.max
		});
	}
	
	static function map(needVal:Bool, e:Expr) {
		return switch(e.expr) {
			case ESwitch({expr: EConst(CIdent("stream"))}, cl, edef):
				if (edef != null)
					cl.push({values: [macro _], expr: edef, guard: null});
				transformCases(needVal, cl);
			case EBlock([]):
				e;
			case EBlock(el):
				var elast = el.pop();
				var el = el.map(map.bind(false));
				el.push(map(true, elast));
				macro $b{el};
			case _: e.map(map.bind(true));
		}
	}
	
	static var fcount = 0;
	
	static function transformCases(needVal:Bool, cl:Array<Case>) {
		var last = cl.pop();
		var funcs = [];
		function mkFunc(e) {
			var name = "__func" +fcount++;
			var e = needVal ? (macro function $name() return $e) : macro function $name() $e;
			funcs.push(e);
			return macro $i{name}();
		}
		var elast = makeCase(last, macro null);
		while (cl.length > 0) {
			elast = makeCase(cl.pop(), mkFunc(elast));
		}
		funcs.push(elast);
		return macro @:pos(elast.pos) $b{funcs};
	}
	
	static function makeCase(c:Case, def:Expr) {
		if (c.expr == null)
			Context.error("Missing expression", c.values[0].pos);
		var pat =
			if (c.values.length == 1)
				c.values[0];
			else if (c.values.length > 1)
				Context.error("Comma notation is not allowed while matching streams", punion(c.values[0].pos, c.values[c.values.length - 1].pos));
		var pl = switch(pat.expr) {
			case EArrayDecl(el): el;
			case EConst(CIdent("_")): return macro ${map(true, c.expr)};
			case _: Context.error("Expected [ patterns ]", pat.pos);
		}
		var last = pl.pop();
		function getDef(e) {
			return pl.length == 0 ? def : macro @:pos(e.pos) throw new hxparse.Parser.Unexpected(peek());
		}
		var plast = makePattern(last, map(true, c.expr), getDef(pat) );
		while (pl.length > 0) {
			var pat = pl.pop();
			plast = makePattern(pat, plast, getDef(pat));
		}
		return plast;
	}
	
	static function makePattern(pat:Expr, e:Expr, def:Expr) {
		return switch(pat.expr) {
			case EBinop(OpAssign, {expr: EConst(CIdent(s))}, e2):
				macro @:pos(pat.pos) {
					var $s = $e2;
					if ($i{s} != null) {
						$e;
					} else
						$def;
				}
			case EBinop(OpBoolAnd, e1, e2):
				macro @:pos(pat.pos) switch peek() {
					case $e1 if ($e2):
						junk();
						$e;
					case _: $def;
				}
			case _:
				macro @:pos(pat.pos) switch peek() {
					case $pat:
						junk();
						$e;
					case _: $def;
				}
		}
	}
}