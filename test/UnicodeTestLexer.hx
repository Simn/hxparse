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
		"あ𠀀" => lexer.current,
		'\u00CA' => lexer.current, // Ê
		'\u20AC' => lexer.current,	// €
		'\u{29e3d}' => lexer.current, // 𩸽
		'[ a-zA-Z0-9ÀÁÂÃÄÅÆÇÈÉËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáãäåæçèéëìíîïðñòóôõöøúûüýþÿ№あ𠀀]' => lexer.current,
		//'[Ã-Ë]' => lexer.current
	];

}