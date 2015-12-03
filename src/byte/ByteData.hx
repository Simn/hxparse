package byte;

abstract ByteData(haxe.io.Bytes) {

	public var length(get,never):Int;
	inline function get_length() return this.length;

	inline public function readByte(i:Int) return this.get(i);

	inline function new(data) {
		this = data;
	}

	static public function ofString(s:String):ByteData {
		var str = "";
		
		try {
			str = haxe.Utf8.decode(s);		
		} catch (e:Dynamic) {
			str = s;
		}
		
		return new ByteData(haxe.io.Bytes.ofString(str));
	}

	inline public function readString(pos:Int, len:Int) {
		return this.getString(pos, len);
	}
}
