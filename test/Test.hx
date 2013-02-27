class Test {
	
	static function main() {
		var testPath = "http://localhost:2000/TestClass.hx";
		var http = new haxe.Http(testPath);
		http.onData = function(data) {
			function run() {
				var i = new haxe.io.StringInput(data);
				var parser = new HaxeParser(i, testPath.substr(testPath.lastIndexOf("/")));
				parser.parse();
			}
			haxe.Timer.measure(run);
		}
		http.onError = function(e) {
			trace(e);
		}
		http.request(false);
	}
	
}