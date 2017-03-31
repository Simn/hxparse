class Test {
	static function main() {

		var t0 = haxe.Timer.stamp();

		var parser = new PrintfParser(byte.ByteData.ofString("Valu$$e: $-050.2f kg"));
		trace(parser.parse());

		var parser = new JSONParser(byte.ByteData.ofString('{ "key": [true, false, null], "other\tkey": [12, 12.1, 0, 0.1, 0.9e1, 0.9E1, 9E-1] }'), "jsontest");
		trace(parser.parseJson());

		// Using haxe.Utf8
		var value = 'hello âê€𩸽ùあ𠀀ÊÀÁÂÃÄÅÆÇÈÉËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáãäåæçèéëìíîïðñòóôõöøúûüýþÿ№ unicode';
		var lexer = new UnicodeTestLexer( byte.ByteData.ofString( value ), 'uft8-test' );
		var tokens = [];

		try while (true) {
			tokens.push( lexer.token( UnicodeTestLexer.root ) );
		} catch (_e:Dynamic) {
			trace(_e);
		}
		trace( tokens );

		var numTests = 0;
		function eq(expected:Float, s:String) {
			++numTests;
			var lexer = new ArithmeticParser.ArithmeticLexer(byte.ByteData.ofString(s));
			var ts = new hxparse.LexerTokenSource(lexer, ArithmeticParser.ArithmeticLexer.tok);
			var parser = new ArithmeticParser(ts);
			var result = ArithmeticParser.ArithmeticEvaluator.eval(parser.parse());
			if (expected != result) {
				trace('Error in "$s"; expected $expected but was $result');
			}
		}
		eq(1, "1");
		eq(2, "1 + 1");
		eq(6, "2 * 3");
		eq(2, "6 / 3");
		eq(1.5, "3 / 2");
		eq(10, "2 * 3 + 4");
		eq(14, "2 * (3 + 4)");
		eq(18, "9 + (3 * 4) - 3 / (1 * 1)");
		eq(-9, "-9");
		eq(-12, "-(4 + 8)");
		eq(12, "--12");
		eq(8, "2*(3-(2+(-3)))");

		var diff = haxe.Timer.stamp() - t0;
		trace('Done $numTests tests in $diff ms');
	}
}
