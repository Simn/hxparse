package hxparse;

class Unexpected<Token> {
	public var token:Token;
	public var msg:String;
	public function new(token:Token, ?msg:String) {
		this.token = token;
		this.msg = msg;
	}
}

@:autoBuild(hxparse.ParserBuilder.build())
class Parser<Token> {
	var stream:Stream<Token>;
	
	public function new(stream:Stream<Token>) {
		this.stream = stream;
	}
	
	inline function junk() {
		stream.junk();
	}
	
	inline function peek():Token {
		return stream.peek();
	}
	
	inline function unexpected(t:Token):Dynamic {
		throw new Unexpected(t);
		return null;
	}
}