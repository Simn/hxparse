package hxparse;

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
	var stream:LexerStream<Token>;

	/**
		Creates a new Parser instance over `LexerStream` `stream`.
	**/
	public function new(stream:LexerStream<Token>) {
		this.stream = stream;
	}
	
	/**
		Consumes the current token.
		
		This method is automatically called after a successful match.
	**/
	@:doc
	inline function junk() {
		stream.junk();
	}
	
	/**
		Returns the `n`th token without consuming it.
	**/
	@:doc
	function peek(n = 0):Token {
		return stream.peek(n);
	}
	
	function noMatch() {
		return new NoMatch(stream.curPos(), stream.peek(0));
	}
	
	inline function unexpected():Dynamic {
		throw new Unexpected(peek(), stream.curPos());
		return null;
	}
}