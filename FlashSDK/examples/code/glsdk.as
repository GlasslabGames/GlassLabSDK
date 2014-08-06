/**
* glsdk.as
* GlassLab SDK
*
* Sample API subclass to the glsdk_core base class. This sample demonstrates
* how to communicate with the core base class to make server calls and receive
* response information.
*
* @author Ben Dapkiewicz
*
* Copyright (c) 2014 GlassLab. All rights reserved.
*/
package {
	
	import GlassLabSDK.*;
	
	import flash.events.*;
	import flash.utils.Timer;
	
	
	public class glsdk extends glsdk_core {
		
		// Singleton instance
		private static var m_instance : glsdk;
		public static function instance() : glsdk {
			if( m_instance == null ) {
				m_instance = new glsdk();
			}
			return m_instance;
		}
		
		
		private const GET_MESSAGES_INTERVAL : int = 500;	// Interval between message retrieval
		private const GET_MESSAGES_MAX : int = 32;			// Max number of messages to retrieve
		
		private var m_getMessagesTimer : Timer;		// Timer for SDK message retrieval		
		

		/**
		* Default constructor creates a timer to check for server messages.
		*/
		public function glsdk() {
			// Initialize the SDK message timer
			m_getMessagesTimer = new Timer( GET_MESSAGES_INTERVAL );
			m_getMessagesTimer.addEventListener( TimerEvent.TIMER, getServerMessages );
			m_getMessagesTimer.start();
		}
		
		/**
		* Function is called at a defined interval to check for server response messages.
		* This function will call popMessageQueue from the glsdk_core base class and 
		* receive a glsdk_response object as a result. It then checks for the returned
		* message type and prints the data.
		*
		* @param event A reference to the TimerEvent object sent along with the listener.
		*/
		private function getServerMessages( event:TimerEvent ) : void {
			var retrievedCount : int = 0;
			
			// Get the next server message
			var response : glsdk_response = popMessageQueue();
			while( response != null && retrievedCount < GET_MESSAGES_MAX ) {
				
				// Check the message type
				switch( response.m_message ) {
					case glsdk_const.MESSAGE_CONNECT:
						trace( "MESSAGE_CONNECT " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_CONNECT " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_AUTH_STATUS:
						trace( "MESSAGE_AUTH_STATUS " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_AUTH_STATUS " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_GET_PLAYER_INFO:
						trace( "MESSAGE_GET_PLAYER_INFO " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_GET_PLAYER_INFO " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_SESSION_START:
						trace( "MESSAGE_SESSION_START " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_SESSION_START " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_SESSION_END:
						trace( "MESSAGE_SESSION_END " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_SESSION_END " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_EVENTS:
						trace( "MESSAGE_EVENTS " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_EVENTS " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_POST_TOTAL_TIME_PLAYED:
						trace( "MESSAGE_POST_TOTAL_TIME_PLAYED " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_POST_TOTAL_TIME_PLAYED " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_GET_ACHIEVEMENTS:
						trace( "MESSAGE_GET_ACHIEVEMENTS " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_GET_ACHIEVEMENTS " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_POST_ACHIEVEMENT:
						trace( "MESSAGE_POST_ACHIEVEMENT " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_POST_ACHIEVEMENT " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_GET_SAVE_GAME:
						trace( "MESSAGE_GET_SAVE_GAME " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_GET_SAVE_GAME " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_POST_SAVE_GAME:
						trace( "MESSAGE_POST_SAVE_GAME " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_POST_SAVE_GAME " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_ERROR:
						trace( "MESSAGE_ERROR " + response.m_data );
					
						// DEBUG - append to canvas stream
						writeText( "MESSAGE_ERROR " + response.m_data );
						break;
					
					default:
						break;
				}
				
				// Update the retrieved count and get the next message
				retrievedCount++;
				response = popMessageQueue();
			}
		}
		
		
		/*
		 * Keep a reference to the document class so we can print to the screen.
		 */
		private var m_document : Document;
		public function setDocument( doc:Document ) : void {
			m_document = doc;
			m_instance.m_document.addEventListener( KeyboardEvent.KEY_DOWN, reportKeyDown );
		}
		
		/**
		* Listen for keyboard buttons to call certain glsdk_core functions:
		* - The 'S' key calls startSession
		* - The 'E' key calls endSession
		* - The 'T' key sends a predefined telemetry event with addTelemEventValue_[type] and saveTelemEvent
		*
		* @param event A reference to the KeyboardEvent object sent along with the listener.
		*
		* @see startSession
		* @see endSession
		* @see addTelemEventValue_string
		* @see addTelemEventValue_int
		* @see addTelemEventValue_uint
		* @see addTelemEventValue_number
		* @see saveTelemEvent
		*/
		public function reportKeyDown( event:KeyboardEvent ) : void { 
			trace("Key Pressed: " + String.fromCharCode(event.charCode) + " (character code: " + event.charCode + ")");
			
			if( event.charCode == 115 ) {	// S
				writeText( "Attempting to call start session..." );
				startSession();
			}
			else if( event.charCode == 101 ) {	// E
				writeText( "Attempting to call end session..." );
				endSession();
			}
			else if( event.charCode == 116 ) {	// T
				writeText( "Attempting to send test telemetry..." );
				/*addTelemEventValue_string( "key1", "value1" );
				addTelemEventValue_int( "key2", 2 );
				addTelemEventValue_uint( "key3", 3 );
				addTelemEventValue_number( "key4", 4.1 );
				addTelemEventValue_bool( "key5", true );*/
				saveTelemEventWithData( "test_telem", { "key1":"value1", "key2":2, "key3":4.1, "key4":true } );
			}
			else if( event.charCode == 97 ) {	// A
				writeText( "Attempting to get auth status..." );
				getAuthStatus();
			}
			else if( event.charCode == 113 ) {	// Q
				writeText( "Attempting to get all achievements..." );
				getAchievements();
			}
			else if( event.charCode == 119 ) {	// W
				writeText( "Attempting to send an achievement..." );
				saveAchievement( "Core Cadet", "CCSS.ELA-Literacy.WHST.6-8.1", "b" );
			}
			else if( event.charCode == 103 ) {	// G
				writeText( "Attempting to get save game..." );
				getSaveGame();
			}
			else if( event.charCode == 104 ) {	// H
				writeText( "Attempting to post save game..." );
				postSaveGame();
				//saveAchievement( "Core Cadet", "CCSS.ELA-Literacy.WHST.6-8.1", "b" );
			}
		}
		
		/**
		* Function writes text to display in the canvas.
		*
		* @param text The text to display.
		*/
		public override function writeText( text:String ) : void {
			// DEBUG - append to canvas stream
			m_document.updateText( text );
		}
	}
}