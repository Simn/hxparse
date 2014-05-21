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
	public var pos:Position;

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