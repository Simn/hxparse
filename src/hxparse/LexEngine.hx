package hxparse;

/**
	LexEngine handles pattern parsing and state transformation.

	This class is used by the `Lexer` and rarely has to be interacted with
	directly.

	The static `parse` method transforms a single `String` to a `Pattern`.
	Multiple patterns can then be passed to the constructor to generate the
	state machine, which is obtainable from the `firstState` method.
**/
class LexEngine {

	var uid : Int;
	var nodes : Array<Node>;
	var finals : Array<Node>;
	var states : Array<State>;
	var hstates : Map<String,State>;

	/**
		Creates a new LexEngine from `patterns`.

		Each LexEngine maintains a state machine, whose initial state can be
		obtained from the `firstState` method. After this, `this` LexEngine can
		be discarded.

		If `patterns` is null, the result is unspecified.
	**/
	public function new( patterns : Array<Pattern> ) {
		nodes = [];
		finals = [];
		states = [];
		hstates = new Map();
		uid = 0;
		var pid = 0;
		for ( p in patterns ) {
			var id = pid++;
			var f = node(id);
			var n = initNode(p, f,id);
			nodes.push(n);
			finals.push(f);
		}
		makeState(addNodes([], nodes));
	}

	/**
		Returns the entry state of the state machine generated by `this`
		LexEngine.
	**/
	public function firstState() {
		return states[0];
	}

	function makeState( nodes : Array<Node> ) {
		var buf = new StringBuf();
		for( n in nodes ) {
			buf.add(n.id);
			buf.addChar("-".code);
		}
		var key = buf.toString();
		var s = hstates.get(key);
		if( s != null )
			return s;

		s = new State();
		states.push(s);
		hstates.set(key, s);

		var trans = getTransitions(nodes);

		for ( t in trans ) {
			var target = makeState(t.n);
			for (chr in t.chars) {
				for (i in chr.min...(chr.max + 1)) {
					s.trans.set(i, target);
				}
			}
		}

		function setFinal() {
			for( f in finals )
				for( n in nodes )
					if( n == f ) {
						s.final = n.pid;
						return;
					}
		}
		if (s.final == -1)
			setFinal();
		return s;
	}

	function getTransitions( nodes : Array<Node> ) {
		var tl = [];
		for( n in nodes )
			for( t in n.trans )
				tl.push(t);

		// Merge transition with the same target
		tl.sort(function(t1, t2) return t1.n.id - t2.n.id);
		var t0 = tl[0];
		for( i in 1...tl.length ) {
			var t1 = tl[i];
			if( t0.n == t1.n ) {
				tl[i - 1] = null;
				t1 = { chars : cunion(t0.chars, t1.chars), n : t1.n };
				tl[i] = t1;
			}
			t0 = t1;
		}
		while( tl.remove(null) ) {
		}

		// Split char sets to make them disjoint
		var allChars = EMPTY;
		var allStates = new List<{ chars : Charset, n : Array<Node> }>();
		for( t in tl ) {
			var states = new List();
			states.push( { chars : cdiff(t.chars, allChars), n : [t.n] } );
			for( s in allStates ) {
				var nodes = s.n.copy();
				nodes.push(t.n);
				states.push( { chars : cinter(s.chars,t.chars), n : nodes } );
				states.push( { chars : cdiff(s.chars, t.chars), n : s.n } );
			}
			for( s in states )
				if( s.chars.length == 0 )
					states.remove(s);
			allChars = cunion(allChars, t.chars);
			allStates = states;
		}

		// Epsilon closure of targets
		var states = [];
		for( s in allStates )
			states.push({ chars : s.chars, n : addNodes([], s.n) });

		// Canonical ordering
		states.sort(function(s1, s2) {
			var a = s1.chars.length;
			var b = s2.chars.length;
			for( i in 0...(a < b?a:b) ) {
				var a = s1.chars[i];
				var b = s2.chars[i];
				if( a.min != b.min )
					return b.min - a.min;
				if( a.max != b.max )
					return b.max - a.max;
			}
			if( a < b )
				return b - a;
			return 0;
		});
		return states;
	}

