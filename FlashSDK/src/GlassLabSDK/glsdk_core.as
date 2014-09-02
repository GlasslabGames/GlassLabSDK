/**
* glsdk_core.as
* GlassLab SDK
*
* Core SDK is responsible for maintaining communication between client and server.
* The client is defined by a number of unique parameters which are associated with
* every telemetry event. These parameters include an Id, name, version, and level.
*
* This class allows the user to start a new session, close that session, and
* send telemetry. Only one session can be active at a time and telemetry will not 
* be stored if it has no game session Id to attach to.
*
* Core also maintains a dispatch queue for server-returned messages. These dispatch
* message can be extracted via the popMessageStack() funtion.
*
* @author Ben Dapkiewicz
*
* Copyright (c) 2014 GlassLab. All rights reserved.
*/
package GlassLabSDK {
	
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	import flash.net.URLLoader;
	
	import flash.external.ExternalInterface;
	import flash.system.Security;
	
	import flash.events.*;
	import flash.utils.Timer;
	import flash.utils.ByteArray;
	
	import com.hurlant.util.Hex;
	
	
	public class glsdk_core {
		
		// Client properties
		private var m_serverUri : String;		// Ex. http://argubotacademy.org
		private var m_clientId : String;		// Ex. AA-1
		private var m_clientName : String;		// Ex. Mars Generation One: Argubot Academy
		private var m_clientVersion : String;	// Ex. 1.02
		private var m_clientLevel : String;		// Ex. MGO_launch, MGO_act1
		
		// User properties
		private var m_deviceId : String;		// Unique Id accompanied with the session indicating device
		private var m_gameSessionId : String;	// Unique Id denoting a game session, set on startSession success
		
		// Config object
		private var m_config : Object;	// Object contains config variables used for throttling telemetry	
		
		// JSON helpers
		private var m_telemEvents : Array;			// Array containing queued telemetry events ready for dispatch
		private var m_telemEventValues : Object;	// Array containing unique event values for a single event
		
		// Default telemetry properties
		private var m_gameSessionEventOrder : int;	// This is an incremented counter attached to each telemetry event, resets with every new session
		private var m_totalTimePlayed : Number;		// Total amount of time played for the user
		
		// Update timer and other total time played variables
		private var m_updateTimer : Timer;	// Timer calls a function to update the total time played
		private var m_lastUpdateTime : int;	// Time since last update
		
		// Dispatches and Responses
		private var m_telemetryQueue : Array;		// Server dispatches queued up, ready to be sent to the server
		private var m_telemetryQueueTimer : Timer;	// Server dispatches will be dequeued at a defined interval
		private var m_messageQueue : Array;			// Server responses to be returned to the client
		
		// Dispatch variables
		private var m_flushQueueOnEndSession : Boolean;	// If necessary, the dispatch queue can be flushed when end session is called
		private var m_dispatchCount : int;				// Local counter for dispatching telemetry
		private var m_dispatching : Boolean;			// Indicates if the SDK is in the middle of dispatching events
		

		/**
		* Default constructor initializes client properties and prepares an "empty" machine
		* ready to communicate to the server.
		*/
		public function glsdk_core() {
			// Setup the ExternalInterface callback functions. These callback functions will redirect
			// to the appropriate internal callback function using the attached "api" variable.
			if( !isLocal() ) {
				Security.allowDomain( "*" );
				if( ExternalInterface.available ) {
					ExternalInterface.addCallback( "success", eiSuccessCallback );
					ExternalInterface.addCallback( "failure", eiFailureCallback );
				}
			}
			
			// Default id variables
			m_serverUri = "";
			m_clientId = "";
			m_clientName = "";
			m_clientVersion = "";
			m_clientLevel = "";
			
			// Create the object to contain connect callback config variables
			m_config = new Object();
			m_config.eventsDetailLevel = glsdk_const.THROTTLE_PRIORITY_DEFAULT;
			m_config.eventsPeriodSecs = glsdk_const.THROTTLE_INTERVAL_DEFAULT;
			m_config.eventsMinSize = glsdk_const.THROTTLE_MIN_SIZE_DEFAULT;
			m_config.eventsMaxSize = glsdk_const.THROTTLE_MAX_SIZE_DEFAULT;
			
			// Default JSON object variables
			clearTelemEvents();
			clearTelemEventValues();
			
			// Default telemetry properties
			m_gameSessionEventOrder = 1;
			m_totalTimePlayed = 0;
			
			// Create the update timer
			m_updateTimer = new Timer( glsdk_const.UPDATE_TIMER * 1000 );
			m_updateTimer.addEventListener( TimerEvent.TIMER, update );
			
			// Initialize the telemetry queue and dispatch timer with default throttling
			m_telemetryQueue = new Array();
			m_telemetryQueueTimer = new Timer( m_config.eventsPeriodSecs );
			m_telemetryQueueTimer.addEventListener( TimerEvent.TIMER, telemetryDispatch );
			m_telemetryQueueTimer.start();
			
			// Set force flush variables to default
			m_flushQueueOnEndSession = true;
			m_dispatchCount = 0;
			m_dispatching = false;
			
			// Initialize the message queue
			m_messageQueue = new Array();
		}
		
		
		/**
		* Function adds a new server response object to the message queue, which is
		* composed of the message type and JSON data. This function is called on
		* every server callback, success and failure included.
		*
		* @param message The message type as denoted in glsdk_const.
		* @param data The returned data in JSON format.
		*/
		private function pushMessageQueue( message:int, data:String = "" ) : void {
			var response:glsdk_response = new glsdk_response( message, data );
			m_messageQueue.push( response );
		}
		
		/**
		* Function pops the first response message from the queue and returns it.
		* If the queue is empty, null will be returned instead.
		*
		* @return A glsdk_response object is returned containing message and data
		* information. A null indicates there are no more message available.
		*/
		public function popMessageQueue() : glsdk_response {
			if( m_messageQueue.length > 0 ) {
				return m_messageQueue.shift();
			}
			return null;
		}
		
		/**
		* This function acts as a helper to push dispatch messages to the telemetry queue.
		* This will be called by start session, end session, and telemetry SDK functions.
		* It will be responsible for forcing server requests if the max number of events
		* has been reached, regardless of the timer.
		*
		* @param dispatch The dispatch object containing request data.
		*/
		private function pushTelemetryQueue( dispatch:glsdk_dispatch ) : void {
			m_telemetryQueue.push( dispatch );
			
			// If we've reached the max number of events, force the dispatch and reset the timer
			if( m_telemetryQueue.length >= m_config.eventsMaxSize ) {
				telemetryDispatch( null );
				m_telemetryQueueTimer.reset();
				m_telemetryQueueTimer.start();
			}
		}
		
		/**
		* This function is called when the dispatch timer is complete or we've reached the max number
		* of events in the queue. Sets a flag indicating we're dispatching and dispatches the first
		* event.
		*
		* @param event A reference to the TimerEvent object sent along with the listener.
		*
		* @see httpRequest
		*/
		private function telemetryDispatch( event:TimerEvent ) : void {
			// Indicate that we are dispatching and reset the count
			m_dispatching = true;
			m_dispatchCount = 0;
			
			// Dispatch the next event
			dispatchNext();
			return;
		}
		
		/**
		* This function will dispatch queued messages to the server. We dispatch messages
		* at a defined interval in an effort to reduce server load, rather than at the
		* time of request. The dispatch interval and chunk size can be found in
		* glsdk_const.
		*
		* @see httpRequest
		*/
		private function dispatchNext() : void {
			// Exit if we're not actual supposed to dispatch, the telemetry queue is empty, or we've exceeded the chunk we can send
			if( !m_dispatching || m_telemetryQueue.length == 0 || m_dispatchCount >= glsdk_const.TELEMETRY_DISPATCH_CHUNK ) {
				m_dispatching = false;
				return;
			}
			
			// Get the dispatch object
			var dispatch : Object = m_telemetryQueue[ 0 ];
			
			// Only proceed with telemetry and end session dispatches if a game session Id exists
			if( dispatch.m_path == glsdk_const.API_POST_EVENTS || dispatch.m_path == glsdk_const.API_POST_SESSION_END ) {
				// If the game session Id does not exist, break out of the loop
				if( m_gameSessionId == "" ) {
					return;
				}
				// Else we need to replace the tag with the actual value
				else {
					m_telemetryQueue[ 0 ].m_postData.gameSessionId = m_gameSessionId;
				}
			}
			
			// Perform the request
			httpRequest( m_telemetryQueue.shift() as glsdk_dispatch );
			
			// Increment the dispatched count
			m_dispatchCount++;
		}
		
		
		/**
		* Update function is called at an interval defined by UPDATE_TIMER. This function 
		* updates the total time played and queues up a dispatch for setting it.
		*
		* @param event A reference to the TimerEvent object sent along with the listener.
		*/
		private function update( event:TimerEvent ) : void {
			m_totalTimePlayed += glsdk_const.UPDATE_TIMER;
			sendTotalTimePlayed();
		}
		

		/**
		* Failure callback function for the connect() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function connect_Fail( event:Object ) : void {
			trace( "connect_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		/**
		* Success callback function for the connect() http request. Adds a CONNECT response
		* to the message queue. Once this request is returned, we need to call getConfig to
		* get the config information specific to the game Id.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function connect_Done( event:Object ) : void {
			trace( "connect_Done: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_CONNECT, event.target.data );
			
			// Once we have a successful connection, get the config info with the redirect URL
			getConfig( event.target.data );
		}
		/**
		* Helper function for connecting directly with the server. This particular request will not
		* be inserted into the queue. Instead, it is called immediately. This server call will return
		* the server we should reroute requests to, if one is specified.
		*
		* If this request is successful, MESSAGE_CONNECT will be the response, otherwise
		* MESSAGE_ERROR.
		*
		* @param clientId The product or game's client Id.
		* @param deviceId The unique Id of the device.
		* @param serverUri The Uri of the server to connect to.
		*
		* @see httpRequest
		*/
		public function connect( clientId:String, deviceId:String, serverUri:String ) : void {
			// Set the Id variables and URI
			m_clientId = clientId;
			m_deviceId = deviceId;
			m_serverUri = serverUri;
			
			// Perform the request
			httpRequest( new glsdk_dispatch( glsdk_const.API_CONNECT, "GET", {}, glsdk_const.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, connect_Done, connect_Fail ) );
		}
		
		
		/**
		* Failure callback function for the getConfig() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function getConfig_Fail( event:Object ) : void {
			trace( "getConfig_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		/**
		* Success callback function for the getConfig() http request. Adds a GET_CONFIG response
		* to the message queue.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function getConfig_Done( event:Object ) : void {
			trace( "getConfig_Done: " + event.target.data );
			
			// Parse the returned JSON and retrieve the telemetry throttle parameters
			var parsedJSON : Object = glsdk_json.instance().parse( event.target.data );
			if( parsedJSON.hasOwnProperty( "eventsDetailLevel" ) ) {
				m_config.eventsDetailLevel = parsedJSON.eventsDetailLevel;
				trace( "Found config info eventsDetailLevel: " + m_config.eventsDetailLevel );
			}
			if( parsedJSON.hasOwnProperty( "eventsPeriodSecs" ) ) {
				m_config.eventsPeriodSecs = parsedJSON.eventsPeriodSecs;
				m_telemetryQueueTimer.delay = m_config.eventsPeriodSecs * 1000;	// account for milliseconds
				trace( "Found config info eventsPeriodSecs: " + m_config.eventsPeriodSecs );
			}
			if( parsedJSON.hasOwnProperty( "eventsMinSize" ) ) {
				m_config.eventsMinSize = parsedJSON.eventsMinSize;
				trace( "Found config info eventsMinSize: " + m_config.eventsMinSize );
			}
			if( parsedJSON.hasOwnProperty( "eventsMaxSize" ) ) {
				m_config.eventsMaxSize = parsedJSON.eventsMaxSize;
				trace( "Found config info eventsMaxSize: " + m_config.eventsMaxSize );
			}
			
			pushMessageQueue( glsdk_const.MESSAGE_GET_CONFIG, event.target.data );
			
			// Once we have a successful connection, get the player info
			getPlayerInfo();
		}
		/**
		* Helper function for getting config info from the server. This particular request will not
		* be inserted into the queue. Instead, it is called immediately.
		*
		* If this request is successful, MESSAGE_GET_CONFIG will be the response, otherwise
		* MESSAGE_ERROR.
		*
		* @param serverUri The Uri of the server to connect to.
		*
		* @see httpRequest
		*/
		public function getConfig( serverUri:String ) : void {
			// Set the new URI variable returned from API_CONNECT
			m_serverUri = serverUri;
			m_gameSessionId = "";
			
			// Perform the request
			httpRequest( new glsdk_dispatch( glsdk_const.API_GET_CONFIG, "GET", {}, glsdk_const.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, getConfig_Done, getConfig_Fail ) );
		}
		
		
		/**
		* Failure callback function for the deviceUpdate() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function deviceUpdate_Fail( event:Object ) : void {
			trace( "deviceUpdate_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		/**
		* Success callback function for the deviceUpdate() http request. Adds a DEVICE_UPDATE response
		* to the message queue.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function deviceUpdate_Done( event:Object ) : void {
			trace( "deviceUpdate_Done: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_DEVICE_UPDATE, event.target.data );
		}
		/**
		* Helper function for sending a device update notification to the server. This particular request
		* will not be inserted into the queue. Instead, it is called immediately.
		*
		* If this request is successful, MESSAGE_DEVICE_UPDATE will be the response, otherwise
		* MESSAGE_ERROR.
		*
		* @see httpRequest
		*/
		public function deviceUpdate() : void {
			var postData : Object = new Object();
			postData.deviceId = m_deviceId;
			postData.gameId = m_clientId;
			
			// Perform the request
			httpRequest( new glsdk_dispatch( glsdk_const.API_POST_DEVICE_UPDATE, "POST", postData, glsdk_const.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, deviceUpdate_Done, deviceUpdate_Fail ) );
		}
		
		
		/**
		* Failure callback function for the getAuthStatus() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function getAuthStatus_Fail( event:Object ) : void {
			trace( "getAuthStatus_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		/**
		* Success callback function for the getAuthStatus() http request. Adds a AUTH_STATUS response
		* to the message queue.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function getAuthStatus_Done( event:Object ) : void {
			trace( "getAuthStatus_Done: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_AUTH_STATUS, event.target.data );
		}
		/**
		* Helper function for getting the authentication status for the cookie. This particular request
		* will not be inserted into the queue. Instead, it is called immediately.
		*
		* If this request is successful, MESSAGE_AUTH_STATUS will be the response, otherwise
		* MESSAGE_ERROR.
		*
		* @see httpRequest
		*/
		public function getAuthStatus() : void {
			// Perform the request
			httpRequest( new glsdk_dispatch( glsdk_const.API_GET_AUTH_STATUS, "GET", {}, glsdk_const.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, getAuthStatus_Done, getAuthStatus_Fail ) );
		}
		
		
		/**
		* Failure callback function for the getPlayerInfo() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function getPlayerInfo_Fail( event:Object ) : void {
			trace( "getPlayerInfo_Fail: " + event.target.data );
			
			// Set totalTimePlayed to 0 and start the timer
			m_totalTimePlayed = 0;
			m_updateTimer.start();
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		/**
		* Success callback function for the getPlayerInfo() http request. Adds a MESSAGE_GET_PLAYER_INFO
		* response to the message queue.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function getPlayerInfo_Done( event:Object ) : void {
			trace( "getPlayerInfo_Done: " + event.target.data );
			
			// Parse the returned JSON and retrieve the total time played
			var parsedJSON : Object = glsdk_json.instance().parse( event.target.data );
			if( parsedJSON.hasOwnProperty( "totalTimePlayed" ) ) {
				m_totalTimePlayed = parsedJSON.totalTimePlayed;
				writeText( "Found totalTimePlayed: " + m_totalTimePlayed );
			}
			
			// Set the last time and start the update timer
			m_updateTimer.start();
			
			pushMessageQueue( glsdk_const.MESSAGE_GET_PLAYER_INFO, event.target.data );
		}
		/**
		* Helper function for getting the total time played for the current session. This
		* particular request will not be inserted into the queue. Instead, it is called
		* immediately.
		*
		* If this request is successful, MESSAGE_GET_PLAYER_INFO will be the response, otherwise
		* MESSAGE_ERROR.
		*
		* @see httpRequest
		*/
		public function getPlayerInfo() : void {
			// Perform the request
			httpRequest( new glsdk_dispatch( glsdk_const.API_GET_PLAYER_INFO, "GET", {}, glsdk_const.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, getPlayerInfo_Done, getPlayerInfo_Fail ) );
		}
		

		/**
		* Failure callback function for the startSession() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function startSession_Fail( event:Object ) : void {
			trace( "startSession_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		/**
		* Success callback function for the startSession() http request. Adds a START_SESSION response
		* to the message queue. This response will also include JSON data with the gameSessionId
		* embedded. This Id should be set as the current gameSessionId to attach to each telemetry
		* event.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function startSession_Done( event:Object ) : void {
			trace( "startSession_Done: " + event.target.data );
			
			// Parse the returned JSON and retrieve the game session Id
			var parsedJSON : Object = glsdk_json.instance().parse( event.target.data );
			if( parsedJSON.hasOwnProperty( "gameSessionId" ) ) {
				m_gameSessionId = parsedJSON.gameSessionId;
				trace( "Found game session Id: " + m_gameSessionId );
			}
			
			pushMessageQueue( glsdk_const.MESSAGE_SESSION_START, event.target.data );
			dispatchNext();
		}
		/**
		* Helper function for starting a new session. The start session request will append the
		* deviceId, clientLevel, and current timestamp to the request.
		*
		* If this request is successful, MESSAGE_SESSION_START will be the response, otherwise
		* MESSAGE_ERROR.
		*/
		public function startSession() : void {
			var date:Date = new Date();
			
			var postData : Object = new Object();
			postData.deviceId = m_deviceId;
			postData.gameId = m_clientId;
			postData.gameLevel = m_clientLevel;
			postData.timestamp = date.time;
			
			// Reset the telemetry counter
			m_gameSessionEventOrder = 1;
			
			// Store the dispatch message to be called later
			pushTelemetryQueue( new glsdk_dispatch( glsdk_const.API_POST_SESSION_START, "POST", postData, glsdk_const.CONTENT_TYPE_APPLICATION_JSON, startSession_Done, startSession_Fail ) );
		}
		
		
		/**
		* Failure callback function for the endSession() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function endSession_Fail( event:Object ) : void {
			trace( "endSession_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		/**
		* Success callback function for the endSession() http request. Adds an END_SESSION response
		* to the message queue. This callback should also reset the current gameSessionId.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function endSession_Done( event:Object ) : void {
			trace( "endSession_Done: " + event.target.data );

			// Reset the game session Id
			m_gameSessionId = "";
			
			pushMessageQueue( glsdk_const.MESSAGE_SESSION_END, event.target.data );
			dispatchNext();
		}
		/**
		* Helper function for ending a session. The end session request will append the gameSessionId
		* and current timestamp to the request.
		*
		* If this request is successful, MESSAGE_SESSION_END will be the response, otherwise
		* MESSAGE_ERROR.
		*/
		public function endSession() : void {
			var date:Date = new Date();
			
			var postData : Object = new Object();
			postData.gameSessionId = "$gameSessionId$";
			postData.timestamp = date.time;
			
			// Store the dispatch message to be called later
			pushTelemetryQueue( new glsdk_dispatch( glsdk_const.API_POST_SESSION_END, "POST", postData, glsdk_const.CONTENT_TYPE_APPLICATION_JSON, endSession_Done, endSession_Fail ) );
				
			// Flush the queue if necessary
			if( m_flushQueueOnEndSession ) {
				telemetryDispatch( null );
				m_telemetryQueueTimer.reset();
				m_telemetryQueueTimer.start();
			}
		}
		
		
		/**
		* Failure callback function for the sendTelemEvents() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function sendTelemEvents_Fail( event:Object ) : void {
			trace( "sendTelemEvents_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
		}
		/**
		* Success callback function for the sendTelemEvents() http request. Adds an EVENTS response
		* to the message queue.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function sendTelemEvents_Done( event:Object ) : void {
			trace( "sendTelemEvents_Done: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_EVENTS, event.target.data );
			dispatchNext();
		}
		/**
		* Helper function for adding a telemetry event to the dispatch queue.
		*
		* If this request is successful, MESSAGE_EVENTS will be the response, otherwise
		* MESSAGE_ERROR.
		*/
		public function sendTelemEvents() : void {
			// Store the dispatch message to be called later
			pushTelemetryQueue( new glsdk_dispatch( glsdk_const.API_POST_EVENTS, "POST", m_telemEvents, glsdk_const.CONTENT_TYPE_APPLICATION_JSON, sendTelemEvents_Done, sendTelemEvents_Fail ) );
		}
		
		
		/**
		* Failure callback function for the sendTotalTimePlayed() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function sendTotalTimePlayed_Fail( event:Object ) : void {
			trace( "sendTotalTimePlayed_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
			dispatchNext();
		}
		/**
		* Success callback function for the sendTotalTimePlayed() http request. Adds an POST_TOTAL_TIME_PLAYED response
		* to the message queue.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function sendTotalTimePlayed_Done( event:Object ) : void {
			trace( "sendTotalTimePlayed_Done: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_POST_TOTAL_TIME_PLAYED, event.target.data );
			dispatchNext();
		}
		/**
		* Helper function for sending the total time played to the server.
		*
		* If this request is successful, MESSAGE_POST_TOTAL_TIME_PLAYED will be the response, otherwise
		* MESSAGE_ERROR.
		*/
		public function sendTotalTimePlayed() : void {
			var date:Date = new Date();
			
			var postData : Object = new Object();
			postData.setTime = m_totalTimePlayed;
			
			// Store the dispatch message to be called later
			pushTelemetryQueue( new glsdk_dispatch( glsdk_const.API_POST_TOTAL_TIME_PLAYED, "POST", postData, glsdk_const.CONTENT_TYPE_APPLICATION_JSON, sendTotalTimePlayed_Done, sendTotalTimePlayed_Fail ) );
		}
		
		
		/**
		* Failure callback function for the getAchievements() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function getAchievements_Fail( event:Object ) : void {
			trace( "sendAchievement_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
			dispatchNext();
		}
		/**
		* Success callback function for the getAchievements() http request. Adds an MESSAGE_GET_ACHIEVEMENTS response
		* to the message queue.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function getAchievements_Done( event:Object ) : void {
			trace( "sendAchievement_Done: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_GET_ACHIEVEMENTS, event.target.data );
			dispatchNext();
		}
		/**
		* Helper function for sending an achievement to the server.
		*
		* If this request is successful, MESSAGE_GET_ACHIEVEMENTS will be the response, otherwise
		* MESSAGE_ERROR.
		*/
		public function getAchievements() : void {
			// Store the dispatch message to be called later
			httpRequest( new glsdk_dispatch( glsdk_const.API_GET_ACHIEVEMENTS, "GET", {}, glsdk_const.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, getAchievements_Done, getAchievements_Fail ) );
		}
		
		
		/**
		* Failure callback function for the getSaveGame() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function getSaveGame_Fail( event:Object ) : void {
			trace( "getSaveGame_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
			dispatchNext();
		}
		/**
		* Success callback function for the getSaveGame() http request. Adds an MESSAGE_GET_SAVE_GAME response
		* to the message queue.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function getSaveGame_Done( event:Object ) : void {
			trace( "getSaveGame_Done: " + event.target.data );
			
			// Make sure we can parse binary if that's what we sent over
			var parsedJSON : Object = glsdk_json.instance().parse( event.target.data );
			if( parsedJSON.hasOwnProperty( "binary" ) ) {
				// We have binary, parse that further
				var bytes:ByteArray = Hex.toArray( parsedJSON.binary );
				bytes.inflate();
				
				// Read the save game object
				event.target.data = glsdk_json.instance().stringify( bytes.readObject() );
			}
			
			pushMessageQueue( glsdk_const.MESSAGE_GET_SAVE_GAME, event.target.data );
			dispatchNext();
		}
		/**
		* Helper function for retrieving save game data from the server.
		*
		* If this request is successful, MESSAGE_GET_SAVE_GAME will be the response, otherwise
		* MESSAGE_ERROR.
		*/
		public function getSaveGame() : void {
			// Store the dispatch message to be called later
			httpRequest( new glsdk_dispatch( glsdk_const.API_GET_SAVE_GAME, "GET", {}, glsdk_const.CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED, getSaveGame_Done, getSaveGame_Fail ) );
		}
		
		
		/**
		* Failure callback function for the postSaveGame() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function postSaveGame_Fail( event:Object ) : void {
			trace( "postSaveGame_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
			dispatchNext();
		}
		/**
		* Success callback function for the postSaveGame() http request. Adds an MESSAGE_POST_SAVE_GAME response
		* to the message queue.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function postSaveGame_Done( event:Object ) : void {
			trace( "postSaveGame_Done: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_POST_SAVE_GAME, event.target.data );
			dispatchNext();
		}
		/**
		* Helper function for posting save game data to the server.
		*
		* If this request is successful, MESSAGE_POST_SAVE_GAME will be the response, otherwise
		* MESSAGE_ERROR.
		*/
		public function postSaveGame( data:Object ) : void {
			// Store the dispatch message to be called later
			pushTelemetryQueue( new glsdk_dispatch( glsdk_const.API_POST_SAVE_GAME, "POST", data, glsdk_const.CONTENT_TYPE_APPLICATION_JSON, postSaveGame_Done, postSaveGame_Fail ) );
		}
		/**
		* Helper function for posting save game binary data to the server.
		*
		* If this request is successful, MESSAGE_POST_SAVE_GAME will be the response, otherwise
		* MESSAGE_ERROR.
		*/
		public function postSaveGameBinary( byteArray:ByteArray ) : void {
			// Call the base function accepting a generic object, after converting
			postSaveGame( { "binary": Hex.fromArray( byteArray ) } );
		}
		
		
		/**
		* Failure callback function for the saveAchievement() http request. Adds an ERROR response
		* to the message queue.
		*
		* @param event A reference to the IOErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function saveAchievement_Fail( event:Object ) : void {
			trace( "saveAchievement_Fail: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.target.data );
			dispatchNext();
		}
		/**
		* Success callback function for the saveAchievement() http request. Adds an MESSAGE_POST_ACHIEVEMENT response
		* to the message queue.
		*
		* @param event A reference to the Event object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function saveAchievement_Done( event:Object ) : void {
			trace( "saveAchievement_Done: " + event.target.data );
			
			pushMessageQueue( glsdk_const.MESSAGE_POST_ACHIEVEMENT, event.target.data );
			dispatchNext();
		}
		/**
		* Helper function for saving an achievement to the server.
		*
		* If this request is successful, MESSAGE_POST_ACHIEVEMENT will be the response, otherwise
		* MESSAGE_ERROR.
		*/
		public function saveAchievement( item:String, group:String, subGroup:String ) : void {
			var date:Date = new Date();
			
			var postData : Object = new Object();
			postData.item = item;
			postData.group = group;
			postData.subGroup = subGroup;
			
			// Store the dispatch message to be called later
			pushTelemetryQueue( new glsdk_dispatch( glsdk_const.API_POST_ACHIEVEMENTS, "POST", postData, glsdk_const.CONTENT_TYPE_APPLICATION_JSON, saveAchievement_Done, saveAchievement_Fail ) );
		}
		
		
		/**
		* Function will create a new URLRequest for server communication. The data that populates
		* the request is passed along in the glsdk_dispatch object. The URLRequest will either be
		* created with the Flash object or via ExternalInterface. If an external javascript interface
		* is available, all requests will funnel through there and callbacks will be triggered back
		* on the flash client.
		*
		* Three event listeners are attached to each request, including the success and failure
		* callback functions, and the SECURITY_ERROR event.
		*
		* @param dispatch The glsdk_dispatch object containing API path, request method,
		* post data, and callback functions.
		*
		* @see onSecurityError
		*/
		private function httpRequest( dispatch:glsdk_dispatch ) : void {
			// Set default postdata is we need to use it
			var dataAsJSON : String = "";
			
			// Check for the existence of an external interface
			// If it does exist, perform requests on the javascript layer
			if( !isLocal() && ExternalInterface.available ) {
				// Create the request object as a blob
				var req : Object = new Object();
				req.key = dispatch.m_path.KEY
				req.api = dispatch.m_path.API;
				req.method = dispatch.m_method;
				req.contentType = dispatch.m_contentType;
				
				// Parse the API path for :gameId
				req.api = req.api.split( ":gameId" ).join( m_clientId );
				trace( req.api );
				
				// Set the request data if this is a POST request
				if( dispatch.m_method == URLRequestMethod.POST ) {
					dataAsJSON = glsdk_json.instance().stringify( dispatch.m_postData );
					req.data = dataAsJSON;
				}
			
				// Call the SDK service on angular
				var result : String = ExternalInterface.call( "GlassLabSDK.request", req );
			}
			else {
				// Create a new URL request object
				var urlReq : URLRequest = new URLRequest();
				
				// Set the request attributes
				urlReq.url = m_serverUri + dispatch.m_path.API;
				urlReq.method = dispatch.m_method;
				urlReq.contentType = dispatch.m_contentType;
				
				// Parse the API path for :gameId
				urlReq.url = urlReq.url.split( ":gameId" ).join( m_clientId );
				trace( urlReq.url );
				
				// Set the request data if this is a POST request
				if( dispatch.m_method == URLRequestMethod.POST ) {
					dataAsJSON = glsdk_json.instance().stringify( dispatch.m_postData );
					urlReq.data = dataAsJSON;
				}
				
				// Create a URL loader to load the request
				var loader : URLLoader = new URLLoader();
				loader.load( urlReq );
				
				// Add necessary loader listeners
				loader.addEventListener( Event.COMPLETE, dispatch.m_successCallback );
				loader.addEventListener( IOErrorEvent.IO_ERROR, dispatch.m_failureCallback );
				loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
			}
		}
		
		/**
		* Generic success callback function for all HTTP requests going through ExternalInterface.
		*
		* @param key The api key referring to the callback function to fire.
		* @param response The server response JSON blob.
		*/
		private function eiSuccessCallback( key:String, response:String ) : void {
			//writeText( "in success (" + key + ") callback: " + response );
			
			var event:Object = {};
			event.target = { data: response };
			
			this[ key + "_Done" ]( event );
		}
		
		/**
		* Generic failure callback function for all HTTP requests going through ExternalInterface.
		*
		* @param key The api key referring to the callback function to fire.
		* @param response The server response JSON blob.
		*/
		private function eiFailureCallback( key:String, response:String ) : void {
			//writeText( "in failure (" + key + ") callback: " + response );
			
			var event:Object = {};
			event.target = { data: response };
			
			this[ key + "_Done" ]( event );
		}
		
		/**
		* Failure callback function for any security error and invalid request. Adds an ERROR
		* response to the message queue.
		*
		* @param event A reference to the SecurityErrorEvent object sent along with the listener.
		*
		* @see pushMessageQueue
		*/
		private function onSecurityError( event:SecurityErrorEvent ) : void {
			writeText( "onSecurityError: " + event.toString() );
			
			pushMessageQueue( glsdk_const.MESSAGE_ERROR, event.toString() );
		}
		
		
		/**
		* Adds a new string data field to be consumed by the next telemetry event.
		*
		* @param key The event key.
		* @param value The event value as a string.
		*/
		public function addTelemEventValue_string( key:String, value:String ) : void {
			m_telemEventValues[ key ] = value;
		}
		/**
		* Adds a new int data field to be consumed by the next telemetry event.
		*
		* @param key The event key.
		* @param value The event value as an int.
		*/
		public function addTelemEventValue_int( key:String, value:int ) : void {
			m_telemEventValues[ key ] = value;
		}
		/**
		* Adds a new uint data field to be consumed by the next telemetry event.
		*
		* @param key The event key.
		* @param value The event value as a uint.
		*/
		public function addTelemEventValue_uint( key:String, value:uint ) : void {
			m_telemEventValues[ key ] = value;
		}
		/**
		* Adds a new boolean data field to be consumed by the next telemetry event.
		*
		* @param key The event key.
		* @param value The event value as a boolean.
		*/
		public function addTelemEventValue_bool( key:String, value:Boolean ) : void {
			m_telemEventValues[ key ] = value;
		}
		/**
		* Adds a new number data field to be consumed by the next telemetry event.
		*
		* @param key The event key.
		* @param value The event value as a number.
		*/
		public function addTelemEventValue_number( key:String, value:Number ) : void {
			m_telemEventValues[ key ] = value;
		}
		
		/**
		* Helper function clears the contents of the telemetry event values. This is
		* called after each telemetry dispatch, to clear the contents for its next
		* usage.
		*/
		private function clearTelemEventValues() : void {
			m_telemEventValues = {};
		}
		
		/**
		* Helper function clears all telemetry events from the local array. This is
		* called after each telemetry dispatch.
		*/
		private function clearTelemEvents() : void {
			m_telemEvents = [];
		}
		
		/**
		* Helper function adds a new telemetry event to the local array to be dispatched
		* to the server. This function will consume and append all telemetry event values
		* added with addTelemEventValue_[type].
		*
		* Before adding to the queue for dispatch to the server, this function will also
		* append the following information to the request:
		* - clientTimeStamp
		* - eventName
		* - gameId
		* - gameSessionId
		* - gameSessionEventOrder
		* - totalTimePlayed
		* - deviceId
		* - clientVersion
		* - gameType
		*
		* @param p_eventName The name of the event to dispatch.
		*
		* @see addTelemEventValue_string
		* @see addTelemEventValue_int
		* @see addTelemEventValue_uint
		* @see addTelemEventValue_number
		*/
		public function saveTelemEvent( p_eventName:String ) : void {
			var date:Date = new Date();
			
			// Set default information
			var telemEvent : Object = {};
			telemEvent.clientTimeStamp = (int)( date.time / 1000 );
			telemEvent.eventName = p_eventName;
			telemEvent.gameId = m_clientId;
			telemEvent.gameSessionId = "$gameSessionId$";
			telemEvent.gameSessionEventOrder = m_gameSessionEventOrder++;
			telemEvent.totalTimePlayed = m_totalTimePlayed;
			
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
			//m_telemEvents.push( telemEvent );
			pushTelemetryQueue( new glsdk_dispatch( glsdk_const.API_POST_EVENTS, "POST", telemEvent, glsdk_const.CONTENT_TYPE_APPLICATION_JSON, sendTelemEvents_Done, sendTelemEvents_Fail ) );
			
			// Clear the event values
			clearTelemEventValues();
		}
		
		/**
		* Helper function adds a new telemetry event to the local array to be dispatched
		* to the server. This function accepts a JSON object blob with all event data and
		* therefore does not use the values set in the addTelemEventValue_[type] functions.
		* This function call will still empty the telemetry values.
		*
		* Before adding to the queue for dispatch to the server, this function will also
		* append the following information to the request:
		* - clientTimeStamp
		* - eventName
		* - gameId
		* - gameSessionId
		* - gameSessionEventOrder
		* - totalTimePlayed
		* - deviceId
		* - clientVersion
		* - gameType
		*
		* @param p_eventName The name of the event to dispatch.
		* @param p_eventData The object blob containing event data.
		*/
		public function saveTelemEventWithData( p_eventName:String, p_eventData:Object ) : void {
			var date:Date = new Date();
			
			// Set default information
			var telemEvent : Object = {};
			telemEvent.clientTimeStamp = (int)( date.time / 1000 );
			telemEvent.eventName = p_eventName;
			telemEvent.gameId = m_clientId;
			telemEvent.gameSessionId = "$gameSessionId$";
			telemEvent.gameSessionEventOrder = m_gameSessionEventOrder++;
			telemEvent.totalTimePlayed = m_totalTimePlayed;
			
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
			telemEvent.eventData = p_eventData;
			
			// Append this event to the events JSON object
			//m_telemEvents.push( telemEvent );
			pushTelemetryQueue( new glsdk_dispatch( glsdk_const.API_POST_EVENTS, "POST", telemEvent, glsdk_const.CONTENT_TYPE_APPLICATION_JSON, sendTelemEvents_Done, sendTelemEvents_Fail ) );
			
			// Clear the event values
			clearTelemEventValues();
		}
		
		
		/**
		* Helper function for determining which encironment this application is running in. If the
		* environment is anything but "remote", we don't want to use ExternalInterface; we'll use
		* Flash's URLRequest and URLLoader classes instead.
		*/
		private function isLocal() : Boolean {
			if( Security.sandboxType == Security.LOCAL_TRUSTED ||
				Security.sandboxType == Security.LOCAL_WITH_FILE ||
				Security.sandboxType == Security.LOCAL_WITH_NETWORK ) {
				return true;
			}
			return false;
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
		
		/*
		 * DEBUG text writing.
		 */
		public function writeText( text:String ) : void {}
	}
}