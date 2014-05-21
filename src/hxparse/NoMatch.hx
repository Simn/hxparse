package hxparse;

/**
	A NoMatch exception is thrown if an outer token matching fails.

	Matching can continue because no tokens have been consumed.
**/
class NoMatch<T> {

	/**
		The position where no matching could be made.
	**/
	public var pos(default, null):Position;

	/**
		The token which was encountered and could not be matched.
	**/
	public var token(default, null):T;

	/**
		Creates a new NoMatch exception.
	**/
	public function new(pos:hxparse.Position, token:T) {
		this.pos = pos;
		this.token = token;
	}

	public function toString() {
		return '$pos: No match: $token';
	}
}