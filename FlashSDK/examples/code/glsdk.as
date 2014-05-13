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
		

		public function glsdk() {
			// Initialize the SDK message timer
			m_getMessagesTimer = new Timer( GET_MESSAGES_INTERVAL );
			m_getMessagesTimer.addEventListener( TimerEvent.TIMER, getServerMessages );
			m_getMessagesTimer.start();
		}
		
		
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
		
		
		////////////////////////////////////////////////////////////////////////////////////////////
		
		/*
		 * The Below code is for debugging purposes.
		 */
		private var m_document : Document;
		public function setDocument( doc:Document ) : void {
			m_document = doc;
			m_instance.m_document.addEventListener( KeyboardEvent.KEY_DOWN, reportKeyDown );
		}
		
		public function reportKeyDown( event:KeyboardEvent ) : void { 
			//trace("Key Pressed: " + String.fromCharCode(event.charCode) + " (character code: " + event.charCode + ")");
			if( event.charCode == 115 ) {
				writeText( "Attempting to call start session..." );
				startSession();
			}
			else if( event.charCode == 101 ) {
				writeText( "Attempting to call end session..." );
				endSession();
			}
			else if( event.charCode == 116 ) {
				writeText( "Attempting to send test telemetry..." );
				addTelemEventValue_string( "key1", "value1" );
				addTelemEventValue_int( "key2", 2 );
				addTelemEventValue_uint( "key3", 3 );
				addTelemEventValue_number( "key4", 4.1 );
				saveTelemEvent( "test_telem" );
			}
		}
		
		public override function writeText( text:String ) : void {
			// DEBUG - append to canvas stream
			m_document.updateText( text );
		}
	}
}