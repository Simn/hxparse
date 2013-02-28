package hxparse;

class Unexpected<Token> {
	public var token:Token;
	public var msg:String;
	public function new(token:Token, ?msg:String) {
		this.token = token;
		this.msg = msg;
	}
	
	public function toString() {
		return 'Unexpected $token';
	}
}

class NoMatch {
	public function new() { }
}

@:autoBuild(hxparse.ParserBuilder.build())
class Parser<Token> {
	var stream:LexerStream<Token>;

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
		throw new Unexpected(t);
		return null;
	}
	
	inline function serror():Dynamic {
		throw new Unexpected(peek());
		return null;
	}
}