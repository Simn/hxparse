package;
import foo.bar.bomb;
import foo2.bar2.bomb2;

enum MyEnum {
	Mega;
	Blub(s:String);
}

@:myMeta("foo")
extern class HelloWorld {
	public function test();
	public function test2(s:String) {
		var exp = ~/.+/g;
		#if (true && js)
		trace("true");
		#else
		trace("false");
		#end
		trace("foo");
		var x = 1 + 3;
	}
}