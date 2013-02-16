package hxparse;
import hxparse.Types;

class LexerStream<T> {

	public var ruleset:Ruleset<T>;
	var lexer:Lexer;
	var lookahead:T;
	
	public function new(lexer:Lexer, ruleset:Ruleset<T>) {
		this.lexer = lexer;
		this.ruleset = ruleset;
		lookahead = lexer.token(ruleset);
	}

	public inline function peek():Null<T> {
		if (lookahead == null)
			lookahead = lexer.token(ruleset);
		return lookahead;
	}
	
	public inline function junk():Void {
		lookahead = null;
	}
}