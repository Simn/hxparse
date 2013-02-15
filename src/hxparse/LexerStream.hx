package hxparse;
import hxparse.Types;

class LexerStream<T> {

	var lexer:Lexer;
	var lookahead:T;
	var ruleset:Ruleset<T>;
	
	public function new(lexer:Lexer, ruleset:Ruleset<T>) {
		this.lexer = lexer;
		this.ruleset = ruleset;
		lookahead = lexer.token(ruleset);
	}

	public inline function peek():Null<T> {
		return lookahead;
	}
	
	public inline function junk():Void {
		lookahead = lexer.token(ruleset);
	}
}