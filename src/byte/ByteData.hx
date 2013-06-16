package byte;

#if flash9
typedef ByteData = byte.flash.ByteData;
#elseif neko
typedef ByteData = byte.neko.ByteData;
#elseif cpp
typedef ByteData = byte.cpp.ByteData;
#elseif java
typedef ByteData = byte.java.ByteData;
#elseif php
typedef ByteData = byte.php.ByteData;
#else

typedef NativeByteRepresentation = haxe.ds.Vector<Int>;

abstract ByteData(NativeByteRepresentation) {
	
	public var length(get, never):Int;
	function get_length():Int return this.length;

	public var reader(get, never):LittleEndianReader;
	inline function get_reader() return new LittleEndianReader(new ByteData(this));

	public var writer(get, never):LittleEndianWriter;
	inline function get_writer() return new LittleEndianWriter(new ByteData(this));
	
	public inline function new(data:NativeByteRepresentation) {
		this = data;
	}
		
	public inline function readByte(pos:Int):Int {
		return this.get(pos);
	}
	
	public inline function writeByte( pos : Int, v : Int ) : Void {
		this.set(pos, v & 0xFF);
	}
	
	public function readString(pos:Int, len:Int) {
		var s = "";
		var fcc = String.fromCharCode;
		var i = pos;
		var max = pos + len;
		// utf8-encode
		while( i < max ) {
			var c = readByte(i++);
			if( c < 0x80 ) {
				if( c == 0 ) break;
				s += fcc(c);
			} else if( c < 0xE0 )
				s += fcc( ((c & 0x3F) << 6) | (readByte(i++) & 0x7F) );
			else if( c < 0xF0 ) {
				var c2 = readByte(i++);
				s += fcc( ((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | (readByte(i++) & 0x7F) );
			} else {
				var c2 = readByte(i++);
				var c3 = readByte(i++);
				s += fcc( ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 << 6) & 0x7F) | (readByte(i++) & 0x7F) );
			}
		}
		return s;
	}
	
	static public function alloc(length:Int) {
		var vec = new haxe.ds.Vector(length);
		for (i in 0...length) vec.set(i, 0);
		return new ByteData(vec);
	}
		
	static public function ofString(s:String):ByteData {
		var a = new Array();
		// utf8-decode
		for( i in 0...s.length ) {
			var c : Int = StringTools.fastCodeAt(s,i);
			if( c <= 0x7F )
				a.push(c);
			else if( c <= 0x7FF ) {
				a.push( 0xC0 | (c >> 6) );
				a.push( 0x80 | (c & 63) );
			} else if( c <= 0xFFFF ) {
				a.push( 0xE0 | (c >> 12) );
				a.push( 0x80 | ((c >> 6) & 63) );
				a.push( 0x80 | (c & 63) );
			} else {
				a.push( 0xF0 | (c >> 18) );
				a.push( 0x80 | ((c >> 12) & 63) );
				a.push( 0x80 | ((c >> 6) & 63) );
				a.push( 0x80 | (c & 63) );
			}
		}
		return new ByteData(haxe.ds.Vector.fromArrayCopy(a));
	}
}
#end