package byte;

abstract LittleEndianReader(ByteData) {

	public inline function new(data:ByteData) {
		this = data;
	}
	
	public function readInt8(pos:Int) {
		var n = this.readByte(pos);
		if( n >= 128 )
			return n - 256;
		return n;
	}
	
	public inline function readUInt8(pos:Int) {
		return this.readByte(pos);
	}

	public function readInt16(pos:Int) {
		var ch1 = this.readByte(pos);
		var ch2 = this.readByte(pos + 1);
		var n = ch1 | (ch2 << 8);
		if( n & 0x8000 != 0 )
			return n - 0x10000;
		return n;
	}

	public function readUInt16(pos:Int) {
		var ch1 = this.readByte(pos);
		var ch2 = this.readByte(pos + 1);
		return ch1 | (ch2 << 8);
	}

	public function readInt24(pos:Int) {
		var ch1 = this.readByte(pos);
		var ch2 = this.readByte(pos + 1);
		var ch3 = this.readByte(pos + 2);
		var n = ch1 | (ch2 << 8) | (ch3 << 16);
		if( n & 0x800000 != 0 )
			return n - 0x1000000;
		return n;
	}

	public function readUInt24(pos:Int) {
		var ch1 = this.readByte(pos);
		var ch2 = this.readByte(pos + 1);
		var ch3 = this.readByte(pos + 2);
		return ch1 | (ch2 << 8) | (ch3 << 16);
	}

	public function readInt32(pos:Int) {
		var ch1 = this.readByte(pos);
		var ch2 = this.readByte(pos + 1);
		var ch3 = this.readByte(pos + 2);
		var ch4 = this.readByte(pos + 3);
		return ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
	}
	
	public function readString(pos:Int, len:Int) : String {
		return this.readString(pos, len);
	}
	
	public function readFloat(pos:Int) {
		var bytes = [];
		bytes.push(cast this.readByte(pos));
		bytes.push(cast this.readByte(pos + 1));
		bytes.push(cast this.readByte(pos + 2));
		bytes.push(cast this.readByte(pos + 3));
		var sign = 1 - ((bytes[0] >> 7) << 1);
		var exp = (((bytes[0] << 1) & 0xFF) | (bytes[1] >> 7)) - 127;
		var sig = ((bytes[1] & 0x7F) << 16) | (bytes[2] << 8) | bytes[3];
		if (sig == 0 && exp == -127)
			return 0.0;
		return sign*(1 + Math.pow(2, -23)*sig) * Math.pow(2, exp);
	}
	
	public function readDouble(pos:Int) {
		var bytes = [];
		bytes.push(this.readByte(pos));
		bytes.push(this.readByte(pos + 1));
		bytes.push(this.readByte(pos + 2));
		bytes.push(this.readByte(pos + 3));
		bytes.push(this.readByte(pos + 4));
		bytes.push(this.readByte(pos + 5));
		bytes.push(this.readByte(pos + 6));
		bytes.push(this.readByte(pos + 7));
		var sign = 1 - ((bytes[0] >> 7) << 1); // sign = bit 0
		var exp = (((bytes[0] << 4) & 0x7FF) | (bytes[1] >> 4)) - 1023; // exponent = bits 1..11
		var sig = getDoubleSig(bytes);
		if (sig == 0 && exp == -1023)
			return 0.0;
		return sign * (1.0 + Math.pow(2, -52) * sig) * Math.pow(2, exp);
	}
	
	function getDoubleSig(bytes:Array<Int>) {
        return (((bytes[1]&0xF) << 16) | (bytes[2] << 8) | bytes[3] ) * 4294967296. +
            (bytes[4] >> 7) * 2147483648 +
            (((bytes[4]&0x7F) << 24) | (bytes[5] << 16) | (bytes[6] << 8) | bytes[7]);
    }
}