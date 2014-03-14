package byte.js;

typedef NativeByteRepresentation = js.html.Uint8Array;

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
		var buf = new StringBuf();
		for (i in pos...pos + len) buf.addChar(this[i]);
		return buf.toString();
	}
	
	static public function alloc(length:Int):ByteData {
		var b = new js.html.Uint8Array(length);
		return new ByteData(b);
	}
		
	static public function ofString(s:String):ByteData {
		var a = new js.html.Uint8Array(s.length);
		for(i in 0...s.length) a[i] = StringTools.fastCodeAt(s, i);
		return new ByteData(a);
	}
}