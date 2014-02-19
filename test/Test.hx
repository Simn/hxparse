import haxe.Resource;
import hxparse.NoMatch;
import hxparse.Unexpected;

class Test {
	
	static function main() {
		function run() {
			var i = byte.ByteData.ofString(Resource.getString('HaxeFile'));
			var parser = new HaxeParser(i, 'HaxeFile.hx');
			parser.define("js");
			parser.define("foo", 1.3);
			var data = try {
				parser.parse();
			} catch(e:NoMatch<Dynamic>) {
				throw e.pos.format(i) + ": Unexpected " +e.token.tok;
			} catch(e:Unexpected<Dynamic>) {
				throw e.pos.format(i) + ": Unexpected " + e.token.tok;
			}
			return data;
		}
		var r = haxe.Timer.measure(run);
		trace(r.decls);
		//trace(r.decls);
		
		var parser = new PrintfParser(byte.ByteData.ofString("Valu$$e: $-050.2f kg"));
		trace(parser.parse());
		
		var parser = new JSONParser(byte.ByteData.ofString('{ "key": [true, false, null], "other\tkey": [12, 12.1, 0, 0.1, 0.9e, 0.9E, 9E-] }'), "jsontest");
		trace(parser.parse());
	}
}