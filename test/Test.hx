class Test {
	
	static function main() {
		var testPath = "http://localhost:2000/TestClass.hx";
		var http = new haxe.Http(testPath);
		http.onData = function(data) {
			function run() {
				var i = new haxe.io.StringInput(data);
				var parser = new HaxeParser(i, testPath.substr(testPath.lastIndexOf("/")));
				return parser.parse();
			}
			var r = haxe.Timer.measure(run);
			trace(r.pack);
			trace(r.decls);
		}
		http.onError = function(e) {
			trace(e);
		}
		http.request(false);
		
		var parser = new PrintfParser(new haxe.io.StringInput("Valu$$e: $-050.2f kg"));
		trace(parser.parse());
	}
}