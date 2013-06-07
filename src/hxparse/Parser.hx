package hxparse;

class Unexpected<Token> {
	public var token:Token;
	public var pos:hxparse.Lexer.Pos;
	public function new(token:Token, pos) {
		this.token = token;
		this.pos = pos;
	}
	
	public function toString() {
		return 'Unexpected $token at $pos';
	}
}

enum Either<S,T> {
	Left(v:S);
	Right(v:T);
}

class NoMatch {
	public function new() { }
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
		Creates a new Parser instance over `LexerStream` `stream.
	**/
	public function new(stream:LexerStream<Token>) {
		this.stream = stream;
	}
	
	inline function junk() {
		stream.junk();
	}
	
	function peek(n = 0):Token {
		return stream.peek(n);
	}
	
	inline function unexpected(t:Token):Dynamic {
		throw new Unexpected(t, stream.curPos());
		return null;
	}
	
	inline function serror():Dynamic {
		throw new Unexpected(peek(), stream.curPos());
		return null;
	}
}