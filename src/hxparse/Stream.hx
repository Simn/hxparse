package hxparse;

interface Stream<T> {
	public function peek():Null<T>;
	public function junk():Void;
}