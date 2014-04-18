import hxparse.TokenSource.LexerTokenSource;

enum PToken {
	Eof;
	Placeholder;
	Dot;
	Number(i:Int);
	Literal(s:String);
	Flag(flag:PFlag);
	Value<C>(v:PValue<C>);
}

enum PFlag {
	Zero;
	Alt;
	Plus;
	Minus;
	Space;
}

enum PValue<T> {
	VInt:PValue<Int>;
	VString:PValue<String>;
	VBool:PValue<Bool>;
	VFloat:PValue<Float>;
}

enum Fmt<A,B> {
	Lit(s:String):Fmt<A,A>;
	Val<C>(v:PValue<C>):Fmt<A,C->A>;
	Cat<C>(a:Fmt<B,C>, b:Fmt<A,B>):Fmt<A,C>;
}

class PrintfLexer extends hxparse.Lexer implements hxparse.RuleBuilder {
	
	static public var tok = @:rule [
		"$" => Placeholder,
		"$$" => Literal(lexer.current),
		"[^$]+" => Literal(lexer.current),
		"" => Eof
	];
	
	static public var placeholder = @:rule [
		"0" => Flag(Zero),
		"#" => Flag(Alt),
		" " => Flag(Space),
		"+" => Flag(Plus),
		"-" => Flag(Minus),
		"[1-9][0-9]*" => Number(Std.parseInt(lexer.current)),
		"\\." => Dot,
		"i" => Value(VInt),
		"f" => Value(VFloat),
		"s" => Value(VString),
		"b" => Value(VBool),
	];
}

class PrintfParser extends hxparse.Parser<LexerTokenSource<PToken>, PToken> implements hxparse.ParserBuilder {
	public function new(input:byte.ByteData) {
		var lexer = new PrintfLexer(input);
		var ts = new LexerTokenSource(lexer, PrintfLexer.tok);
		super(ts);
	}
	
	public function parse() {
		var v:Fmt<Dynamic,Dynamic> = switch stream {
			case [Literal(s)]: Lit(s);
			case [Placeholder]:
				var current = stream.ruleset;
				stream.ruleset = PrintfLexer.placeholder;
				var r = parsePlaceholder();
				stream.ruleset = current;
				r;
			case [Eof]: null;
		}
		if (v == null) return null;
		var next = parse();
		return next == null ? v : Cat(v, next);
	}
	
	function parsePlaceholder() {
		var flags = parseFlags([]);
		var width = switch stream {
			case [Number(n)]: n;
			case _: -1;
		}
		var precision = switch stream {
			case [Dot, Number(n)]: n;
			case _: -1;
		}
		return switch stream {
			case [Value(v)]: Val(v); // we omit the config for simplicity reasons
			case _: unexpected();
		}
	}
	
	function parseFlags(acc:Array<PFlag>) {
		return switch stream {
			case [Flag(x)]:
				acc.push(x);
				parseFlags(acc);
			case _: acc;
		}
	}
}