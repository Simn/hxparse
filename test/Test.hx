import haxe.Resource;
import hxparse.NoMatch;
import hxparse.Unexpected;

class Test {
	
	static function main() {
		function run() {
			var i = byte.ByteData.ofString(Resource.getString('HaxeFile'));
			var parser = new HaxeParser(i, 'HaxeFile.hx');
			var data = try {
				parser.parse();
			} catch(e:NoMatch<Dynamic>) {
				trace(e.pos.format(i) + ": Unexpected " +e.token.tok);
				throw e;
			} catch(e:Unexpected<Dynamic>) {
				trace(e.pos.format(i) + ": Unexpected " + e.token.tok);
				throw e;
			}
			return data;
		}
		var r = haxe.Timer.measure(run);
		trace(r.pack);
		//trace(r.decls);
		
		var parser = new PrintfParser(byte.ByteData.ofString("Valu$$e: $-050.2f kg"));
		trace(parser.parse());
		
		var parser = new JSONParser(byte.ByteData.ofString('{ "key": [true, false, null], "other\tkey": [12, 12.1, 0, 0.1, 0.9e, 0.9E, 9E-] }'), "jsontest");
		trace(parser.parse());
	}
}