	function addNode( nodes : Array<Node>, n : Node ) {
		for( n2 in nodes )
			if( n == n2 )
				return;
		nodes.push(n);
		addNodes(nodes, n.epsilon);
	}

	function addNodes( nodes : Array<Node>, add : Array<Node> ) {
		for( n in add  )
			addNode(nodes, n);
		return nodes;
	}

	inline function node(pid) {
		return new Node(uid++, pid);
	}

	function initNode( p : Pattern, final : Node, pid : Int ) {
		return switch( p ) {
		case Empty:
			final;
		case Match(c):
			var n = node(pid);
			n.trans.push({ chars : c, n : final });
			n;
		case Star(p):
			var n = node(pid);
			var an = initNode(p,n,pid);
			n.epsilon.push(an);
			n.epsilon.push(final);
			n;
		case Plus(p):
			var n = node(pid);
			var an = initNode(p,n,pid);
			n.epsilon.push(an);
			n.epsilon.push(final);
			an;
		case Next(a,b):
			initNode(a, initNode(b, final,pid),pid);
		case Choice(a,b):
			var n = node(pid);
			n.epsilon.push(initNode(a,final,pid));
			n.epsilon.push(initNode(b,final,pid));
			n;
		case Group(p):
			initNode(p, final, pid);
		}
	}

	// ----------------------- PATTERN PARSING ---------------------------

	static inline var MAX_CODE = 255;
	static var EMPTY = [];
	static var ALL_CHARS = [ { min : 0, max : MAX_CODE } ];

	static inline function single( c : Int ) : Charset {
		return [ { min : c, max : c } ];
	}

	/**
		Parses the `pattern` `String` and returns an instance of `Pattern`.

		If `pattern` is not a valid pattern string, an exception of `String` is
		thrown.

		The following meta characters are supported:

			- `*`: zero or more
			- `+`: one or more
			- `?`: zero or one
			- `|`: or
			- `[`: begin char range
			- `]`: end char range
			- `(`: begin group
			- `)`: end group
			- `\`: escape next char

		These characters must be escaped if they are part of the pattern, by
		using `\\*`, `\\]` etc.
	**/
	public static function parse( pattern : String ) : Pattern {
		var p = parseInner(byte.ByteData.ofString(pattern));
		if( p == null ) throw "Invalid pattern '" + pattern + "'";
		return p.pattern;
	}

	static function next( a, b ) {
		return a == Empty ? b : Next(a, b);
	}

	static function plus(r) {
		return switch( r ) {
		case Next(r1, r2): Next(r1, plus(r2));
		default: Plus(r);
		}
	}

	static function star(r) {
		return switch( r ) {
		case Next(r1, r2): Next(r1, star(r2));
		default: Star(r);
		}
	}

	static function opt(r) {
		return switch( r ) {
		case Next(r1, r2): Next(r1, opt(r2));
		default: Choice(r, Empty);
		}
	}

	static function cinter(c1,c2) {
		return ccomplement(cunion(ccomplement(c1), ccomplement(c2)));
	}

	static function cdiff(c1,c2) {
		return ccomplement(cunion(ccomplement(c1), c2));
	}

	static function ccomplement( c : Charset ) {
		var first = c[0];
		var start = first != null && first.min == -1 ? c.shift().max + 1 : -1;
		var out = [];
		for( k in c ) {
			out.push( { min : start, max : k.min - 1 } );
			start = k.max + 1;
		}
		if( start <= MAX_CODE )
			out.push( { min : start, max : MAX_CODE } );
		return out;
	}

