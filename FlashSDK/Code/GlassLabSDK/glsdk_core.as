package GlassLabSDK {	
	
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.URLLoader;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;
	import flash.system.SecurityDomain;
	import flash.events.*;
	import flash.utils.Timer;
	
	
	public class glsdk_core {
		
		private var m_glsdk_config : glsdk_config;
		
		private var m_serverUri : String;
		private var m_clientId : String;
		private var m_clientName : String;
		private var m_clientVersion : String;
		private var m_clientLevel : String;
		
		private var m_deviceId : String;
		private var m_userId : int;
		private var m_gameSessionId : String;
		
		private var m_telemEvents : Array;
		private var m_telemEventValues : Object;
		
		private var m_telemetryQueue : Array;		// Server dispatches queued up, ready to be sent to the server
		private var m_telemetryQueueTimer : Timer	// Server dispatches will be dequeued at a defined interval
		
		private var m_messageStack : Array;		// Server responses to be returned to the client
		

		public function glsdk_core() {
			// Create the config file
			m_glsdk_config = new glsdk_config();
			
			// Default id variables
			m_serverUri = "";
			m_clientId = "";
			m_clientName = "";
			m_clientVersion = "";
			m_clientLevel = "";
			
			// Default JSON object variables
			clearTelemEvents();
			clearTelemEventValues();
			
			// Initialize the telemetry queue and dispatch timer
			m_telemetryQueue = new Array();
			m_telemetryQueueTimer = new Timer( glsdk_const.TELEMETRY_DISPATCH_TIMER );
			m_telemetryQueueTimer.addEventListener( TimerEvent.TIMER, telemetryDispatch );
			m_telemetryQueueTimer.start();
			
			// Initialize the message stack
			m_messageStack = new Array();
		}
		
		
		private function pushMessageStack( message:int, data:String = "" ) : void {
			var response:glsdk_response = new glsdk_response( message, data );
			m_messageStack.push( response );
		}
		
		public function popMessageStack() : glsdk_response {
			if( m_messageStack.length > 0 ) {
				return m_messageStack.shift();
			}
			return null;
		}
		
		
		private function telemetryDispatch( event:TimerEvent ) : void {
			var dispatchCount : int = 0;
			
			// Iterate through the telemetry queue as long as it is populated
			while( m_telemetryQueue.length > 0 && dispatchCount < glsdk_const.TELEMETRY_DISPATCH_CHUNK ) {
				// Get the dispatch object
				var dispatch : Object = m_telemetryQueue[ 0 ];
				
				// Only proceed with telemetry and end session dispatches if a game session Id exists
				if( ( dispatch.m_path == m_glsdk_config.API_POST_EVENTS ||
					dispatch.m_path == m_glsdk_config.API_POST_SESSION_END ) &&
					m_gameSessionId == "" ) {
					break;
				}
				
				// Perform the request
				httpRequest( m_telemetryQueue.shift() as glsdk_dispatch );
				
				// Update the dispatched count
				dispatchCount++;
			}
		}
		

		private function connect_Fail( event:IOErrorEvent ) : void {
			trace( "connect_Fail: " + event.target.data );
			
			pushMessageStack( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		private function connect_Done( event:Event) : void {
			trace( "connect_Done: " + event.target.data );
			
			pushMessageStack( glsdk_const.MESSAGE_CONNECT, event.target.data );
		}
		public function connect( clientId:String, deviceId:String, serverUri:String ) : void {
			// Set the Id variables and URI
			m_clientId = clientId;
			m_deviceId = deviceId;
			m_serverUri = serverUri;
			m_gameSessionId = "";
			
			// Perform the request
			httpRequest( new glsdk_dispatch( m_glsdk_config.API_GET_CONFIG, "GET", {}, m_glsdk_config.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, connect_Done, connect_Fail ) );
		}
		
		
		private function deviceUpdate_Fail( event:IOErrorEvent ) : void {
			trace( "deviceUpdate_Fail: " + event.target.data );
			
			pushMessageStack( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		private function deviceUpdate_Done( event:Event ) : void {
			trace( "deviceUpdate_Done: " + event.target.data );
			
			pushMessageStack( glsdk_const.MESSAGE_DEVICE_UPDATE, event.target.data );
		}
		public function deviceUpdate() : void {
			var postData : Object = new Object();
			postData.deviceId = m_deviceId;
			postData.gameId = m_clientId;
			
			// Perform the request
			httpRequest( new glsdk_dispatch( m_glsdk_config.API_POST_DEVICE_UPDATE, "POST", postData, m_glsdk_config.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, deviceUpdate_Done, deviceUpdate_Fail ) );
		}
		

		private function startSession_Fail( event:IOErrorEvent ) : void {
			trace( "startSession_Fail: " + event.target.data );
			
			pushMessageStack( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		private function startSession_Done( event:Event ) : void {
			trace( "startSession_Done: " + event.target.data );
			
			// Parse the returned JSON and retrieve the game session Id
			var parsedJSON : Object = JSON.parse( event.target.data );
			if( parsedJSON.hasOwnProperty( "gameSessionId" ) ) {
				m_gameSessionId = parsedJSON.gameSessionId;
				trace( "Found game session Id: " + m_gameSessionId );
			}
			
			pushMessageStack( glsdk_const.MESSAGE_SESSION_START, event.target.data );
		}
		public function startSession() : void {
			var date:Date = new Date();
			
			var postData : Object = new Object();
			postData.deviceId = m_deviceId;
			postData.gameLevel = m_clientLevel;
			postData.timestamp = date.time;
			
			// Store the dispatch message to be called later
			m_telemetryQueue.push( new glsdk_dispatch( m_glsdk_config.API_POST_SESSION_START, "POST", postData, m_glsdk_config.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, startSession_Done, startSession_Fail ) );
		}
		
		
		private function endSession_Fail( event:IOErrorEvent ) : void {
			trace( "endSession_Fail: " + event.target.data );
			
			pushMessageStack( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		private function endSession_Done( event:Event ) : void {
			trace( "endSession_Done: " + event.target.data );
			
			pushMessageStack( glsdk_const.MESSAGE_SESSION_END, event.target.data );
		}
		public function endSession() : void {
			var date:Date = new Date();
			
			var postData : Object = new Object();
			postData.gameSessionId = "$gameSessionId$";
			postData.timestamp = date.time;
			
			// Store the dispatch message to be called later
			m_telemetryQueue.push( new glsdk_dispatch( m_glsdk_config.API_POST_SESSION_END, "POST", postData, m_glsdk_config.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, endSession_Done, endSession_Fail ) );
		}
		
		
		private function sendTelemEvents_Fail( event:IOErrorEvent ) : void {
			trace( "sendTelemEvents_Fail: " + event.target.data );
			
			pushMessageStack( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		private function sendTelemEvents_Done( event:Event ) : void {
			trace( "sendTelemEvents_Done: " + event.target.data );
			
			pushMessageStack( glsdk_const.MESSAGE_EVENTS, event.target.data );
		}
		public function sendTelemEvents() : void {
			// Store the dispatch message to be called later
			m_telemetryQueue.push( new glsdk_dispatch( m_glsdk_config.API_POST_EVENTS, "POST", [], m_glsdk_config.CONTENT_TYPE_APPLICATION_JSON, sendTelemEvents_Done, sendTelemEvents_Fail ) );
		}
		
		
		private function httpRequest( dispatch:glsdk_dispatch ) : void {
			// Create a new URL request object
			var req : URLRequest = new URLRequest();
			
			// Set the request attributes
			req.url = m_serverUri + dispatch.m_path;
			req.method = dispatch.m_method;
			req.contentType = dispatch.m_contentType;
			
			// Set the request data if this is a POST request
			if( dispatch.m_method == URLRequestMethod.POST ) {
				req.data = dispatch.m_postData;
			}
			
			// Create a URL loader to load the request
			var loader : URLLoader = new URLLoader();
			
			loader.load( req );
			loader.addEventListener( Event.COMPLETE, dispatch.m_successCallback );
			loader.addEventListener( IOErrorEvent.IO_ERROR, dispatch.m_failureCallback );
            loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
		}
		private function onSecurityError( event:SecurityErrorEvent ) : void {
			trace( "onSecurityError: " + event.toString() );
			
			pushMessageStack( glsdk_const.MESSAGE_ERROR, event.toString() );
		}
		
		
		public function addTelemEventValue_string( key:String, value:String ) : void {
			m_telemEventValues[ key ] = value;
		}
		public function addTelemEventValue_int( key:String, value:int ) : void {
			m_telemEventValues[ key ] = value;
		}
		public function addTelemEventValue_uint( key:String, value:uint ) : void {
			m_telemEventValues[ key ] = value;
		}
		public function addTelemEventValue_number( key:String, value:Number ) : void {
			m_telemEventValues[ key ] = value;
		}
		
		private function clearTelemEventValues() : void {
			m_telemEventValues = {};
		}
		
		private function clearTelemEvents() : void {
			m_telemEvents = [];
		}
		
		public function saveTelemEvent( p_eventName:String ) : void {
			var date:Date = new Date();
			
			// Set default information
			var telemEvent : Object = {};
			telemEvent.clientTimeStamp = date.time;
			telemEvent.eventName = p_eventName;
			telemEvent.gameId = m_clientId;
			telemEvent.gameSessionId = "";
			
			// Set the device Id if it is valid
			if( m_deviceId != "" ) {
				telemEvent.deviceId = m_deviceId;
			}
			// Set the client version if it is valid
			if( m_clientVersion != "" ) {
				telemEvent.clientVersion = m_clientVersion;
			}
			// Set the game type if it is valid
			if( m_clientLevel != "" ) {
				telemEvent.gameType = m_clientLevel;
			}
			
			// Set the event data
			telemEvent.eventData = m_telemEventValues;
			
			// Append this event to the events JSON object
			m_telemEvents.push( telemEvent );
			
			// Clear the event values
			clearTelemEventValues();
		}
		
		
		public function set serverUri( value:String ) : void {
			m_serverUri = value;
		}
		public function set clientId( value:String ) : void {
			m_clientId = value;
		}
		public function set clientName( value:String ) : void {
			m_clientName = value;
		}
		public function set clientVersion( value:String ) : void {
			m_clientVersion = value;
		}
		public function set clientLevel( value:String ) : void {
			m_clientLevel = value;
		}
		
		public function get serverUri() : String {
			return m_serverUri;
		}
		public function get clientId() : String {
			return m_clientId;
		}
		public function get clientName() : String {
			return m_clientName;
		}
		public function get clientVersion() : String {
			return m_clientVersion;
		}
		public function get clientLevel() : String {
			return m_clientLevel;
		}
	}
}