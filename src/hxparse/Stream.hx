package hxparse;

typedef Stream<T> = {
	public function peek():Null<T>;
	public function junk():Void;
}