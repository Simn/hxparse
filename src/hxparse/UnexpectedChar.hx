package hxparse;

/**
	UnexpectedChar is thrown by `Lexer.token` if it encounters a character for
	which no state transition is defined.
**/
class UnexpectedChar {

	/**
		The character which caused `this` exception.
	**/
	public var char:String;

	/**
		The position in the input where `this` exception occured.
	**/
	public var pos:Position;

	/**
		Creates a new instance of UnexpectedChar.
	**/
	public function new(char, pos) {
		this.char = char;
		this.pos = pos;
	}

	/**
		Returns a readable representation of `this` exception.
	**/
	public function toString() {
		return '$pos: Unexpected $char';
	}
}