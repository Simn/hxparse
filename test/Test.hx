class Test {
	
	static function main() {
		var path = Sys.args();
		if (path.length != 1)
			throw "Usage: neko hxparse.n [path to .hx file]";
		var i = sys.io.File.read(path[0], true);
		var parser = new HaxeParser(i, path[0]);
		parser.parse();
	}
}