	static function cunion( ca : Charset, cb : Charset ) {
		var i = 0, j = 0;
		var out = [];
		var a = ca[i++], b = cb[j++];
		while( true ) {
			if( a == null ) {
				out.push(b);
				while( j < cb.length )
					out.push(cb[j++]);
				break;
			}
			if( b == null ) {
				out.push(a);
				while( i < ca.length )
					out.push(ca[i++]);
				break;
			}
			if( a.min <= b.min ) {
				if( a.max + 1 < b.min ) {
					out.push(a);
					a = ca[i++];
				} else if( a.max < b.max ) {
					b = { min : a.min, max : b.max };
					a = ca[i++];
				} else
					b = cb[j++];
			} else {
				// swap
				var tmp = ca;
				ca = cb;
				cb = tmp;
				var tmp = j;
				j = i;
				i = tmp;
				var tmp = a;
				a = b;
				b = tmp;
			}
		}
		return out;
	}

	static function parseInner( pattern : byte.ByteData, i : Int = 0, pDepth : Int = 0 ) : { pattern: Pattern, pos: Int } {
		function readChar() {
			var c = pattern.readByte(i++);
			if ( StringTools.isEof(c) ) c = '\\'.code;
			else if (c >= "0".code && c <= "9".code) {
				var v = c - 48;
				while(true) {
					var cNext = pattern.readByte(i);
					if (cNext >= "0".code && cNext <= "9".code) {
						v = v * 10 + (cNext - 48);
						++i;
					} else {
						break;
					}
				}
				c = v;
			}
			return c;
		}

		var r = Empty;
		var l = pattern.length;
		while( i < l ) {
			var c = pattern.readByte(i++);
			if (c > 255) throw c;
			switch( c ) {
			case '+'.code if (r != Empty):
				r = plus(r);
			case '*'.code if (r != Empty):
				r = star(r);
			case '?'.code if (r != Empty):
				r = opt(r);
			case '|'.code if (r != Empty):
				var r2 = parseInner(pattern, i);
				return {pattern: Choice(r, r2.pattern), pos: r2.pos};
			case '.'.code:
				r = next(r, Match(ALL_CHARS));
			case '('.code:
				var r2 = parseInner(pattern, i, pDepth + 1);
				i = r2.pos;
				r = next(r, r2.pattern);
			case ')'.code:
				if (r == Empty) throw "Empty group";
				return { pattern: Group(r), pos: i};
			case '['.code if (pattern.length > 1):
				var range = 0;
				var acc = [];
				var not = pattern.readByte(i) == '^'.code;
				if( not ) i++;
				while( true ) {
					var c = pattern.readByte(i++);
					if( c == ']'.code ) {
						if( range != 0 ) return null;
						break;
					} else if( c == '-'.code ) {
						if( range != 0 ) return null;
						var last = acc.pop();
						if( last == null )
							acc.push( { min : c, max : c } );
						else {
							if( last.min != last.max ) return null;
							range = last.min;
						}
					} else {
						if( c == '\\'.code ) {
							c = readChar();
						}
						if( range == 0 )
							acc.push( { min : c, max : c } );
						else {
							acc.push( { min : range, max : c } );
							range = 0;
						}
					}
				}
				var g = [];
				for( k in acc )
					g = cunion(g, [k]);
				if( not )
					g = cdiff(ALL_CHARS, g);
				r = next(r, Match(g));
			case '\\'.code:
				c = readChar();
				r = next(r, Match(single(c)));
			default:
				r = next(r, Match(single(c)));
			}
		}
		if (pDepth != 0) throw 'Found unclosed parenthesis while parsing "$pattern"';
		return {pattern:r, pos: i};
	}
}

private enum Pattern {
	Empty;
	Match( c : Charset );
	Star( p : Pattern );
	Plus( p : Pattern );
	Next( p1 : Pattern, p2 : Pattern );
	Choice( p1 : Pattern, p2 : Pattern );
	Group ( p : Pattern );
}

private typedef Charset = Array<{ min : Int, max : Int }>;

private class Node {
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

private class Transition {
	public var chars : Charset;
	public function new(chars) {
		this.chars = chars;
	}
	public function toString() {
		return Std.string(chars);
	}
}
