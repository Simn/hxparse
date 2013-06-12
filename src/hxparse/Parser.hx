package hxparse;

import hxparse.Types;

/**
	Unexpected is thrown by `Parser.serror`, which is invoked when an inner
	token matching fails.
	
	Unlike `NoMatch`, this exception denotes that the stream is in an
	irrecoverable state because tokens have been consumed.
**/
class Unexpected<Token> {
	
	/**
		The token which was found.
	**/
	public var token:Token;
	
	/**
		The position in the input where `this` exception occured.
	**/
	public var pos:hxparse.Position;
	
	/**
		Creates a new instance of Unexpected.
	**/
	public function new(token:Token, pos) {
		this.token = token;
		this.pos = pos;
	}
	
	/**
		Returns a readable representation of `this` exception.
	**/
	public function toString() {
		return 'Unexpected $token at $pos';
	}
}

enum Either<S,T> {
	Left(v:S);
	Right(v:T);
}

/**
	A NoMatch exception is thrown if an outer token matching fails.
	
	Matching can continue because no tokens have been consumed.
**/
class NoMatch<T> {
	
	/**
		The position where no matching could be made.
	**/
	public var pos(default, null):Position;
	
	/**
		The token which was encountered and could not be matched.
	**/
	public var token(default, null):T;
	
	/**
		Creates a new NoMatch exception.
	**/
	public function new(pos:hxparse.Position, token:T) {
		this.pos = pos;
		this.token = token;
	}
	
	public function toString() {
		return '$pos: No match: $token';
	}
}

/**
	Parser is the base class for all custom parsers.
	
	The intended usage is to extend it and utilize its method as an API where
	required.
	
	All extending classes are automatically transformed using the
	`hxparse.ParserBuilder.build` macro.
 */
@:autoBuild(hxparse.ParserBuilder.build())
class Parser<Token> {

	/**
		The current `Ruleset`.
		
		This value is passed to the lexer when the `peek` method is invoked.
		Changing it during parsing can thus modify the tokenizing behavior
		of the lexer.
	**/
	public var ruleset:Ruleset<Token>;
	
	/**
		Returns the last matched token.
		
		This is a convenience property for accessing `cache[offset - 1]`.
	**/
	public var last(get, null):Token;
	
	var stream:Lexer;
	var offset = 0;
	var cache:Array<Token>;
	
	/**
		Creates a new Parser instance over `LexerStream` `stream`.
	**/
	public function new(lexer:Lexer, ruleset:Ruleset<Token>) {
		this.stream = lexer;
		this.ruleset = ruleset;
		cache = [];
	}
	
	/**
		Consumes the current token.
		
		This method is automatically called after a successful match.
	**/
	@:doc
	inline function junk() {
		offset++;
	}
	
	/**
		Returns the `n`th token without consuming it.
	**/
	@:doc
	function peek(n = 0):Token {
		var index = offset + n;
		while (cache[index] == null) {
			cache.push(stream.token(ruleset));
		}
		return cache[index];
	}
	
	/**
		Returns the current lexer position.
	**/
	public inline function curPos() {
		return stream.curPos();
	}
	
	function noMatch() {
		return new NoMatch(stream.curPos(), peek(0));
	}
	
	inline function unexpected():Dynamic {
		throw new Unexpected(peek(), stream.curPos());
		return null;
	}
		
	inline function get_last() {
		return cache[offset - 1];
	}
}