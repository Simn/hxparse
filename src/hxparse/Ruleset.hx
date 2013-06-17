package hxparse;

/**
	A Ruleset wraps an input state and the semantic callback functions for the
	`Lexer`.
**/
class Ruleset<Token> {
	
	/**
		The initial state.
	**/
	public var state:State;
	
	/**
		The semantic functions.
	**/
	public var functions:Array<Lexer->Token>;
	
	/**
		The callback function for when end of file state is reached.
	**/
	public var eofFunction:Lexer->Token;
	
	/**
		Creates a new Ruleset.
	**/
	public function new(state,functions,eofFunction) {
		this.state = state;
		this.functions = functions;
		this.eofFunction = eofFunction;
	}
}