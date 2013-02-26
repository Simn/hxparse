import Data;
import haxe.macro.Expr;
import haxe.ds.Option;
using Lambda;

enum ErrorMsg {
	MissingSemicolon;
	Custom(s:String);
}

typedef Error = {
	msg: ErrorMsg,
	pos: hxparse.Lexer.Pos
}

class HaxeParser extends hxparse.Parser<Token> {

	var doResume = false;
	var doc:String;

	public function new(input:haxe.io.Input, sourceName:String) {
		super(new hxparse.LexerStream(new HaxeLexer(input, sourceName), HaxeLexer.tok));
	}

	public function parse() {
		parseFile();
	}

	static inline function punion(p1:Position, p2:Position) {
		return {
			file: p1.file,
			min: p1.min < p2.min ? p1.min : p2.min,
			max: p1.max > p2.max ? p1.max : p2.max,
		};
	}

	static inline function isLowerIdent(s:String) {
		function loop(p) {
			var c = s.charCodeAt(p);
			return if (c >= 'a'.code && c <= 'z'.code)
				true
			else if (c == '_'.code) {
				if (p + 1 < s.length)
					loop(p + 1);
				else
					true;
			} else
				false;
		}
		return loop(0);
	}

	inline function aadd<T>(a:Array<T>, t:T) {
		a.push(t);
		return a;
	}

	function psep<T>(t:TokenDef, f:Void->T) {
		var v = f();
		var ret = [];
		while (v != noMatch) {
			ret.push(v);
			if (peek().tok != t)
				break;
			junk();
			v = f();
		}
		return ret;
	}

	function popt<T>(f:Void->T) {
		return switch stream {
			case [v = f()]: v;
			case _: null;
		}
	}

	function plist<T>(f:Void->T) {
		return switch stream {
			case [v = f(), l = plist(f)]: aadd(l,v);
			case _: [];
		}
	}

	function ident() {
		return switch stream {
			case [{tok:Const(CIdent(i)),pos:p}]: { name: i, pos: p};
		}
	}

	function dollarIdent() {
		return switch stream {
			case [{tok:Const(CIdent(i)),pos:p}]: { name: i, pos: p};
			case [{tok:Dollar(i), pos:p}]: { name: "$" + i, pos: p};
		}
	}

	function dollarIdentMacro(pack) {
		return switch stream {
			case [{tok:Const(CIdent(i)),pos:p}]: { name: i, pos: p};
			case [{tok:Dollar(i), pos:p}]: { name: "$" + i, pos: p};
			case [{tok:Kwd(Macro), pos: p} && pack.length > 0]: { name: "macro", pos: p };
		}
	}

	function lowerIdentOrMacro() {
		return switch stream {
			case [{tok:Const(CIdent(i))} && isLowerIdent(i)]: i;
			case [{tok:Kwd(Macro)}]: "macro";
		}
	}

	function anyEnumIdent() {
		return switch stream {
			case [i = ident()]: i;
			//case [{tok:Kwd(k), pos:p}
		}
	}

	function propertyIdent() {
		return switch stream {
			case [i = ident()]: i.name;
			case [{tok:Kwd(Dynamic)}]: "dynamic";
			case [{tok:Kwd(Default)}]: "default";
			case [{tok:Kwd(Null)}]: "null";
		}
	}

	function getDoc() {
		return "";
	}

	function comma() {
		return switch stream {
			case [{tok:Comma}]:
		}
	}

	function semicolon() {
		return if (stream.last.tok == BrClose) {
			switch stream {
				case [{tok: Semicolon, pos:p}]: p;
				case _: stream.last.pos;
			}
		} else switch stream {
			case [{tok: Semicolon, pos:p}]: p;
		case _:
			var pos = stream.last.pos;
			if (doResume)
				pos
			else
				throw {
					msg: MissingSemicolon,
					pos: pos
				}
		}
	}

	function parseFile() {
		switch stream {
			case [{tok:Kwd(Package)}, p = parsePackage(), _ = semicolon(), l = parseTypeDecls(p,[]), {tok:Eof}]:
				trace(l);
			case [l = parseTypeDecls([],[]), {tok:Eof}]:
				trace(l);
		}
	}

	function parseTypeDecls(pack, acc:Array<TypeDef>) {
		return switch stream {
			case [ v = parseTypeDecl(), l = parseTypeDecls(pack,aadd(acc,v.decl)) ]:
				l;
			case _: acc;
		}
	}

