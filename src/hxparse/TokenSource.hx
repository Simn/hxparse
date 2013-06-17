package hxparse;

/**
	Defines the structure of a type usable as input for a `Parser`.
**/
typedef TokenSource<Token> = {
	
	/**
		Returns the next token according to the rules of `Ruleset` `r`.
	**/
	function token(r:Ruleset<Token>):Token;
	
	/**
		Returns the current `Position` of `this` TokenSource.
	**/
	function curPos():Position;
}
