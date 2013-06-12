import haxe.macro.Expr;

enum Keyword {
	KwdFunction;
	KwdClass;
	KwdVar;
	KwdIf;
	KwdElse;
	KwdWhile;
	KwdDo;
	KwdFor;
	KwdBreak;
	KwdContinue;
	KwdReturn;
	KwdExtends;
	KwdImplements;
	KwdImport;
	KwdSwitch;
	KwdCase;
	KwdDefault;
	KwdStatic;
	KwdPublic;
	KwdPrivate;
	KwdTry;
	KwdCatch;
	KwdNew;
	KwdThis;
	KwdThrow;
	KwdExtern;
	KwdEnum;
	KwdIn;
	KwdInterface;
	KwdUntyped;
	KwdCast;
	KwdOverride;
	KwdTypedef;
	KwdDynamic;
	KwdPackage;
	KwdInline;
	KwdUsing;
	KwdNull;
	KwdTrue;
	KwdFalse;
	KwdAbstract;
	KwdMacro;
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
	IntInterval(s:String);
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
	Eof;
}

class Token {
	public var tok: TokenDef;
	public var pos: Position;
	
	public function new(tok, pos) {
		this.tok = tok;
		this.pos = pos;
	}
}

typedef EnumConstructor = {
	name : String,
	doc: String,
	meta: Metadata,
	args: Array<{ name: String, opt: Bool, type: ComplexType}>,
	pos: Position,
	params: Array<TypeParamDecl>,
	type: Null<ComplexType>
}

typedef Definition<A,B> = {
	name : String,
	doc: String,
	params: Array<TypeParamDecl>,
	meta: Metadata,
	flags: Array<A>,
	data: B
}

enum TypeDef {
	EClass(d:Definition<ClassFlag, Array<Field>>);
	EEnum(d:Definition<EnumFlag, Array<EnumConstructor>>);
	EImport(sl:Array<{pack:String, pos:Position}>, mode:ImportMode);
	ETypedef(d:Definition<EnumFlag, ComplexType>);
	EUsing(path:TypePath);
}

enum ClassFlag {
	HInterface;
	HExtern;
	HPrivate;
	HExtends(t:TypePath);
	HImplements(t:TypePath);
}

enum EnumFlag {
	EPrivate;
	EExtern;
}

enum ImportMode {
	INormal;
	IAsName(s:String);
	IAll;
}