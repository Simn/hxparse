package byte.java;

typedef NativeByteRepresentation = java.NativeArray<java.StdTypes.Int8>;

abstract ByteData(NativeByteRepresentation) {
	
	public var length(get, never):Int;
	public function get_length():Int return this.length;

	public var reader(get, never):LittleEndianReader;
	inline function get_reader():LittleEndianReader return new LittleEndianReader(new ByteData(this));

	public var writer(get, never):LittleEndianWriter;
	inline function get_writer():LittleEndianWriter return new LittleEndianWriter(new ByteData(this));
	
	public inline function new(data:NativeByteRepresentation) {
		this = data;
	}
		
	public inline function readByte(pos:Int):Int {
		return untyped this[pos] & 0xFF;
	}
	
	public inline function writeByte(pos:Int, v:Int):Void {
		this[pos] = cast v;
	}
	
	public function readString(pos:Int, len:Int):String {
		return try new String(this, pos, len, "UTF-8") catch(e:Dynamic) null;
	}
	
	static public function alloc(length:Int):ByteData {
		return new ByteData(new java.NativeArray<java.StdTypes.Int8>(length));
	}
		
	public static function ofString(s:String):ByteData {
			var b = untyped try s.getBytes("UTF-8") catch(e:Dynamic) null;
			return new ByteData(b);
	}
}