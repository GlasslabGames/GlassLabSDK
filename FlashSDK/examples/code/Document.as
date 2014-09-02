/**
* Document.as
*
* Sample document class to establish a connectin to a temporary server and 
* write debug text to the canvas.
*
* @author Ben Dapkiewicz
*
* Copyright (c) 2014 GlassLab. All rights reserved.
*/
package {
	import flash.display.MovieClip;
	import flash.text.TextField;

	import flash.events.*;


	public class Document extends MovieClip {
		
		// Server/client constants
		public static const SERVER_URI 	: String = "http://developer.playfully.org";
		public static const GAME_LEVEL 	: String = "Demonstration";
		public static const GAME_ID		: String = "TEST";
		

		/**
		* Default constructor creates a new instance of the GlassLab SDK and 
		* esablishes a connection to the server.
		*/
		public function Document() {
			
			// DEBUG - set the document so we have the canvas to print to
			glsdk.instance().setDocument( this );
			
			// Set the client level and connect to a server
			glsdk.instance().clientLevel = GAME_LEVEL;
			glsdk.instance().connect( GAME_ID, "test_device", SERVER_URI );
		}
		
		/**
		* Helper function for writing text to the canvas.
		*
		* @param text The text to display.
		*/
		public function updateText( text:String ) : void {
			var rt:MovieClip = MovieClip(root);
			TextField( rt["DebugText"] ).text = text + "\n\n" + TextField( rt["DebugText"] ).text;
		}
	}
}