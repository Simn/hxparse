package byte;

import haxe.io.Error;

abstract LittleEndianWriter(ByteData) {
	public inline function new(data:ByteData) {
		this = data;
	}
	
	public function writeInt8(pos:Int, x:Int) {
		if( x < -0x80 || x >= 0x80 )
			throw Error.Overflow;
		this.writeByte(pos, x & 0xFF);
	}
	
	public inline function writeUInt8(pos:Int, x:Int) {
		this.writeByte(pos, x);
	}

	public function writeInt16(pos:Int, x:Int) {
		if( x < -0x8000 || x >= 0x8000 ) throw Error.Overflow;
		writeUInt16(pos, x & 0xFFFF);
	}

	public function writeUInt16(pos:Int, x:Int) {
		if( x < 0 || x >= 0x10000 ) throw Error.Overflow;
		this.writeByte(pos, x & 0xFF);
		this.writeByte(pos + 1, x >> 8);
	}

	public function writeInt24(pos:Int, x:Int) {
		if( x < -0x800000 || x >= 0x800000 ) throw Error.Overflow;
		writeUInt24(pos, x & 0xFFFFFF);
	}

	public function writeUInt24(pos:Int, x:Int) {
		if( x < 0 || x >= 0x1000000 ) throw Error.Overflow;
		this.writeByte(pos, x & 0xFF);
		this.writeByte(pos + 1, (x >> 8) & 0xFF);
		this.writeByte(pos + 2, x >> 16);
	}

	public function writeInt32(pos:Int, x:Int) {
		this.writeByte(pos, x & 0xFF);
		this.writeByte(pos + 1, (x >> 8) & 0xFF);
		this.writeByte(pos + 2, (x >> 16) & 0xFF);
		this.writeByte(pos + 3, x >>> 24);
	}
	
	public function writeFloat(pos:Int, x:Float) {
		if (x == 0.0) {
			this.writeByte(pos, 0);
			this.writeByte(pos + 1, 0);
			this.writeByte(pos + 2, 0);
			this.writeByte(pos + 3, 0);
			return;
		}
		var exp = Math.floor(Math.log(Math.abs(x)) / LN2);
		var sig = (Math.floor(Math.abs(x) / Math.pow(2, exp) * (2 << 22)) & 0x7FFFFF);
		var b1 = (exp + 0x7F) >> 1 | (exp>0 ? ((x<0) ? 1<<7 : 1<<6) : ((x<0) ? 1<<7 : 0)),
			b2 = (exp + 0x7F) << 7 & 0xFF | (sig >> 16 & 0x7F),
			b3 = (sig >> 8) & 0xFF,
			b4 = sig & 0xFF;
		this.writeByte(pos, b1);
		this.writeByte(pos + 1, b2);
		this.writeByte(pos + 2, b3);
		this.writeByte(pos + 3, b4);
	}
	
	public function writeDouble(pos:Int, x:Float) {
		if (x == 0.0) {
			this.writeByte(pos, 0);
			this.writeByte(pos + 1, 0);
			this.writeByte(pos + 2, 0);
			this.writeByte(pos + 3, 0);
			this.writeByte(pos + 4, 0);
			this.writeByte(pos + 5, 0);
			this.writeByte(pos + 6, 0);
			this.writeByte(pos + 7, 0);
			return;
		}

		var exp = Math.floor(Math.log(Math.abs(x)) / LN2);
		var sig : Int = Math.floor(Math.abs(x) / Math.pow(2, exp) * Math.pow(2, 52));
		var sig_h = (sig & cast 34359738367);
		var sig_l = Math.floor((sig / Math.pow(2,32)));
		var b1 = (exp + 0x3FF) >> 4 | (exp>0 ? ((x<0) ? 1<<7 : 1<<6) : ((x<0) ? 1<<7 : 0)),
			b2 = (exp + 0x3FF) << 4 & 0xFF | (sig_l >> 16 & 0xF),
			b3 = (sig_l >> 8) & 0xFF,
			b4 = sig_l & 0xFF,
			b5 = (sig_h >> 24) & 0xFF,
			b6 = (sig_h >> 16) & 0xFF,
			b7 = (sig_h >> 8) & 0xFF,
			b8 = sig_h & 0xFF;

		this.writeByte(pos, b1);
		this.writeByte(pos + 1, b2);
		this.writeByte(pos + 2, b3);
		this.writeByte(pos + 3, b4);
		this.writeByte(pos + 4, b5);
		this.writeByte(pos + 5, b6);
		this.writeByte(pos + 6, b7);
		this.writeByte(pos + 7, b8);
	}
	
	private static var LN2 = Math.log(2);
}