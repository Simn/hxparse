package hxparse;

/**
	Parser is the base class for all custom parsers.
	
	The intended usage is to extend it and utilize its method as an API where
	required.
	
	All extending classes are automatically transformed using the
	`hxparse.ParserBuilder.build` macro.
 */
@:generic
class Parser<S:TokenSource<Token>, Token> {

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
	public var last:Token;
	
	var stream:S;
	var token:haxe.ds.GenericStack.GenericCell<Token>;
	
	/**
		Creates a new Parser instance over `TokenSource` `stream` with the
		initial `Ruleset` being `ruleset`.
	**/
	public function new(stream:S, ruleset:Ruleset<Token>) {
		this.stream = stream;
		this.ruleset = ruleset;
	}
	
	/**
		Returns the `n`th token without consuming it.
	**/
	@:doc
	function peek(n:Int):Token {
		if (token == null) {
			token = new haxe.ds.GenericStack.GenericCell<Token>(stream.token(ruleset), null);
			n--;
		}
		var tok = token;
		while (n > 0) {
			if (tok.next == null) tok.next = new haxe.ds.GenericStack.GenericCell<Token>(stream.token(ruleset), null);
			tok = tok.next;
			n--;
		}
		return tok.elt;
	}
	
	/**
		Consumes the current token.
		
		This method is automatically called after a successful match.
	**/
	@:doc
	inline function junk() {
		last = token.elt;
		token = token.next;
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
		return throw new Unexpected(peek(0), stream.curPos());
	}
}