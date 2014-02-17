import Data;
import haxe.macro.Expr;
import haxe.ds.Option;
using Lambda;

enum ParserErrorMsg {
	MissingSemicolon;
	MissingType;
	DuplicateDefault;
	Custom(s:String);
}

typedef ParserError = {
	msg: ParserErrorMsg,
	pos: hxparse.Position
}

class HaxeParser extends hxparse.Parser<HaxeLexer, Token> implements hxparse.ParserBuilder {

	var defines:Map<String, Dynamic>;

	var mstack:Array<Bool>;
	var doResume = false;
	var doc:String;
	var inMacro:Bool;
	
	public function new(input:byte.ByteData, sourceName:String) {
		super(new HaxeLexer(input, sourceName), HaxeLexer.tok);
		mstack = [];
		defines = new Map();
		defines.set("true", true);
		inMacro = false;
		doc = "";
	}

	public function define(flag:String, ?value:Dynamic)
	{
		defines.set(flag, value);
	}

	public function parse() {
		return parseFile();
	}
	
	override function peek(n) {
		return if (n == 0)
			switch(super.peek(0)) {
				case {tok:CommentLine(_) | Sharp("error" | "line")}:
					junk();
					peek(0);
				case {tok:Sharp(cond)}:
					junk();
					switch (cond) {
						case "if":
							mstack.unshift(parseMacroCond());
							if (!mstack[0]) skipTokens();
						case "elseif":
							var bool = parseMacroCond();
							if (mstack[0]) skipTokens();
							else
							{
								mstack[0] = bool;
								if (!mstack[0]) skipTokens();
							}
						case "else":
							if (mstack[0]) skipTokens();
							else mstack[0] = true;
							peek(0);
						case "end":
							mstack.shift();
							peek(0);
						case _:
							throw "wtf";
					}
					peek(0);
				case t: t;
			}
		else
			super.peek(n);
	}

	function parseMacroCond():Bool
	{
		return switch super.peek(0) {
			case {tok:Const(CIdent(s))}:
				junk();
				defines.exists(s);
			case {tok:Kwd(k)}:
				junk();
				var str = Std.string(k).substr(3).toLowerCase();
				defines.exists(str);
			case {tok:Unop(OpNot)}:
				junk();
				!parseMacroCond();
			case {tok:POpen}:
				junk();
				var val = parseMacroCond();
				while (true) switch super.peek(0) {
					case {tok:Binop(OpBoolAnd)}:
						junk();
						val = val && parseMacroCond();
					case {tok:Binop(OpBoolOr)}:
						junk();
						val = val || parseMacroCond();
					case {tok:PClose}:
						junk();
						break;
					case tok:
						throw tok;
						false;
				}
				val;
			case tok:
				throw tok;
				false;
		}
	}

	function skipTokens()
	{
		var start = mstack.length;

		while (true)
		{	
			switch (super.peek(0))
			{
				case {tok:Sharp("if")}:
					mstack.unshift(parseMacroCond());
				case {tok:Sharp("elseif")}:
					if (mstack.length == start) break;
					if (!mstack[0]) mstack[0] = parseMacroCond();
				case {tok:Sharp("else")}:
					if (mstack.length == start) break;
					else if (!mstack[0]) mstack[0] = true;
				case {tok:Sharp("end")}:
					if (mstack.length == start) break;
					mstack.shift();
				case _:
			}
			junk();
		}
	}

	static function punion(p1:Position, p2:Position) {
		return {
			file: p1.file,
			min: p1.min < p2.min ? p1.min : p2.min,
			max: p1.max > p2.max ? p1.max : p2.max,
		};
	}

	static function quoteIdent(s:String) {
		// TODO
		return s;
	}

