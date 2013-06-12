package hxparse;

/**
	The position information maintained by `Lexer`.
**/
class Position {
	/**
		Name of the source.
	**/
	public var psource : String;
	
	/**
		The line number.
	**/
	public var pline : Int;
	
	/**
		The first character position, counting from the beginning of the input.
	**/
	public var pmin : Int;
	
	/**
		The last character position, counting from the beginning of the input.
	**/
	public var pmax : Int;
	
	/**
		Creates a new `Position` from the given information.
	**/
	public function new(source, line, min, max) {
		psource = source;
		pline = line;
		pmin = min;
		pmax = max;
	}
	
	/**
		Unifies two positions `p1` and `p2`, using the minimum `pmin` and
		maximum `pmax` of both.
		
		The resulting `psource` and `pline` are taken from `p1`.
		
		If `p1` or `p2` are null, the result is unspecified.
	**/
	static public function union(p1:Position, p2:Position) {
		return new Position(p1.psource, p1.pline, p1.pmin < p2.pmin ? p1.pmin : p2.pmin, p1.pmax > p2.pmax ? p1.pmax : p2.pmax);
	}
}