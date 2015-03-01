package byte;

abstract ByteData(haxe.io.UInt8Array) {

	public var length(get,never):Int;
	inline function get_length() return this.length;

	inline public function readByte(i:Int) return this.get(i);

	inline function new(data) {
		this = data;
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
		var bd = new haxe.io.UInt8Array(a.length);
		for (i in 0...bd.length) {
			bd.set(i, a[i]);
		}
		return new ByteData(bd);
	}

	public function readString(pos:Int, len:Int) {
		var s = new StringBuf();
		var i = pos;
		var max = pos + len;
		// utf8-encode
		while( i < max ) {
			var c = readByte(i++);
			if( c < 0x80 ) {
				if( c == 0 ) break;
				s.addChar(c);
			} else if( c < 0xE0 )
				s.addChar( ((c & 0x3F) << 6) | (readByte(i++) & 0x7F) );
			else if( c < 0xF0 ) {
				var c2 = readByte(i++);
				s.addChar( ((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | (readByte(i++) & 0x7F) );
			} else {
				var c2 = readByte(i++);
				var c3 = readByte(i++);
				s.addChar( ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 << 6) & 0x7F) | (readByte(i++) & 0x7F) );
			}
		}
		return s.toString();
	}
}