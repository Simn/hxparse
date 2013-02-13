package hxparse;
typedef Charset = Array<{ min : Int, max : Int }>;

enum Pattern {
	Empty;
	Match( c : Charset );
	Star( p : Pattern );
	Plus( p : Pattern );
	Next( p1 : Pattern, p2 : Pattern );
	Choice( p1 : Pattern, p2 : Pattern );
}

class Node {
	public var id : Int;
	public var pid : Int;
	public var trans : Array<{ chars : Charset, n : Node }>;
	public var epsilon : Array<Node>;
	public function new(id, pid) {
		this.id = id;
		this.pid = pid;
		trans = [];
		epsilon = [];
	}
}

class Transition {
	public var chars : Charset;
	public function new(chars) {
		this.chars = chars;
	}
	public function toString() {
		return Std.string(chars);
	}
}

typedef StateTransition = haxe.ds.Vector<State>;

class State {
	public var trans : StateTransition;
	public var finals : Array<Node>;
	public function new() {
		finals = [];
		trans = new haxe.ds.Vector(256);
	}
}

class Ruleset<Token> {
	public var engine:LexEngine<Pattern>;
	public var functions:Array<Lexer->Token>;
	
	public function new(engine,functions) {
		this.engine = engine;
		this.functions = functions;
	}
}