enum Keyword {
	Function;
	Class;
	Var;
	If;
	Else;
	While;
	Do;
	For;
	Break;
	Continue;
	Return;
	Extends;
	Implements;
	Import;
	Switch;
	Case;
	Default;
	Static;
	Public;
	Private;
	Try;
	Catch;
	New;
	This;
	Throw;
	Extern;
	Enum;
	In;
	Interface;
	Untyped;
	Cast;
	Override;
	Typedef;
	Dynamic;
	Package;
	Inline;
	Using;
	Null;
	True;
	False;
	Abstract;
	Macro;
}

enum TokenDef {
	Kwd(k:Keyword);
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