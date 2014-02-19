class TestMacro
{
	function test()
	{
		#if false
		"#if false";
		#end
		
		#if !js
		"#if !js";
		#end

		#if (true && !js)
		"#if (true && !js)";
		#end

		#if !(true && js)
		"#if !(true && js)";
		#end

		#if (foo < 1.2)
		"#if (foo < 1.2)";
		#end

		#if true
		"#if true";
		#end

		#if js
		"#if js";
		#end

		#if (true && js)
		"#if (true && js)";
		#end

		#if (false || js)
		"#if (false || js)";
		#end

		#if (foo > 1.2)
		"#if (foo > 1.2)";
		#end
	}
}