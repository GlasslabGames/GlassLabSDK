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

		/**
		* Default constructor creates a new instance of the GlassLab SDK and 
		* esablishes a connection to the server.
		*/
		public function Document() {
			
			// DEBUG - set the document so we have the canvas to print to
			glsdk.instance().setDocument( this );
			
			// Set the client level and connect to a server
			glsdk.instance().clientLevel = "Argument Wars";
			//glsdk.instance().connect( "AW-1", "test_device", "http://192.168.2.16:8001" );
			glsdk.instance().connect( "AW-1", "test_device", "http://aw.glgames.org" );
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