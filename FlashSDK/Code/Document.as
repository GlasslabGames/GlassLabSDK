package {
	import flash.display.MovieClip;
	import flash.text.TextField;

	import flash.events.*;

	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Security;


	public class Document extends MovieClip {

		public function Document() {
			
			glsdk.instance().setDocument( this );
			glsdk.instance().clientLevel = "Argument Wars";
			glsdk.instance().connect( "AW-1", "ben_device", "http://192.168.4.244:8001" );
		}
		
		public function updateText( text:String ) : void {
			var rt:MovieClip = MovieClip(root);
			TextField(rt["DebugText"]).appendText( text );
		}
	}
}