	function parseTypeDecl() {
		return switch stream {
			case [{tok:Kwd(Import), pos:p1}]:
				parseImport(p1);
			case [{tok:Kwd(Using), pos: p1}, t = parseTypePath(), p2 = semicolon()]:
				{decl: EUsing(t), pos: punion(p1, p2)};
			case [meta = parseMeta(), c = parseCommonFlags()]:
				switch stream {
					case [flags = parseEnumFlags(), doc = getDoc(), name = typeName(), tl = parseConstraintParams(), {tok:BrOpen}, l = plist(parseEnum), {tok:BrClose, pos: p2}]:
						{decl: EEnum({
							name: name,
							doc: doc,
							meta: meta,
							params: tl,
							flags: c.map(function(i) return i.e).concat(flags.flags),
							data: l
						}), pos: punion(flags.pos,p2)};
					case [flags = parseClassFlags(), doc = getDoc(), name = typeName(), tl = parseConstraintParams(), hl = plist(parseClassHerit), {tok:BrOpen}, fl = parseClassFields(false,flags.pos)]:
						{decl: EClass({
							name: name,
							doc: doc,
							meta: meta,
							params: tl,
							flags: c.map(function(i) return i.c).concat(flags.flags).concat(hl),
							data: fl.fields
						}), pos: punion(flags.pos,fl.pos)};
					case [{tok: Kwd(Typedef), pos: p1}, doc = getDoc(), name = typeName(), tl = parseConstraintParams(), {tok:Binop(OpAssign), pos: p2}, t = parseComplexType()]:
						switch stream {
							case [{tok:Semicolon}]:
							case _:
						}
						{ decl: ETypedef({
							name: name,
							doc: doc,
							meta: meta,
							params: tl,
							flags: c.map(function(i) return i.e),
							data: t
						}), pos: punion(p1,p2)};
				}
		}
	}

	function parseClass(meta, cflags, needName) {
		var optName = if (needName) typeName else function() {
			var t = popt(typeName);
			return t == null ? "" : t;
		}
		switch stream {
			case [flags = parseClassFlags(), doc = getDoc(), name = optName(), tl = parseConstraintParams(), hl = psep(Comma,parseClassHerit), {tok: BrOpen}, fl = parseClassFields(false,flags.pos)]:
				{ decl: EClass({
					name: name,
					doc: doc,
					meta: meta,
					params: tl,
					flags: cflags.map(function(i) return i.fst).concat(flags.flags).concat(hl),
					data: fl.fields
				}), pos: punion(flags.pos,fl.pos)};
		}
	}

	function parseImport(p1) {
		function loop(acc):{pos:Position, mode:ImportMode, acc:Array<{pack:String, pos:Position}>} {
			return switch stream {
				case [{tok: Dot}]:
					switch stream {
						case [{tok:Const(CIdent(k)), pos: p}]:
							loop(aadd(acc,{pack:k,pos:p}));
						case [{tok:Kwd(Macro), pos:p}]:
							loop(aadd(acc,{pack:"macro",pos:p}));
						case [{tok:Binop(OpMult)}, {tok:Semicolon, pos:p2}]:
							{pos: p2, acc: acc, mode: IAll};
						case _: serror();
					}
				case [{tok:Semicolon, pos:p2}]:
					{ pos: p2, acc: acc, mode: INormal};
				case [{tok:Kwd(In)}, {tok:Const(CIdent(name))}, {tok:Semicolon, pos:p2}]:
					{ pos: p2, acc: acc, mode: IAsName(name)};
				case _: serror();
			}
		}
		var data = switch stream {
			case [{tok:Const(CIdent(name)), pos:p}]: loop([{pack:name, pos:p}]);
			case _: serror();
		}
		return {
			decl: EImport(data.acc,data.mode),
			pos: punion(p1, data.pos)
		};
	}

	function parsePackage() {
		return psep(Dot, lowerIdentOrMacro);
	}

	function parseClassFields(tdecl, p1):{fields:Array<Field>, pos:Position} {
		var l = parseClassFieldResume(tdecl);
		var p2 = switch stream {
			case [{tok: BrClose, pos: p2}]:
				p2;
			case _: serror();
		}
		return {
			fields: l,
			pos: p2
		}
	}

