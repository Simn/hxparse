import Data;

class TestParser {
	
	var stream:hxparse.LexerStream<Token>;
	
	public function new(input:haxe.io.Input, sourceName:String) {
		stream = new hxparse.LexerStream(new TestLexer(input, sourceName), TestLexer.tok);
	}
	
	public function parse() {
		try {
			while (true) {
				trace(stream.peek().token);
				stream.junk();
			}
		} catch (_:haxe.io.Eof) {
			
		}
	}
	
}