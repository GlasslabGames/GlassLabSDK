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
		
		
		// TEMP
		private var m_document : Document;
		public function setDocument( doc:Document ) : void {
			m_document = doc;
		}
		
		
		private const GET_MESSAGES_INTERVAL : int = 2000;	// Interval between message retrieval
		private const GET_MESSAGES_MAX : int = 10;			// Max number of messages to retrieve
		
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
			var response : glsdk_response = popMessageStack();
			while( response != null && retrievedCount < GET_MESSAGES_MAX ) {
				
				m_document.updateText( response.m_data );
				
				// Check the message type
				switch( response.m_message ) {
					case glsdk_const.MESSAGE_CONNECT:
						trace( "MESSAGE_CONNECT: " + response.m_data );
						deviceUpdate();
						break;
					
					case glsdk_const.MESSAGE_DEVICE_UPDATE:
						trace( "MESSAGE_DEVICE_UPDATE: " + response.m_data );
						startSession();
						break;
					
					case glsdk_const.MESSAGE_SESSION_START:
						trace( "MESSAGE_SESSION_START: " + response.m_data );
						endSession();
						break;
					
					case glsdk_const.MESSAGE_SESSION_END:
						trace( "MESSAGE_SESSION_END: " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_EVENTS:
						trace( "MESSAGE_EVENTS: " + response.m_data );
						break;
					
					case glsdk_const.MESSAGE_ERROR:
						trace( "MESSAGE_ERROR: " + response.m_data );
						break;
					
					default:
						break;
				}
				
				// Update the retrieved count and get the next message
				retrievedCount++;
				response = popMessageStack();
			}
		}
	}
}