package byte.php;

private class Wrap {
	public var s:php.NativeString;
	public function new(s) {
		this.s = s;
	}
}

typedef NativeByteRepresentation = Wrap;

abstract ByteData(NativeByteRepresentation) {
	
	public var length(get, never):Int;
	function get_length():Int return untyped __call__("strlen", this.s);

	public var reader(get, never):LittleEndianReader;
	inline function get_reader():LittleEndianReader return new LittleEndianReader(new ByteData(this));

	public var writer(get, never):LittleEndianWriter;
	inline function get_writer():LittleEndianWriter return new LittleEndianWriter(new ByteData(this));
	
	public inline function new(data:NativeByteRepresentation) {
		this = data;
	}
		
	public function readByte(pos:Int):Int {
		return untyped __call__("ord", this.s[pos]);
	}
	
	public function writeByte( pos : Int, v : Int ) : Void {
		this.s[pos] = untyped __call__("chr",v);
	}
	
	public function readString(pos:Int, len:Int):String {
		return untyped __call__("substr", this.s, pos, len);
	}
	
	static public function alloc(length:Int):ByteData {
		return new ByteData(new Wrap(untyped __call__("str_repeat", __call__("chr", 0), length)));
	}
		
	static public function ofString(s:String):ByteData {
		return new ByteData(new Wrap(cast s));
	}
}