package hxparse;

/**
	Defines the structure of a type usable as input for a `Parser`.
**/
typedef TokenSource<Token> = {
	
	/**
		Returns the next token according to the rules of `Ruleset` `r`.
	**/
	function token():Token;
	
	/**
		Returns the current `Position` of `this` TokenSource.
	**/
	function curPos():Position;
}

class LexerTokenSource<Token> {
	var lexer:Lexer;
	public var ruleset:Ruleset<Token>;

	public function new(lexer, ruleset){
		this.lexer = lexer;
		this.ruleset = ruleset;
	}

	public function token():Token{
		return lexer.token(ruleset);
	}

	public function curPos():Position{
		return lexer.curPos();
	}
}