	static function isLowerIdent(s:String) {
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

	static function isPostfix(e:Expr, u:Unop) {
		return switch (u) {
			case OpIncrement | OpDecrement:
				switch(e.expr) {
					case EConst(_) | EField(_) | EArray(_):
						true;
					case _:
						false;
				}
			case OpNot | OpNeg | OpNegBits: false;
		}
	}

	static function isPrefix(u:Unop) {
		return switch(u) {
			case OpIncrement | OpDecrement: true;
			case OpNot | OpNeg | OpNegBits: true;
		}
	}

	static function precedence(op:Binop) {
		var left = true;
		var right = false;
		return switch(op) {
			case OpMod : {p: 0, left: left};
			case OpMult | OpDiv : {p: 0, left: left};
			case OpAdd | OpSub : {p: 0, left: left};
			case OpShl | OpShr | OpUShr : {p: 0, left: left};
			case OpOr | OpAnd | OpXor : {p: 0, left: left};
			case OpEq | OpNotEq | OpGt | OpLt | OpGte | OpLte : {p: 0, left: left};
			case OpInterval : {p: 0, left: left};
			case OpBoolAnd : {p: 0, left: left};
			case OpBoolOr : {p: 0, left: left};
			case OpArrow : {p: 0, left: left};
			case OpAssign | OpAssignOp(_) : {p:10, left:right};
		}
	}

	static function isNotAssign(op:Binop) {
		return switch(op) {
			case OpAssign | OpAssignOp(_): false;
			case _: true;
		}
	}

	static function isDollarIdent(e:Expr) {
		return switch (e.expr) {
			case EConst(CIdent(n)) if (n.charCodeAt(0) == "$".code): true;
			case _: false;
		}
	}

	static function swap(op1:Binop, op2:Binop) {
		var i1 = precedence(op1);
		var i2 = precedence(op2);
		return i1.left && i1.p < i2.p;
	}

	static function makeBinop(op:Binop, e:Expr, e2:Expr) {
		return switch (e2.expr) {
			case EBinop(_op,_e,_e2) if (swap(op,_op)):
				var _e = makeBinop(op,e,_e);
				{expr: EBinop(_op,_e,_e2), pos:punion(_e.pos,_e2.pos)};
			case ETernary(e1,e2,e3) if (isNotAssign(op)):
				var e = makeBinop(op,e,e1);
				{expr:ETernary(e,e2,e3), pos:punion(e.pos, e3.pos)};
			case _:
				{ expr: EBinop(op,e,e2), pos:punion(e.pos, e2.pos)};
		}
	}

	static function makeUnop(op:Unop, e:Expr, p1:Position) {
		return switch(e.expr) {
			case EBinop(bop,e,e2):
				{ expr: EBinop(bop, makeUnop(op,e,p1), e2), pos: punion(p1,e.pos)};
			case ETernary(e1,e2,e3):
				{ expr: ETernary(makeUnop(op,e1,p1), e2, e3), pos:punion(p1,e.pos)};
			case _:
				{ expr: EUnop(op,false,e), pos:punion(p1,e.pos)};
		}
	}

	static function makeMeta(name:String, params:Array<Expr>, e:Expr, p1:Position) {
		return switch(e.expr) {
			case EBinop(bop,e,e2):
				{ expr: EBinop(bop, makeMeta(name,params,e,p1), e2), pos: punion(p1,e.pos)};
			case ETernary(e1,e2,e3):
				{ expr: ETernary(makeMeta(name,params,e1,p1), e2, e3), pos:punion(p1,e.pos)};
			case _:
				{ expr: EMeta({name:name, params:params, pos:p1}, e), pos: punion(p1, e.pos) };
		}
	}

	static function aadd<T>(a:Array<T>, t:T) {
		a.push(t);
		return a;
	}

	function psep<T>(sep:TokenDef, f:Void->T):Array<T> {
		var acc = [];
		while(true) {
			try {
				acc.push(f());
				switch stream {
					case [{tok: sep2} && sep2 == sep]:
				}
			} catch(e:hxparse.NoMatch<Dynamic>) {
				break;
			}
		}
		return acc;
	}

	function popt<T>(f:Void->T):Null<T> {
		return switch stream {
			case [v = f()]: v;
			case _: null;
		}
	}

	function plist<T>(f:Void->T):Array<T> {
		var acc = [];
		try {
			while(true) {
				acc.push(f());
			}
		} catch(e:hxparse.NoMatch<Dynamic>) {}
		return acc;
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

	function dollarIdentMacro(pack:Array<String>) {
		return switch stream {
			case [{tok:Const(CIdent(i)),pos:p}]: { name: i, pos: p};
			case [{tok:Dollar(i), pos:p}]: { name: "$" + i, pos: p};
			case [{tok:Kwd(KwdMacro), pos: p} && pack.length > 0]: { name: "macro", pos: p };
		}
	}

	function lowerIdentOrMacro() {
		return switch stream {
			case [{tok:Const(CIdent(i))} && isLowerIdent(i)]: i;
			case [{tok:Kwd(KwdMacro)}]: "macro";
		}
	}

	function anyEnumIdent() {
		return switch stream {
			case [i = ident()]: i;
			case [{tok:Kwd(k), pos:p}]: {name:k.getName().toLowerCase(), pos:p};
		}
	}

	function propertyIdent() {
		return switch stream {
			case [i = ident()]: i.name;
			case [{tok:Kwd(KwdDynamic)}]: "dynamic";
			case [{tok:Kwd(KwdDefault)}]: "default";
			case [{tok:Kwd(KwdNull)}]: "null";
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
		return if (last.tok == BrClose) {
			switch stream {
				case [{tok: Semicolon, pos:p}]: p;
				case _: last.pos;
			}
		} else switch stream {
			case [{tok: Semicolon, pos:p}]: p;
		case _:
			var pos = last.pos;
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
		return switch stream {
			case [{tok:Kwd(KwdPackage)}, p = parsePackage(), _ = semicolon(), l = parseTypeDecls(p,[]), {tok:Eof}]:
				{ pack: p, decls: l };
			case [l = parseTypeDecls([],[]), {tok:Eof}]:
				{ pack: [], decls: l };
		}
	}

	function parseTypeDecls(pack:Array<String>, acc:Array<TypeDef>) {
		return switch stream {
			case [ v = parseTypeDecl(), l = parseTypeDecls(pack,aadd(acc,v.decl)) ]:
				l;
			case _: acc;
		}
	}

	function parseTypeDecl() {
		return switch stream {
			case [{tok:Kwd(KwdImport), pos:p1}]:
				parseImport(p1);
			case [{tok:Kwd(KwdUsing), pos: p1}, t = parseTypePath(), p2 = semicolon()]:
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
					case [{tok: Kwd(KwdTypedef), pos: p1}, doc = getDoc(), name = typeName(), tl = parseConstraintParams(), {tok:Binop(OpAssign), pos: p2}, t = parseComplexType()]:
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

	function parseClass(meta:Metadata, cflags:Array<{fst: ClassFlag, snd:String}>, needName:Bool) {
		var optName = if (needName) typeName else function() {
			var t = popt(typeName);
			return t == null ? "" : t;
		}
		return switch stream {
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

	function parseImport(p1:Position) {
		var acc = switch stream {
			case [{tok:Const(CIdent(name)), pos:p}]: [{pack:name, pos:p}];
			case _: unexpected();
		}
		while(true) {
			switch stream {
				case [{tok: Dot}]:
					switch stream {
						case [{tok:Const(CIdent(k)), pos: p}]:
							acc.push({pack:k,pos:p});
						case [{tok:Kwd(KwdMacro), pos:p}]:
							acc.push({pack:"macro",pos:p});
						case [{tok:Binop(OpMult)}, {tok:Semicolon, pos:p2}]:
							return {
								decl: EImport(acc, IAll),
								pos: p2
							}
						case _: unexpected();
					}
				case [{tok:Semicolon, pos:p2}]:
					return {
						decl: EImport(acc, INormal),
						pos: p2
					}
				case [{tok:Kwd(KwdIn)}, {tok:Const(CIdent(name))}, {tok:Semicolon, pos:p2}]:
					return {
						decl: EImport(acc, IAsName(name)),
						pos: p2
					}
				case _: unexpected();
			}
		}
	}

	function parsePackage() {
		return psep(Dot, lowerIdentOrMacro);
	}

	function parseClassFields(tdecl:Bool, p1:Position):{fields:Array<Field>, pos:Position} {
		var l = parseClassFieldResume(tdecl);
		var p2 = switch stream {
			case [{tok: BrClose, pos: p2}]:
				p2;
			case _: unexpected();
		}
		return {
			fields: l,
			pos: p2
		}
	}

	function parseClassFieldResume(tdecl:Bool):Array<Field> {
		return plist(parseClassField);
	}

	function parseCommonFlags():Array<{c:ClassFlag, e:EnumFlag}> {
		return switch stream {
			case [{tok:Kwd(KwdPrivate)}, l = parseCommonFlags()]: aadd(l, {c:HPrivate, e:EPrivate});
			case [{tok:Kwd(KwdExtern)}, l = parseCommonFlags()]: aadd(l, {c:HExtern, e:EExtern});
			case _: [];
		}
	}

	function parseMetaParams(pname:Position) {
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
			case [{tok:Kwd(k), pos:p}]: {name: k.getName().toLowerCase(), pos:p};
			case [{tok:DblDot}]:
				switch stream {
					case [{tok:Const(CIdent(i)), pos:p}]: {name: i, pos: p};

				}
		}
	}

	function parseEnumFlags() {
		return switch stream {
			case [{tok:Kwd(KwdEnum), pos:p}]: {flags: [], pos: p};
		}
	}

	function parseClassFlags() {
		return switch stream {
			case [{tok:Kwd(KwdClass), pos:p}]: {flags: [], pos: p};
			case [{tok:Kwd(KwdInterface), pos:p}]: {flags: aadd([],HInterface), pos: p};
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
							case [l = parseTypeAnonymous(false)]: TExtend([t],l);
							case [fl = parseClassFields(true, p1)]: TExtend([t], fl.fields);
							case _: unexpected();
						}
					case [l = parseClassFields(true, p1)]: TAnonymous(l.fields);
					case _: unexpected();
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
						case _: unexpected();
					}
				} else {
					var sub = switch stream {
						case [{tok:Dot}]:
							switch stream {
								case [{tok:Const(CIdent(name))} && !isLowerIdent(name)]: name;
								case _: unexpected();
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
			case _: unexpected();
		}
	}

	function parseComplexTypeNext(t:ComplexType) {
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

	function parseTypeAnonymous(opt:Bool):Array<Field> {
		return switch stream {
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
							case _: unexpected();
						}
					case _: unexpected();
				}
			case [{tok:Question} && !opt]: parseTypeAnonymous(true);
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
					case _: unexpected();
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

	function parseClassField():Field {
		doc = null;
		return switch stream {
			case [meta = parseMeta(), al = parseCfRights(true,[]), doc = getDoc()]:
				var data = switch stream {
					case [{tok:Kwd(KwdVar), pos:p1}, name = ident()]:
						switch stream {
							case [{tok:POpen}, i1 = propertyIdent(), {tok:Comma}, i2 = propertyIdent(), {tok:PClose}]:
								var t = switch stream {
									case [{tok:DblDot}, t = parseComplexType()]: t;
									case _: null;
								}
								var e = switch stream {
									case [{tok:Binop(OpAssign)}, e = toplevelExpr(), p2 = semicolon()]: { expr: e, pos: p2 };
									case [{tok:Semicolon, pos:p2}]: { expr: null, pos: p2 };
									case _: unexpected();
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
									case _: unexpected();
								}
								{
									name: name.name,
									pos: punion(p1,e.pos),
									kind: FVar(t,e.expr)
								}
						}
					case [{tok:Kwd(KwdFunction), pos:p1}, name = parseFunName(), pl = parseConstraintParams(), {tok:POpen}, al = psep(Comma, parseFunParam), {tok:PClose}, t = parseTypeOpt()]:
						var e = switch stream {
							case [e = toplevelExpr(), _ = semicolon()]:
								{ expr: e, pos: e.pos };
							case [{tok: Semicolon,pos:p}]:
								{ expr: null, pos: p}
							case _: unexpected();
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
							throw noMatch();
						else
							unexpected();
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

	function parseCfRights(allowStatic:Bool, l:Array<Access>) {
		return switch stream {
			case [{tok:Kwd(KwdStatic)} && allowStatic, l = parseCfRights(false, aadd(l, AStatic))]: l;
			case [{tok:Kwd(KwdMacro)} && !l.has(AMacro), l = parseCfRights(allowStatic, aadd(l, AMacro))]: l;
			case [{tok:Kwd(KwdPublic)} && !(l.has(APublic) || l.has(APrivate)), l = parseCfRights(allowStatic, aadd(l, APublic))]: l;
			case [{tok:Kwd(KwdPrivate)} && !(l.has(APublic) || l.has(APrivate)), l = parseCfRights(allowStatic, aadd(l, APrivate))]: l;
			case [{tok:Kwd(KwdOverride)} && !l.has(AOverride), l = parseCfRights(false, aadd(l, AOverride))]: l;
			case [{tok:Kwd(KwdDynamic)} && !l.has(ADynamic), l = parseCfRights(allowStatic, aadd(l, ADynamic))]: l;
			case [{tok:Kwd(KwdInline)}, l = parseCfRights(allowStatic, aadd(l, AInline))]: l;
			case _: l;
		}
	}

	function parseFunName() {
		return switch stream {
			case [{tok:Const(CIdent(name))}]: name;
			case [{tok:Kwd(KwdNew)}]: "new";
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
							case _: unexpected();
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
			case [{tok:Kwd(KwdExtends)}, t = parseTypePath()]: HExtends(t);
			case [{tok:Kwd(KwdImplements)}, t = parseTypePath()]: HImplements(t);
		}
	}

	function block1() {
		return switch stream {
			case [{tok:Const(CIdent(name)), pos:p}]: block2(name, CIdent(name), p);
			case [{tok:Const(CString(name)), pos:p}]: block2(quoteIdent(name), CString(name), p);
			case [b = block([])]: EBlock(b);
		}
	}

	function block2(name:String, ident:Constant, p:Position) {
		return switch stream {
			case [{tok:DblDot}, e = expr(), l = parseObjDecl()]: EObjectDecl(aadd(l, {field:name, expr:e}));
			case _:
				var e = exprNext({expr:EConst(ident), pos: p});
				var _ = semicolon();
				var b = block([e]);
				EBlock(b);
		}
	}

	function block(acc:Array<Expr>) {
		try {
			var e = parseBlockElt();
			return block(aadd(acc,e));
		} catch(e:hxparse.NoMatch<Dynamic>) {
			acc.reverse();
			return acc;
		}
	}

	function parseBlockElt() {
		return switch stream {
			case [{tok:Kwd(KwdVar), pos:p1}, vl = psep(Comma, parseVarDecl), p2 = semicolon()]: { expr: EVars(vl), pos:punion(p1,p2)};
			case [e = expr(), _ = semicolon()]: e;
		}
	}

	function parseObjDecl() {
		return switch stream {
			case [{tok:Comma}]:
				switch stream {
					case [id = ident(), {tok:DblDot}, e = expr(), l = parseObjDecl()]: aadd(l, {field:id.name, expr: e});
					case [{tok:Const(CString(name))}, {tok:DblDot}, e = expr(), l = parseObjDecl()]: aadd(l,{field:quoteIdent(name), expr: e});
					case _: [];
				}
			case _: [];
		}
	}

	function parseArrayDecl() {
		var acc = [];
		var br = false;
		while(true) {
			switch stream {
				case [e = expr()]:
					acc.push(e);
					switch stream {
						case [{tok: Comma}]:
						case _: br = true;
					}
				case _: br = true;
			}
			if (br) break;
		}
		return acc;
	}

	function parseVarDecl() {
		return switch stream {
			case [id = dollarIdent(), t = parseTypeOpt()]:
				switch stream {
					case [{tok:Binop(OpAssign)}, e = expr()]: { name: id.name, type: t, expr: e};
					case _: { name: id.name, type:t, expr: null};
				}
		}
	}

	function inlineFunction() {
		return switch stream {
			case [{tok:Kwd(KwdInline)}, {tok:Kwd(KwdFunction), pos:p1}]: { isInline: true, pos: p1};
			case [{tok:Kwd(KwdFunction), pos: p1}]: { isInline: false, pos: p1};
		}
	}

	function reify(inMacro:Bool) {
		// TODO
		return {
			toExpr: function(e) return null,
			toType: function(t,p) return null,
			toTypeDef: function(t) return null,
		}
	}
	
	function reifyExpr(e:Expr) {
		var toExpr = reify(inMacro).toExpr;
		var e = toExpr(e);
		return { expr: ECheckType(e, TPath( {pack:["haxe","macro"], name:"Expr", sub:null, params: []})), pos: e.pos};
	}

	function parseMacroExpr(p:Position) {
		return switch stream {
			case [{tok:DblDot}, t = parseComplexType()]:
				var toType = reify(inMacro).toType;
				var t = toType(t,p);
				{ expr: ECheckType(t, TPath( {pack:["haxe","macro"], name:"Expr", sub:"ComplexType", params: []})), pos: p};
			case [{tok:Kwd(KwdVar), pos:p1}, vl = psep(Comma, parseVarDecl)]:
				reifyExpr({expr:EVars(vl), pos:p1});
			case [{tok:BkOpen}, d = parseClass([],[],false)]:
				var toType = reify(inMacro).toTypeDef;
				{ expr: ECheckType(toType(d), TPath( {pack:["haxe","macro"], name:"Expr", sub:"TypeDefinition", params: []})), pos: p};
			case [e = secureExpr()]:
				reifyExpr(e);
		}
	}

	function expr():Expr {
		return switch stream {
			case [meta = parseMetaEntry()]:
				makeMeta(meta.name, meta.params, secureExpr(), meta.pos);
			case [{tok:BrOpen, pos:p1}, b = block1(), {tok:BrClose, pos:p2}]:
				var e = { expr: b, pos: punion(p1, p2)};
				switch(b) {
					case EObjectDecl(_): exprNext(e);
					case _: e;
				}
			case [{tok:Kwd(KwdMacro), pos:p}]:
				parseMacroExpr(p);
			case [{tok:Kwd(KwdVar), pos: p1}, v = parseVarDecl()]: { expr: EVars([v]), pos: p1};
			case [{tok:Const(c), pos:p}]: exprNext({expr:EConst(c), pos:p});
			case [{tok:Kwd(KwdThis), pos:p}]: exprNext({expr: EConst(CIdent("this")), pos:p});
			case [{tok:Kwd(KwdTrue), pos:p}]: exprNext({expr: EConst(CIdent("true")), pos:p});
			case [{tok:Kwd(KwdFalse), pos:p}]: exprNext({expr: EConst(CIdent("false")), pos:p});
			case [{tok:Kwd(KwdNull), pos:p}]: exprNext({expr: EConst(CIdent("null")), pos:p});
			case [{tok:Kwd(KwdCast), pos:p1}]:
				switch stream {
					case [{tok:POpen}, e = expr()]:
						switch stream {
							case [{tok:Comma}, t = parseComplexType(), {tok:PClose, pos:p2}]: exprNext({expr:ECast(e,t), pos: punion(p1,p2)});
							case [{tok:PClose, pos:p2}]: exprNext({expr:ECast(e,null),pos:punion(p1,p2)});
							case _: unexpected();
						}
					case [e = secureExpr()]: exprNext({expr:ECast(e,null), pos:punion(p1, e.pos)});
				}
			case [{tok:Kwd(KwdThrow), pos:p}, e = expr()]: { expr: EThrow(e), pos: p};
			case [{tok:Kwd(KwdNew), pos:p1}, t = parseTypePath(), {tok:POpen, pos:_}]:
				switch stream {
					case [al = psep(Comma, expr), {tok:PClose, pos:p2}]: exprNext({expr:ENew(t,al), pos:punion(p1, p2)});
					case _: unexpected();
				}
			case [{tok:POpen, pos: p1}, e = expr(), {tok:PClose, pos:p2}]: exprNext({expr:EParenthesis(e), pos:punion(p1, p2)});
			case [{tok:BkOpen, pos:p1}, l = parseArrayDecl(), {tok:BkClose, pos:p2}]: exprNext({expr: EArrayDecl(l), pos:punion(p1,p2)});
			case [inl = inlineFunction(), name = popt(dollarIdent), pl = parseConstraintParams(), {tok:POpen}, al = psep(Comma,parseFunParam), {tok:PClose}, t = parseTypeOpt()]:
				function make(e) {
					var f = {
						params: pl,
						ret: t,
						args: al,
						expr: e
					};
					return { expr: EFunction(name == null ? null : inl.isInline ? "inline_" + name.name : name.name, f), pos: punion(inl.pos, e.pos)};
				}
				exprNext(make(secureExpr()));
			case [{tok:Unop(op), pos:p1}, e = expr()]: makeUnop(op,e,p1);
			case [{tok:Binop(OpSub), pos:p1}, e = expr()]:
				function neg(s:String) {
					return s.charCodeAt(0) == '-'.code
						? s.substr(1)
						: s;
				}
				switch (makeUnop(OpNeg,e,p1)) {
					case {expr:EUnop(OpNeg,false,{expr:EConst(CInt(i))}), pos:p}:
						{expr:EConst(CInt(neg(i))), pos:p};
					case {expr:EUnop(OpNeg,false,{expr:EConst(CFloat(j))}), pos:p}:
						{expr:EConst(CFloat(neg(j))), pos:p};
					case _: e;
				}
			case [{tok:Kwd(KwdFor), pos:p}, {tok:POpen}, it = expr(), {tok:PClose}]:
				var e = secureExpr();
				{ expr: EFor(it,e), pos:punion(p, e.pos)};
			case [{tok:Kwd(KwdIf), pos:p}, {tok:POpen}, cond = expr(), {tok:PClose}, e1 = expr()]:
				var e2 = switch stream {
					case [{tok:Kwd(KwdElse)}, e2 = expr()]: e2;
					case _:
						switch [peek(0),peek(1)] {
							case [{tok:Semicolon}, {tok:Kwd(KwdElse)}]:
								junk();
								junk();
								secureExpr();
							case _: null;
						}
				}
				{ expr: EIf(cond,e1,e2), pos:punion(p, e2 == null ? e1.pos : e2.pos)};
			case [{tok:Kwd(KwdReturn), pos:p}, e = popt(expr)]: { expr: EReturn(e), pos: e == null ? p : punion(p,e.pos)};
			case [{tok:Kwd(KwdBreak), pos:p}]: { expr: EBreak, pos: p };
			case [{tok:Kwd(KwdContinue), pos:p}]: { expr: EContinue, pos: p};
			case [{tok:Kwd(KwdWhile), pos:p1}, {tok:POpen}, cond = expr(), {tok:PClose}]:
				var e = secureExpr();
				{ expr: EWhile(cond, e, true), pos: punion(p1, e.pos)};
			case [{tok:Kwd(KwdDo), pos:p1}, e = expr(), {tok:Kwd(KwdWhile)}, {tok:POpen}, cond = expr(), {tok:PClose}]: { expr: EWhile(cond,e,false), pos:punion(p1, e.pos)};
			case [{tok:Kwd(KwdSwitch), pos:p1}, e = expr(), {tok:BrOpen}, cases = parseSwitchCases(e,[]), {tok:BrClose, pos:p2}]:
				{ expr: ESwitch(e,cases.cases,cases.def), pos:punion(p1,p2)};
			case [{tok:Kwd(KwdTry), pos:p1}, e = expr(), cl = plist(parseCatch)]:
				{ expr: ETry(e,cl), pos:p1};
			case [{tok:IntInterval(i), pos:p1}, e2 = expr()]: makeBinop(OpInterval,{expr:EConst(CInt(i)), pos:p1}, e2);
			case [{tok:Kwd(KwdUntyped), pos:p1}, e = expr()]: { expr: EUntyped(e), pos:punion(p1,e.pos)};
			case [{tok:Dollar(v), pos:p}]: exprNext({expr:EConst(CIdent("$" + v)), pos:p});
		}
	}

	function toplevelExpr():Expr {
		return expr();
	}

	function exprNext(e1:Expr):Expr {
		return switch stream {
			case [{tok:Dot, pos:p}]:
				switch stream {
					case [{tok:Dollar(v), pos:p2}]:
						exprNext({expr:EField(e1, "$" + v), pos:punion(e1.pos, p2)});
					case [{tok:Const(CIdent(f)), pos:p2} && p.max == p2.min]:
						exprNext({expr:EField(e1,f), pos:punion(e1.pos,p2)});
					case [{tok:Kwd(KwdMacro), pos:p2} && p.max == p2.min]:
						exprNext({expr:EField(e1,"macro"), pos:punion(e1.pos,p2)});
					case _:
						switch(e1) {
							case {expr: EConst(CInt(v)), pos:p2} if (p2.max == p.min):
								exprNext({expr:EConst(CFloat(v + ".")), pos:punion(p,p2)});
							case _: unexpected();
						}
				}
			case [{tok:POpen, pos:_}]:
				switch stream {
					case [params = parseCallParams(), {tok:PClose, pos:p2}]:
						exprNext({expr:ECall(e1,params),pos:punion(e1.pos,p2)});
					case _: unexpected();
				}
			case [{tok:BkOpen}, e2 = expr(), {tok:BkClose, pos:p2}]:
				exprNext({expr:EArray(e1,e2), pos:punion(e1.pos,p2)});
			case [{tok:Binop(OpGt)}]:
				switch stream {
					case [{tok:Binop(OpGt)}]:
						switch stream {
							case [{tok:Binop(OpGt)}]:
								switch stream {
									case [{tok:Binop(OpAssign)}, e2 = expr()]:
										makeBinop(OpAssignOp(OpUShr),e1,e2);
									case [e2 = secureExpr()]: makeBinop(OpUShr,e1,e2);
								}
							case [{tok:Binop(OpAssign)}, e2 = expr()]:
								makeBinop(OpAssignOp(OpShr),e1,e2);
							case [e2 = secureExpr()]:
								makeBinop(OpShr,e1,e2);
						}
					case [{tok:Binop(OpAssign)}]:
						makeBinop(OpGte,e1,secureExpr());
					case [e2 = secureExpr()]:
						makeBinop(OpGt,e1,e2);
				}
			case [{tok:Binop(op)}, e2 = expr()]:
				makeBinop(op,e1,e2);
			case [{tok:Question}, e2 = expr(), {tok:DblDot}, e3 = expr()]:
				{ expr: ETernary(e1,e2,e3), pos: punion(e1.pos, e3.pos)};
			case [{tok:Kwd(KwdIn)}, e2 = expr()]:
				{expr:EIn(e1,e2), pos:punion(e1.pos, e2.pos)};
			case [{tok:Unop(op), pos:p} && isPostfix(e1,op)]:
				exprNext({expr:EUnop(op,true,e1), pos:punion(e1.pos, p)});
			case [{tok:BrOpen, pos:p1} && isDollarIdent(e1), eparam = expr(), {tok:BrClose,pos:p2}]:
				switch (e1.expr) {
					case EConst(CIdent(n)):
						exprNext({expr: EMeta({name:n, params:[], pos:e1.pos},eparam), pos:punion(p1,p2)});
					case _: throw false;
				}
			case _: e1;
		}
	}

	function parseGuard() {
		return switch stream {
			case [{tok:Kwd(KwdIf)}, {tok:POpen}, e = expr(), {tok:PClose}]:
				e;
		}
	}

	function parseSwitchCases(eswitch:Expr, cases:Array<Case>) {
		return switch stream {
			case [{tok:Kwd(KwdDefault), pos:p1}, {tok:DblDot}]:
				var b = block([]);
				var b = { expr: b.length == 0 ? null : EBlock(b), pos:p1 };
				var cl = parseSwitchCases(eswitch,cases);
				if (cl.def != null) {
					throw {
						msg: DuplicateDefault,
						pos: p1
					}
				}
				{ cases: cl.cases, def: b }
			case [{tok:Kwd(KwdCase), pos:p1}, el = psep(Comma,expr), eg = popt(parseGuard), {tok:DblDot}]:
				var b = block([]);
				var b = { expr: b.length == 0 ? null : EBlock(b), pos: p1};
				parseSwitchCases(eswitch, aadd(cases,{values:el,guard:eg,expr:b}));
			case _:
				cases.reverse();
				{ cases: cases, def: null};
		}
	}

	function parseCatch() {
		return switch stream {
			case [{tok:Kwd(KwdCatch), pos:p}, {tok:POpen}, id = ident(), ]:
				switch stream {
					case [{tok:DblDot}, t = parseComplexType(), {tok:PClose}]:
						{
							name: id.name,
							type: t,
							expr: secureExpr()
						}
					case _:
						throw {
							msg: MissingType,
							pos: p
						}
				}
		}
	}

	function parseCallParams() {
		var ret = [];
		switch stream {
			case [e = expr()]: ret.push(e);
			case _: return [];
		}
		while(true) {
			switch stream {
				case [{tok: Comma}, e = expr()]: ret.push(e);
				case _: break;
			}
		}
		return ret;
	}

	function secureExpr() {
		return expr();
	}
}