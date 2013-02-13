package hxparse;
import hxparse.Types;
import hxparse.Stream;

class LexerStream<T> implements Stream<T> {

	var lexer:Lexer;
	var buffer:Array<T>;
	var ruleset:Ruleset<T>;
	
	public function new(lexer:Lexer, ruleset:Ruleset<T>) {
		this.lexer = lexer;
		this.ruleset = ruleset;
		buffer = [];
	}

	public function peek():Null<T> {
		if (buffer.length == 0) {
			buffer.push(lexer.token(ruleset));
		}
		return buffer[0];
	}
	
	public function junk():Void {
		if (buffer.length > 0)
			buffer.shift();
		else
			lexer.token(ruleset);
	}
}