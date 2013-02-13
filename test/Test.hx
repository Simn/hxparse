import hxparse.Lexer;
import haxe.macro.Expr;
import Data;

class Test {
	
	static function main() {
		var path = Sys.args();
		if (path.length != 1)
			throw "Usage: lextest [path]";
		var i = sys.io.File.read(path[0], true);
		var parser = new TestParser(i, path[0]);
		parser.parse();
	}
}