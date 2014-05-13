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
		
		public static const API_GET_CONFIG 			: String = "/api/config";
		public static const API_GET_AUTH_STATUS 	: String = "/api/v2/auth/login/status";
		public static const API_POST_DEVICE_UPDATE 	: String = "/api/v2/data/game/device";
		public static const API_POST_SESSION_START 	: String = "/api/v2/data/session/start";
		public static const API_POST_SESSION_END 	: String = "/api/v2/data/session/end";
		public static const API_POST_EVENTS 		: String = "/api/v2/data/events";
		
		public static const CONTENT_TYPE_APPLICATION_JSON					: String = "application/json";
		public static const CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED	: String = "application/x-www-form-urlencoded";
		
		public static const MESSAGE_CONNECT 		: int = 0;
		public static const MESSAGE_DEVICE_UPDATE 	: int = 1;
		public static const MESSAGE_SESSION_START 	: int = 2;
		public static const MESSAGE_SESSION_END 	: int = 3;
		public static const MESSAGE_EVENTS 			: int = 4;
		public static const MESSAGE_ERROR 			: int = 5;
		
		
		public static const TELEMETRY_DISPATCH_TIMER : int = 500;	// In milliseconds
		public static const TELEMETRY_DISPATCH_CHUNK : int = 32;	// Dispatch a number of telemetry events per tick
	}
}