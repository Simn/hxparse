import hxparse.TokenSource.LexerTokenSource;

private enum Token {
	TBrOpen;
	TBrClose;
	TComma;
	TDblDot;
	TBkOpen;
	TBkClose;
	TDash;
	TDot;
	TTrue;
	TFalse;
	TNull;
	TNumber(v:String);
	TString(v:String);
	TEof;
}

class JSONLexer extends hxparse.Lexer implements hxparse.RuleBuilder {

	static var buf:StringBuf;
		
	public static var tok = @:rule [
		"{" => TBrOpen,
		"}" => TBrClose,
		"," => TComma,
		":" => TDblDot,
		"[" => TBkOpen,
		"]" => TBkClose,
		"-" => TDash,
		"\\." => TDot,
		"true" => TTrue,
		"false" => TFalse,
		"null" => TNull,
		"-?(([1-9][0-9]*)|0)(.[0-9]+)?([eE][\\+\\-]?[0-9]?)?" => TNumber(lexer.current),
		'"' => {
			buf = new StringBuf();
			lexer.token(string);
			TString(buf.toString());
		},
		"[\r\n\t ]" => lexer.token(tok),
		"" => TEof
	];
	
	static var string = @:rule [
		"\\\\t" => {
			buf.addChar("\t".code);
			lexer.token(string);
		},
		"\\\\n" => {
			buf.addChar("\n".code);
			lexer.token(string);
		},
		"\\\\r" => {
			buf.addChar("\r".code);
			lexer.token(string);
		},
		'\\\\"' => {
			buf.addChar('"'.code);
			lexer.token(string);
		},
		"\\\\u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]" => {
			buf.add(String.fromCharCode(Std.parseInt("0x" +lexer.current.substr(2))));
			lexer.token(string);
		},
		'"' => {
			lexer.curPos().pmax;
		},
		'[^"]' => {
			buf.add(lexer.current);
			lexer.token(string);
		},
	];
}

class JSONParser extends hxparse.Parser<LexerTokenSource<Token>, Token> implements hxparse.ParserBuilder {
	public function new(input:byte.ByteData, sourceName:String) {
		var lexer = new JSONLexer(input, sourceName);
		var ts = new LexerTokenSource(lexer, JSONLexer.tok);
		super(ts);
	}
		
	public function parse():Dynamic {
		return switch stream {
			case [TBrOpen, obj = object({})]: obj;
			case [TBkOpen, arr = array([])]: arr;
			case [TNumber(s)]: s;
			case [TTrue]: true;
			case [TFalse]: false;
			case [TNull]: null;
			case [TString(s)]: s;
		}
	}
	
	function object(obj:{}) {
		return switch stream {
			case [TBrClose]: obj;
			case [TString(s), TDblDot, e = parse()]:
				Reflect.setField(obj, s, e);
				switch stream {
					case [TBrClose]: obj;
					case [TComma]: object(obj);
				}
		}
	}

	function array(acc:Array<Dynamic>) {
		return switch stream {
			case [TBkClose]: acc;
			case [elt = parse()]:
				acc.push(elt);
				switch stream {
					case [TBkClose]: acc;
					case [TComma]: array(acc);
				}
		}
	}
}