package hxparse;
import hxparse.Types;

class LexerStream<T> {

	public var ruleset:Ruleset<T>;
	public var last(get, null):T;
	var lexer:Lexer;
	
	var offset = 0;
	var cache:Array<T>;
	
	public function new(lexer:Lexer, ruleset:Ruleset<T>) {
		this.lexer = lexer;
		this.ruleset = ruleset;
		cache = [];
	}

	public function peek(n = 0):Null<T> {
		var index = offset + n;
		while (cache[index] == null) {
			cache.push(lexer.token(ruleset));
		}
		return cache[index];
	}
	
	public inline function junk():Void {
		offset++;
	}
	
	function get_last() {
		return cache[offset - 1];
	}
}