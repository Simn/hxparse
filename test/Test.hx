import haxe.Resource;
class Test {
	
	static function main() {
		function run() {
			var i = new haxe.io.StringInput( Resource.getString('HaxeFile') );
			var parser = new HaxeParser(i, '/');
			return parser.parse();
		}
		var r = haxe.Timer.measure(run);
		trace(r.pack);
		trace(r.decls);
		
		var parser = new PrintfParser(new haxe.io.StringInput("Valu$$e: $-050.2f kg"));
		trace(parser.parse());
	}
}