	function parseClassFieldResume(tdecl) {
		return plist(parseClassField);
	}

	function parseCommonFlags():Array<{c:ClassFlag, e:EnumFlag}> {
		return switch stream {
			case [{tok:Kwd(Private)}, l = parseCommonFlags()]: aadd(l, {c:HPrivate, e:EPrivate});
			case [{tok:Kwd(Extern)}, l = parseCommonFlags()]: aadd(l, {c:HExtern, e:EExtern});
			case _: [];
		}
	}

	function parseMetaParams(pname) {
		return switch stream {
			case [{tok: POpen, pos:p} && p.min == pname.max, params = psep(Comma, expr), {tok: PClose}]: params;
			case _: [];
		}
	}

	function parseMetaEntry() {
		return switch stream {
			case [{tok:At}, name = metaName(), params = parseMetaParams(name.pos)]: {name: name.name, params: params, pos: name.pos};
		}
	}

	function parseMeta() {
		return switch stream {
			case [entry = parseMetaEntry()]: aadd(parseMeta(), entry);
			case _: [];
		}
	}

	function metaName() {
		return switch stream {
			case [{tok:Const(CIdent(i)), pos:p}]: {name: i, pos: p};
			//case [{tok:Kwd(k), pos:p}]: {name: }
			case [{tok:DblDot}]:
				switch stream {
					case [{tok:Const(CIdent(i)), pos:p}]: {name: i, pos: p};

				}
		}
	}

	function parseEnumFlags() {
		return switch stream {
			case [{tok:Kwd(Enum), pos:p}]: {flags: [], pos: p};
		}
	}

	function parseClassFlags() {
		return switch stream {
			case [{tok:Kwd(Class), pos:p}]: {flags: [], pos: p};
			case [{tok:Kwd(Interface), pos:p}]: {flags: aadd([],HInterface), pos: p};
		}
	}

	function parseTypeOpt() {
		return switch stream {
			case [{tok:DblDot}, t = parseComplexType()]: t;
			case _: null;
		}
	}

	function parseComplexType() {
		var t = parseComplexTypeInner();
		return parseComplexTypeNext(t);
	}

	function parseComplexTypeInner():ComplexType {
		return switch stream {
			case [{tok:POpen}, t = parseComplexType(), {tok:PClose}]: TParent(t);
			case [{tok:BrOpen, pos: p1}]:
				switch stream {
					case [l = parseTypeAnonymous(false)]: TAnonymous(l);
					case [{tok:Binop(OpGt)}, t = parseTypePath(), {tok:Comma}]:
						switch stream {
							case [l = parseTypeAnonymous(false)]: TExtend(t,l);
							case [fl = parseClassFields(true, p1)]: TExtend(t, fl.fields);
							case _: serror();
						}
					case [l = parseClassFields(true, p1)]: TAnonymous(l.fields);
					case _: serror();
				}
			case [{tok:Question}, t = parseComplexTypeInner()]:
				TOptional(t);
			case [t = parseTypePath()]:
				TPath(t);
		}
	}

	function parseTypePath() {
		return parseTypePath1([]);
	}

	function parseTypePath1(pack:Array<String>) {
		return switch stream {
			case [ident = dollarIdentMacro(pack)]:
				if (isLowerIdent(ident.name)) {
					switch stream {
						case [{tok:Dot}]:
							parseTypePath1(aadd(pack, ident.name));
						case [{tok:Semicolon}]:
							throw {
								msg: Custom("Type name should start with an uppercase letter"),
								pos: ident.pos
							}
						case _: serror();
					}
				} else {
					var sub = switch stream {
						case [{tok:Dot}]:
							switch stream {
								case [{tok:Const(CIdent(name))} && !isLowerIdent(name)]: name;
								case _: serror();
							}
						case _:
							null;
					}
					var params = switch stream {
						case [{tok:Binop(OpLt)}, l = psep(Comma, parseTypePathOrConst), {tok:Binop(OpGt)}]: l;
						case _: [];
					}
					pack.reverse();
					{
						pack: pack,
						name: ident.name,
						params: params,
						sub: sub
					}
				}
		}
	}

	function typeName() {
		return switch stream {
			case [{tok: Const(CIdent(name)), pos:p}]:
				if (isLowerIdent(name)) throw {
					msg: Custom("Type name should start with an uppercase letter"),
					pos: p
				}
				else name;
		}
	}

