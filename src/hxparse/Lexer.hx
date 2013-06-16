package hxparse;
import hxparse.Types;

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

/**
	Lexer matches a sequence of characters against a set of rule patterns.
	
	An instance of Lexer is created once for each input and maintains state
	for that input. Tokens can then be obtained by calling the `token` method,
	passing an instance of `Ruleset`.
	
	Rule sets can be created manually, or by calling the static `buildRuleset`
	method.
**/
class Lexer {
	
	/**
		The `String` that was matched by the most recent invocation of the
		`token` method.
	**/
	public var current(default, null):String;
	
	var input:byte.ByteData;
	var source:String;
	var line:Int;
	var pos:Int;
	var carriage:Bool;
	var eof(default, null):Bool;
	
	/**
		Creates a new Lexer for `input`.
		
		If `sourceName` is provided, it is used in error messages to denote
		the position of an error.
		
		If `input` is null, the result is unspecified.
	**/
	public function new(input:byte.ByteData, sourceName:String = "<null>") {
		carriage = false;
		current = "";
		this.input = input;
		source = sourceName;
		line = 1;
		pos = 0;
		eof = false;
	}
	
	/**
		Returns the current position of `this` Lexer.
	**/
	public function curPos():Position {
		return new Position(source, line, pos - current.length, pos);
	}
	
	/**
		Returns the next token according to `ruleset`.
		
		This method starts with `ruleset.state` and reads characters from `this`
		input until no further state transitions are possible. It always returns
		the longest match.
		
		If a character is read which has no transition defined, an
		`UnexpectedChar` exception is thrown.
		
		If the input is in the end of file state upon method invocation,
		`ruleset.eofFunction` is called with `this` Lexer as argument. If
		`ruleset` defines no `eofFunction` field, a `haxe.io.Eof` exception
		is thrown.
		
		If `ruleset` is null, the result is unspecified.
	**/
	public function token<T>(ruleset:Ruleset<T>):T {
		if (eof) {
			if (ruleset.eofFunction != null) return ruleset.eofFunction(this);
			else throw new haxe.io.Eof();
		}
		var state = ruleset.state;
		var lastMatch = null;
		var lastMatchPos = pos;
		var start = pos;
		while(true) {
			if (state.final > -1) {
				lastMatch = state;
				lastMatchPos = pos;
			}
			if (pos == input.length) {
				eof = true;
				break;
			}
			var i = input.readByte(pos++);
			state = state.trans.get(i);
			if (state == null)
				break;
		}
		pos = lastMatchPos;
		current = input.readString(start, pos - start);
		if (lastMatch == null || lastMatch.final == -1)
			throw new UnexpectedChar(String.fromCharCode(input.readByte(pos)), curPos());
		return ruleset.functions[lastMatch.final](this);
	}
	
	/**
		Builds a `Ruleset` from the given `rules` `Array`.
		
		For each element of `rules`, its `rule` `String` is parsed into a
		`Pattern` using `LexEngine.parse`.
		
		If `rules` is null, the result is unspecified.
	**/
	static public function buildRuleset<Token>(rules:Array<{rule:String,func:Lexer->Token}>) {
		var cases = [];
		var functions = [];
		var eofFunction = null;
		for (rule in rules) {
			if (rule.rule == "") {
				eofFunction = rule.func;
			} else {
				cases.push(LexEngine.parse(rule.rule));
				functions.push(rule.func);
			}
		}
		return new Ruleset(new LexEngine(cases).firstState(),functions,eofFunction);
	}
}