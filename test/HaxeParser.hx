import Data;
using Lambda;

class HaxeParser extends hxparse.Parser<Token> {
	public function new(input:haxe.io.Input, sourceName:String) {
		super(new hxparse.LexerStream(new HaxeLexer(input, sourceName), HaxeLexer.tok));
	}
	
	public function parse() {
		parseFile();
	}
	
	inline function aadd<T>(a:Array<T>, t:T) {
		a.push(t);
		return a;
	}
	
	function psep<T>(t:TokenDef, f:Void->T) {
		var v = f();
		var ret = [];
		while (v != null) {
			ret.push(v);
			if (peek().tok != t)
				break;
			junk();
			v = f();
		}
		return ret;
	}

	function parseFile() {
		return switch stream {
			case [{tok:Kwd(Package)}, p = parsePackage(), {tok:Semicolon}, l = parseTypeDecls(p,[]), {tok:Eof}]:
				trace(l);
			case [l = parseTypeDecls([],[]), {tok:Eof}]:
				trace(l);
		}
	}
	
	function parsePackage() {
		return psep(Dot, lowerIdentOrMacro);
	}
	
	function parseTypeDecls(pack, acc:Array<TypeDef>) {
		return switch stream {
			case [ v = parseTypeDecl(), l = parseTypeDecls(pack,aadd(acc,v)) ]:
				l;
			case _: acc;
		}
	}
	
	function parseTypeDecl() {
		return switch stream {
			case [{tok:Kwd(Import), pos: p1}, i = parseImport(p1), {tok: Semicolon}]:
				EImport(i);
			case [c = parseCommonFlags()]:
				switch stream {
					case [flags = parseClassFlags(), name = typeName(), {tok:BrOpen}, fl = parseClassFields()]:
						EClass({
							name: name,
							doc: "",
							meta: [],
							params: [],
							flags: c.concat(flags.fst).array(),
							data: fl
						});
				}
		}
	}
	
	function parseImport(p1) {
		return parsePackage();
	}
	
	function parseCommonFlags():Array<ClassFlag> {
		return switch stream {
			case [{tok:Kwd(Private)}, l = parseCommonFlags()]: aadd(l, HPrivate);
			case [{tok:Kwd(Extern)}, l = parseCommonFlags()]: aadd(l, HExtern);
			case _: [];
		}
	}
	
	function parseClassFlags() {
		return switch stream {
			case [{tok:Kwd(Class), pos:p}]: {fst: [], snd: p};
			case [{tok:Kwd(Interface), pos:p}]: {fst: aadd([],HInterface), snd: p};
		}
	}
	
	function parseClassFields() {
		return switch stream {
			case [{tok: BrClose}]:
				[];
		}
	}
	
	function typeName() {
		return switch stream {
			case [{tok: Const(CIdent(name))}]: name;
		}
	}
	
	function lowerIdentOrMacro() {
		return switch stream {
			case [{tok:Const(CIdent(i))}]: i;
			case [{tok:Kwd(Macro)}]: "macro";
		}
	}
}