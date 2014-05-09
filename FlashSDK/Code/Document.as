package {
	import flash.display.MovieClip;
	import flash.text.TextField;

	import flash.events.*;


	public class Document extends MovieClip {

		public function Document() {
			
			// DEBUG - set the document so we have the canvas to print to
			glsdk.instance().setDocument( this );
			
			// Set the client level and connect to a server
			glsdk.instance().clientLevel = "Argument Wars";
			glsdk.instance().connect( "AW-1", "test_device", "http://54.241.27.184" );
		}
		
		// DEBUG text printing
		public function updateText( text:String ) : void {
			var rt:MovieClip = MovieClip(root);
			TextField(rt["DebugText"]).text = text + "\n\n" + TextField(rt["DebugText"]).text;
		}
	}
}