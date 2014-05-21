enum ArithmeticBinop {
	OpAdd;
	OpSub;
	OpMul;
	OpDiv;
}

enum ArithmeticToken {
	TNumber(f:Float);
	TPOpen;
	TPClose;
	TBinop(op:ArithmeticBinop);
	TEof;
}

enum ArithmeticExpr {
	ENumber(f:Float);
	EBinop(op:ArithmeticBinop, e1:ArithmeticExpr, e2:ArithmeticExpr);
	EParenthesis(e:ArithmeticExpr);
	ENeg(e:ArithmeticExpr);
}

class ArithmeticLexer extends hxparse.Lexer implements hxparse.RuleBuilder {
	static public var tok = @:rule [
		"[1-9][0-9]*" => TNumber(Std.parseFloat(lexer.current)), // lazy...
		"\\(" => TPOpen,
		"\\)" => TPClose,
		"\\+" => TBinop(OpAdd),
		"\\-" => TBinop(OpSub),
		"\\*" => TBinop(OpMul),
		"\\/" => TBinop(OpDiv),
		"[\r\n\t ]" => lexer.token(tok),
		"" => TEof
	];
}

class ArithmeticParser extends hxparse.Parser<hxparse.LexerTokenSource<ArithmeticToken>, ArithmeticToken> implements hxparse.ParserBuilder {
	public function parse() {
		return switch stream {
			case [TNumber(f)]:
				parseNext(ENumber(f));
			case [TPOpen, e = parse(), TPClose]:
				parseNext(EParenthesis(e));
			case [TBinop(OpSub), e = parse()]:
				parseNext(ENeg(e));
		}
	}

	function parseNext(e1:ArithmeticExpr) {
		return switch stream {
			case [TBinop(op), e2 = parse()]:
				binop(e1, op, e2);
			case _:
				e1;
		}
	}

	function binop(e1:ArithmeticExpr, op:ArithmeticBinop, e2:ArithmeticExpr) {
		return switch [e2, op] {
			case [EBinop(op2 = OpAdd | OpSub, e3, e4), OpMul | OpDiv]:
				// precedence
				EBinop(op2, EBinop(op, e1, e3), e4);
			case _:
				EBinop(op, e1, e2);
		}
	}
}

class ArithmeticEvaluator {
	static public function eval(e:ArithmeticExpr):Float {
		return switch(e) {
			case ENumber(f):
				f;
			case EBinop(op, e1, e2):
				switch(op) {
					case OpAdd:
						eval(e1) + eval(e2);
					case OpSub:
						eval(e1) - eval(e2);
					case OpMul:
						eval(e1) * eval(e2);
					case OpDiv:
						eval(e1) / eval(e2);
				}
			case EParenthesis(e1):
				eval(e1);
			case ENeg(e1):
				-eval(e1);
		}
	}
}