	function parseTypePathOrConst() {
		return switch stream {
			case [{tok:BkOpen, pos: p1}, l = parseArrayDecl(), {tok:BkClose, pos:p2}]: TPExpr({expr: EArrayDecl(l), pos:punion(p1,p2)});
			case [t = parseComplexType()]: TPType(t);
			case [{tok:Const(c), pos:p}]: TPExpr({expr:EConst(c), pos:p});
			case [e = expr()]: TPExpr(e);
			case _: serror();
		}
	}

	function parseComplexTypeNext(t) {
		return switch stream {
			case [{tok:Arrow}, t2 = parseComplexType()]:
				switch(t2) {
					case TFunction(args,r):
						TFunction(aadd(args,t),r);
					case _:
						TFunction([t],t2);
				}
			case _: t;
		}
	}

	function parseTypeAnonymous(opt):Array<Field> {
		return switch stream {
			case [{tok:Question} && !opt]: parseTypeAnonymous(true);
			case [id = ident(), {tok:DblDot}, t = parseComplexType()]:
				function next(p2,acc) {
					var t = !opt ? t : switch(t) {
						case TPath({pack:[], name:"Null"}): t;
						case _: TPath({pack:[], name:"Null", sub:null, params:[TPType(t)]});
					}
					return aadd(acc, {
						name: id.name,
						meta: opt ? [{name:":optional",params:[], pos:id.pos}] : [],
						access: [],
						doc: null,
						kind: FVar(t,null),
						pos: punion(id.pos, p2)
					});
				}
				switch stream {
					case [{tok:BrClose, pos:p2}]: next(p2, []);
					case [{tok:Comma, pos:p2}]:
						switch stream {
							case [{tok:BrClose}]: next(p2, []);
							case [l = parseTypeAnonymous(false)]: next(p2, l);
							case _: serror();
						}
					case _: serror();
				}
		}
	}

	function parseEnum() {
		doc = null;
		var meta = parseMeta();
		return switch stream {
			case [name = anyEnumIdent(), doc = getDoc(), params = parseConstraintParams()]:
				var args = switch stream {
					case [{tok:POpen}, l = psep(Comma, parseEnumParam), {tok:PClose}]: l;
					case _: [];
				}
				var t = switch stream {
					case [{tok:DblDot}, t = parseComplexType()]: t;
					case _: null;
				}
				var p2 = switch stream {
					case [p = semicolon()]: p;
					case _: serror();
				}
				{
					name: name.name,
					doc: doc,
					meta: meta,
					args: args,
					params: params,
					type: t,
					pos: punion(name.pos, p2)
				}
		}
	}

	function parseEnumParam() {
		return switch stream {
			case [{tok:Question}, name = ident(), {tok:DblDot}, t = parseComplexType()]: { name: name.name, opt: true, type: t};
			case [name = ident(), {tok:DblDot}, t = parseComplexType()]: { name: name.name, opt: false, type: t };
		}
	}
	
	function parseClassField() {
		doc = null;
		return switch stream {
			case [meta = parseMeta(), al = parseCfRights(true,[]), doc = getDoc()]:
				var data = switch stream {
					case [{tok:Kwd(Var), pos:p1}, name = ident()]:
						switch stream {
							case [{tok:POpen}, i1 = propertyIdent(), {tok:Comma}, i2 = propertyIdent(), {tok:PClose}]:
								var t = switch stream {
									case [{tok:DblDot}, t = parseComplexType()]: t;
									case _: null;
								}
								var e = switch stream {
									case [{tok:Binop(OpAssign)}, e = toplevelExpr(), p2 = semicolon()]: { expr: e, pos: p2 };
									case [{tok:Semicolon, pos:p2}]: { expr: null, pos: p2 };
									case _: serror();
								}
								{
									name: name.name,
									pos: punion(p1,e.pos),
									kind: FVar(t,e.expr)
								}
							case [t = parseTypeOpt()]:
								var e = switch stream {
									case [{tok:Binop(OpAssign)}, e = toplevelExpr(), p2 = semicolon()]: { expr: e, pos: p2 };
									case [{tok:Semicolon, pos:p2}]: { expr: null, pos: p2 };
									case _: serror();
								}
								{
									name: name.name,
									pos: punion(p1,e.pos),
									kind: FVar(t,e.expr)
								}
						}
					case [{tok:Kwd(Function), pos:p1}, name = parseFunName(), pl = parseConstraintParams(), {tok:POpen}, al = psep(Comma, parseFunParam), {tok:PClose}, t = parseTypeOpt()]:
						trace(peek());
						var e = switch stream {
							case [e = toplevelExpr(), _ = semicolon()]:
								{ expr: e, pos: e.pos };
							case [{tok: Semicolon,pos:p}]:
								{ expr: null, pos: p}
							case _: serror();
						}
						var f = {
							params: pl,
							args: al,
							ret: t,
							expr: e.expr
						}
						{
							name: name,
							pos: punion(p1, e.pos),
							kind: FFun(f)
						}
					case _:
						if (al.length == 0)
							return noMatch;
						else
							serror();
				}
			{
				name: data.name,
				doc: doc,
				meta: meta,
				access: al,
				pos: data.pos,
				kind: data.kind
			}
		}
	}

