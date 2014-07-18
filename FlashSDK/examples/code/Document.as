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
		
		//public static const SERVER_URI 	: String = "http://192.168.1.101:8001";
		public static const SERVER_URI 	: String = "http://aw.glgames.org";
		public static const GAME_LEVEL 	: String	= "Argument Wars";
		public static const GAME_ID		: String = "AW-1";
		

		/**
		* Default constructor creates a new instance of the GlassLab SDK and 
		* esablishes a connection to the server.
		*/
		public function Document() {

			//flash.system.Security.loadPolicyFile( SERVER_URI + "/crossdomain.xml" );
			
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