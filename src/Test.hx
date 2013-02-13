import hxparse.Lexer;
import haxe.macro.Expr;

enum TokenDef {
	Const(c:haxe.macro.Expr.Constant);
	Sharp(s:String);
	Dollar(s:String);
	Unop(op:haxe.macro.Expr.Unop);
	Binop(op:haxe.macro.Expr.Binop);
	Comment(s:String);
	CommentLine(s:String);
	Semicolon;
	Dot;
	DblDot;
	Arrow;
	Comma;
	BkOpen;
	BkClose;
	BrOpen;
	BrClose;
	POpen;
	PClose;
	Question;
	At;
}

typedef Token = {
	token: TokenDef,
	pos: hxparse.Lexer.Pos
}

/**
 * Lexer test file.
 * This comment is just here to test if it is lexed correctly.
 */
class Test implements hxparse.RuleBuilder {
	
	static function mk(lexer:Lexer, td) {
		return {
			token: td,
			pos: lexer.curPos()
		}
	}
	
	static var buf = new StringBuf();
	
	static var ident = "_*[a-z][a-zA-Z0-9_]*";
	static var idtype = "_*[A-Z][a-zA-Z0-9_]*";
	
	static var token = @:rule [
		"[\r\n\t ]" => lexer.token(token),
		"0x[0-9a-fA-F]+" => mk(lexer, Const(CInt(lexer.current))),
		"[0-9]+" => mk(lexer, Const(CInt(lexer.current))),
		"[0-9]+.[0-9]+" => mk(lexer, Const(CFloat(lexer.current))),
		"//[^\n\r]*" => mk(lexer, CommentLine(lexer.current.substr(2))),
		"\\+\\+" => mk(lexer,Unop(OpIncrement)),
		"--" => mk(lexer,Unop(OpDecrement)),
		"~" => mk(lexer,Unop(OpNegBits)),
		"%=" => mk(lexer,Binop(OpAssignOp(OpMod))),
		"&=" => mk(lexer,Binop(OpAssignOp(OpAnd))),
		"|=" => mk(lexer,Binop(OpAssignOp(OpOr))),
		"^=" => mk(lexer,Binop(OpAssignOp(OpXor))),
		"\\+=" => mk(lexer,Binop(OpAssignOp(OpAdd))),
		"-=" => mk(lexer,Binop(OpAssignOp(OpSub))),
		"\\*=" => mk(lexer,Binop(OpAssignOp(OpMult))),
		"/=" => mk(lexer,Binop(OpAssignOp(OpDiv))),
		"==" => mk(lexer,Binop(OpEq)),
		"!=" => mk(lexer,Binop(OpNotEq)),
		"<=" => mk(lexer,Binop(OpLte)),
		"&&" => mk(lexer,Binop(OpBoolAnd)),
		"||" => mk(lexer,Binop(OpBoolOr)),
		"<<" => mk(lexer,Binop(OpShl)),
		"->" => mk(lexer,Arrow),
		"..." => mk(lexer,Binop(OpInterval)),
		"=>" => mk(lexer,Binop(OpArrow)),
		"!" => mk(lexer,Unop(OpNot)),
		"<" => mk(lexer,Binop(OpLt)),
		">" => mk(lexer,Binop(OpGt)),
		";" => mk(lexer, Semicolon),
		":" => mk(lexer, DblDot),
		"," => mk(lexer, Comma),
		"." => mk(lexer, Dot),
		"%" => mk(lexer,Binop(OpMod)),
		"&" => mk(lexer,Binop(OpAnd)),
		"|" => mk(lexer,Binop(OpOr)),
		"^" => mk(lexer,Binop(OpXor)),
		"\\+" => mk(lexer,Binop(OpAdd)),
		"\\*" => mk(lexer,Binop(OpMult)),
		"/" => mk(lexer,Binop(OpDiv)),
		"-" => mk(lexer,Binop(OpSub)),
		"=" => mk(lexer,Binop(OpAssign)),
		"\\[" => mk(lexer, BkOpen),
		"\\]" => mk(lexer, BkClose),
		"{" => mk(lexer, BrOpen),
		"}" => mk(lexer, BrClose),
		"(" => mk(lexer, POpen),
		")" => mk(lexer, PClose),
		"\\?" => mk(lexer, Question),
		"@" => mk(lexer, At),
		'"' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = lexer.token(string);
			mk(lexer, Const(CString(buf.toString())));
		},
		"'" => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = lexer.token(string2);
			mk(lexer, Const(CString(buf.toString())));
		},
		'/\\*' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = lexer.token(comment);
			mk(lexer, Comment(buf.toString()));
		},
		"#" + ident => mk(lexer, Sharp(lexer.current.substr(1))),
		"$" + ident => mk(lexer, Dollar(lexer.current.substr(1))),
		ident => mk(lexer, Const(CIdent(lexer.current))),
		idtype => mk(lexer, Const(CIdent(lexer.current))),
	];
	
	static var string = @:rule [
		"\\\\\\\\" => {
			buf.add("\\");
			lexer.token(string);
		},
		"\\\\n" => {
			buf.add("\n");
			lexer.token(string);
		},
		"\\\\r" => {
			buf.add("\r");
			lexer.token(string);
		},
		"\\\\t" => {
			buf.add("\t");
			lexer.token(string);
		},
		"\\\\\"" => {
			buf.add('"');
			lexer.token(string);
		},
		'"' => lexer.curPos().pmax,
		"[^\\\\\"]+" => {
			buf.add(lexer.current);
			lexer.token(string);
		}
	];
	
	static var string2 = @:rule [
		"\\\\\\\\" => {
			buf.add("\\");
			lexer.token(string2);
		},
		"\\\\n" =>  {
			buf.add("\n");
			lexer.token(string2);
		},
		"\\\\r" => {
			buf.add("\r");
			lexer.token(string2);
		},
		"\\\\t" => {
			buf.add("\t");
			lexer.token(string2);
		},
		'\\\\\'' => {
			buf.add('"');
			lexer.token(string2);
		},
		"'" => lexer.curPos().pmax,
		'[^\\\\\']+' => {
			buf.add(lexer.current);
			lexer.token(string2);
		}
	];
	
	static var comment = @:rule [
		"\\*/" => lexer.curPos().pmax,
		"\\*" => {
			buf.add("*");
			lexer.token(comment);
		},
		"[^\\*]" => {
			buf.add(lexer.current);
			lexer.token(comment);
		}
	];
	
	static function main() {
		var path = Sys.args();
		if (path.length != 1)
			throw "Usage: lextest [path]";
		var i = sys.io.File.read(path[0], true);
		var lexer = new Lexer(i, path[0]);
		var buf = new StringBuf();
		try {
			while (true) {
				buf.add(lexer.token(token).token + "\n");
			}
		} catch (e:String) {
			var c = lexer.char();
			// c == null is Eof (I hope)
			if (c != null) {
				throw "Unexpected " +String.fromCharCode(c) + (lexer.curPos());
			}
		}
		Sys.print(buf.toString());
	}
}