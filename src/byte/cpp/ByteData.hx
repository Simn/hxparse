package byte.cpp;

@:native("haxe.io.Unsigned_char__")
extern class Unsigned_char__ { }

typedef NativeByteRepresentation = Array<Unsigned_char__>;

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
		return untyped this[pos];
	}
	
	public inline function writeByte(pos:Int, v:Int):Void {
		untyped this[pos] = v;
	}
	
	public function readString(pos:Int, len:Int):String {
		var result:String="";
		untyped __global__.__hxcpp_string_of_bytes(this,result,pos,len);
		return result;
	}
	
	static public function alloc(length:Int):ByteData {
		var a = [];
		if (length>0) a[length-1] = untyped 0;
		return new ByteData(a);
	}
		
	public static function ofString( s : String ) : ByteData {
		var a = [];
		untyped __global__.__hxcpp_bytes_of_string(a,s);
		return new ByteData(a);
	}
}