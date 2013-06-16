package byte.neko;

typedef NativeByteRepresentation = neko.NativeString;

abstract ByteData(NativeByteRepresentation) {
	
	public var length(get, never):Int;
	public function get_length():Int return untyped __dollar__ssize(this);

	public var reader(get, never):LittleEndianReader;
	inline function get_reader():LittleEndianReader return new LittleEndianReader(new ByteData(this));

	public var writer(get, never):LittleEndianWriter;
	inline function get_writer():LittleEndianWriter return new LittleEndianWriter(new ByteData(this));
	
	public inline function new(data:NativeByteRepresentation) {
		this = data;
	}
		
	public inline function readByte(pos:Int):Int {
		return untyped __dollar__sget(this, pos);
	}
	
	public inline function writeByte(pos:Int, v:Int):Void {
		untyped __dollar__sset(this,pos,v);
	}
	
	public function readString(pos:Int, len:Int):String {
		return try new String(untyped __dollar__ssub(this,pos,len)) catch( e : Dynamic ) throw haxe.io.Error.OutsideBounds;
	}
	
	static public function alloc(length:Int):ByteData {
		return new ByteData(untyped __dollar__smake(length));
	}
		
	public static function ofString( s : String ) : ByteData {
		return new ByteData(untyped __dollar__ssub(s.__s,0,s.length));
	}
}