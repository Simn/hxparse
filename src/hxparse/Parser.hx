package hxparse;

/**
	Parser is the base class for all custom parsers.
	
	The intended usage is to extend it and utilize its method as an API where
	required.
 */
@:generic
class Parser<S:TokenSource<Token>, Token> {

	/**
		The current `Ruleset`.
		
		This value is passed to the lexer when the `peek` method is invoked.
		Changing it during parsing can thus modify the tokenizing behavior
		of the lexer.
	**/
	public var ruleset(default, null):Ruleset<Token>;
	
	/**
		Returns the last matched token.
		
		This is a convenience property for accessing `cache[offset - 1]`.
	**/
	public var last(default, null):Token;
	
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
	@:doc
	public inline function curPos() {
		return stream.curPos();
	}
	
	/**
		Invokes `f` and then `separatorFunc` with the current token until the
		result of that call is `false`.
		
		The result is an Array containing the results of all calls to `f`.
		
		A typical use case is parsing function arguments which are separated by
		a comma.
	 */
	@:doc
	function parseSeparated<T>(separatorFunc:Token->Bool, f:Void->T):Array<T> {
		var acc = [];
		while(true) {
			acc.push(f());
			if (separatorFunc(peek(0))) {
				junk();
			} else {
				break;
			}
		}
		return acc;
	}
	
	/**
		Returns the result of calling `f()` if a match is made, or `null`
		otherwise`.
	**/
	@:doc
	function parseOptional<T>(f:Void->T) {
		try {
			return f();
		} catch(e:hxparse.NoMatch<Dynamic>) {
			return null;
		}
	}
	
	/**
		Calls `f` until no match can be made.
		
		The result is an Array containing the results of all calls to `f`.
	**/
	@:doc
	function parseRepeat<T>(f:Void->T) {
		var acc = [];
		while(true) {
			try {
				acc.push(f());
			} catch(e:hxparse.NoMatch<Dynamic>) {
				return acc;
			}
		}
	}
	
	inline function noMatch() {
		return new NoMatch(stream.curPos(), peek(0));
	}
	
	inline function unexpected():Dynamic {
		return throw new Unexpected(peek(0), stream.curPos());
	}
}