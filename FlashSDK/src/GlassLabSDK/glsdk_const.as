/**
* glsdk_const.as
* GlassLab SDK
*
* This class represents all of the static and constant information used by
* the GlassLab Core class. This includes the SDK version, API paths, content
* types, and response values.
*
* @author Ben Dapkiewicz
*
* Copyright (c) 2014 GlassLab. All rights reserved.
*/
package GlassLabSDK {
	
	public class glsdk_const {

		public static const SDK_VERSION : Number = 0.1;
		
		public static const API_GET_CONFIG 				: String = "/api/config";
		public static const API_GET_AUTH_STATUS 		: String = "/api/v2/auth/login/status";
		public static const API_POST_DEVICE_UPDATE 		: String = "/api/v2/data/game/device";
		public static const API_GET_PLAYER_INFO 		: String = "/api/v2/data/game";	// /:gameId/playInfo
		public static const API_POST_TOTAL_TIME_PLAYED 	: String = "/api/v2/data/game";	// /:gameId/totalTimePlayed
		public static const API_POST_SESSION_START 		: String = "/api/v2/data/session/start";
		public static const API_POST_SESSION_END 		: String = "/api/v2/data/session/end";
		public static const API_POST_EVENTS 			: String = "/api/v2/data/events";
		
		public static const CONTENT_TYPE_APPLICATION_JSON					: String = "application/json";
		public static const CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED	: String = "application/x-www-form-urlencoded";
		
		public static const MESSAGE_CONNECT 				: int = 0;
		public static const MESSAGE_AUTH_STATUS				: int = 1;
		public static const MESSAGE_DEVICE_UPDATE 			: int = 2;
		public static const MESSAGE_GET_PLAYER_INFO			: int = 3;
		public static const MESSAGE_POST_TOTAL_TIME_PLAYED	: int = 4;
		public static const MESSAGE_SESSION_START 			: int = 5;
		public static const MESSAGE_SESSION_END 			: int = 6;
		public static const MESSAGE_EVENTS 					: int = 7;
		public static const MESSAGE_ERROR 					: int = 8;
		
		public static const UPDATE_TIMER				: int = 3;	// Update function is called at this interval
		public static const TELEMETRY_DISPATCH_CHUNK 	: int = 32;	// Dispatch a number of telemetry events per tick
		
		public static const THROTTLE_PRIORITY_DEFAULT : int = 10;		// Default priority level for throttling telemetry
		public static const THROTTLE_INTERVAL_DEFAULT : int = 30000;	// Default request interval to throttle telemetry (milliseconds)
		public static const THROTTLE_MIN_SIZE_DEFAULT : int = 5;		// Minimum number of events to reach before sending telemetry
		public static const THROTTLE_MAX_SIZE_DEFAULT : int = 100;		// Maximum number of events reached will send telemetry
	}
}