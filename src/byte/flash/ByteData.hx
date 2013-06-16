package byte.flash;

typedef NativeByteRepresentation = flash.utils.ByteArray;

abstract ByteData(NativeByteRepresentation) {
	
	public var length(get, never):Int;
	#if as3 public #end
	function get_length():Int return this.length;

	public var reader(get, never):LittleEndianReader;
	#if as3 public #end
	inline function get_reader():LittleEndianReader return new LittleEndianReader(new ByteData(this));

	public var writer(get, never):LittleEndianWriter;
	#if as3 public #end
	inline function get_writer():LittleEndianWriter return new LittleEndianWriter(new ByteData(this));
	
	public inline function new(data:NativeByteRepresentation) {
		this = data;
	}
		
	public inline function readByte(pos:Int):Int {
		return this[pos];
	}
	
	public inline function writeByte(pos:Int, v:Int):Void {
		this[pos] = v & 0xFF;
	}
	
	public function readString(pos:Int, len:Int):String {
		this.position = pos;
		return this.readUTFBytes(len);
	}
	
	static public function alloc(length:Int):ByteData {
		var b = new flash.utils.ByteArray();
		b.length = length;
		return new ByteData(b);
	}
		
	public static function ofString(s:String):ByteData {
		var b = new flash.utils.ByteArray();
		b.writeUTFBytes(s);
		return new ByteData(b);
	}
}