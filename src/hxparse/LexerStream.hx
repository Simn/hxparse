package hxparse;
import hxparse.Types;

/**
	LexerStream is the connecting class between `Lexer` and `Parser`.
	
	It maintains a `Ruleset` state which can be modified by the parser to
	influence tokenizing behavior of the lexer.
**/
class LexerStream<T> {

	/**
		The current `Ruleset`.
		
		This value is passed to the lexer when the `peek` method is invoked.
		Changing it during parsing can thus modify the tokenizing behavior
		of the lexer.
	**/
	public var ruleset:Ruleset<T>;
	
	/**
		Returns the last matched token.
		
		This is a convenience property for accessing `cache[offset - 1]`.
	**/
	public var last(get, null):T;
	
	var lexer:Lexer;
	var offset = 0;
	var cache:Array<T>;
	
	/**
		Creates a new LexerStream instance over `Lexer` `lexer`, with the
		initial `Ruleset` being `ruleset`.
	**/
	public function new(lexer:Lexer, ruleset:Ruleset<T>) {
		this.lexer = lexer;
		this.ruleset = ruleset;
		cache = [];
	}

	/**
		Returns the `n`th token, counting from the current position.
		
		This method fills the internal cache until enough tokens are available,
		using `this.ruleset` as an argument to `Lexer.token`.
		
		If `n` is less than 0, the result is unspecified.
	**/
	public function peek(n = 0):Null<T> {
		var index = offset + n;
		while (cache[index] == null) {
			cache.push(lexer.token(ruleset));
		}
		return cache[index];
	}
	
	/**
		Junks one token by increasing the offset.
	**/
	public inline function junk():Void {
		offset++;
	}

	/**
		Returns the current lexer position.
	**/
	public inline function curPos() {
		return lexer.curPos();
	}
	
	inline function get_last() {
		return cache[offset - 1];
	}
}