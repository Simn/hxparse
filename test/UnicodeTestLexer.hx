package ;

import hxparse.Lexer;
import hxparse.RuleBuilder;
import haxe.Utf8;

/**
 * ...
 * @author Skial Bainn
 */
class UnicodeTestLexer extends Lexer implements RuleBuilder {

	public static var root = @:rule [
		'â' => lexer.current,
		'ê' => lexer.current,
		'ù' => lexer.current,
		"あ𠀀" => lexer.current
	];

}