	function parseCfRights(allowStatic,l) {
		return switch stream {
			case [{tok:Kwd(Static)} && allowStatic, l = parseCfRights(false, aadd(l, AStatic))]: l;
			case [{tok:Kwd(Macro)} && !l.has(AMacro), l = parseCfRights(allowStatic, aadd(l, AMacro))]: l;
			case [{tok:Kwd(Public)} && !(l.has(APublic) || l.has(APrivate)), l = parseCfRights(allowStatic, aadd(l, APublic))]: l;
			case [{tok:Kwd(Private)} && !(l.has(APublic) || l.has(APrivate)), l = parseCfRights(allowStatic, aadd(l, APrivate))]: l;
			case [{tok:Kwd(Override)} && !l.has(AOverride), l = parseCfRights(false, aadd(l, AOverride))]: l;
			case [{tok:Kwd(Dynamic)} && !l.has(ADynamic), l = parseCfRights(allowStatic, aadd(l, ADynamic))]: l;
			case [{tok:Kwd(Inline)}, l = parseCfRights(allowStatic, aadd(l, AInline))]: l;
			case _: l;
		}
	}

	function parseFunName() {
		return switch stream {
			case [{tok:Const(CIdent(name))}]: name;
			case [{tok:Kwd(New)}]: "new";
		}
	}

	function parseFunParam() {
		return switch stream {
			case [{tok:Question}, id = ident(), t = parseTypeOpt(), c = parseFunParamValue()]: { name: id.name, opt: true, type: t, value: c};
			case [id = ident(), t = parseTypeOpt(), c = parseFunParamValue()]: { name: id.name, opt: false, type: t, value: c};

		}
	}

	function parseFunParamValue() {
		return switch stream {
			case [{tok:Binop(OpAssign)}, e = toplevelExpr()]: e;
			case _: null;
		}
	}

	function parseFunParamType() {
		return switch stream {
			case [{tok:Question}, id = ident(), {tok:DblDot}, t = parseComplexType()]: { name: id.name, opt: true, type: t};
			case [ id = ident(), {tok:DblDot}, t = parseComplexType()]: { name: id.name, opt: false, type: t};
		}
	}

	function parseConstraintParams() {
		return switch stream {
			case [{tok:Binop(OpLt)}, l = psep(Comma, parseConstraintParam), {tok:Binop((OpGt))}]: l;
			case _: [];
		}
	}

	function parseConstraintParam() {
		return switch stream {
			case [name = typeName()]:
				var params = [];
				var ctl = switch stream {
					case [{tok:DblDot}]:
						switch stream {
							case [{tok:POpen}, l = psep(Comma, parseComplexType), {tok:PClose}]: l;
							case [t = parseComplexType()]: [t];
							case _: serror();
						}
					case _: [];
				}
				{
					name: name,
					params: params,
					constraints: ctl
				}
		}
	}

	function parseClassHerit() {
		return switch stream {
			case [{tok:Kwd(Extends)}, t = parseTypePath()]: HExtends(t);
			case [{tok:Kwd(Implements)}, t = parseTypePath()]: HImplements(t);
		}
	}
	
	function toplevelExpr():Expr {
		return expr();
	}
	
	function expr():Expr {
		return switch stream {
			case [{tok:Const(c), pos:p}]: {expr:EConst(c), pos:p};
		}
	}
	
	function parseArrayDecl() {
		return null;
	}
}