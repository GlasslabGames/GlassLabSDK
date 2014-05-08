package GlassLabSDK {
	
	public class glsdk_config {
		
		public const SDK_VERSION 			: Number = 0.1;
		
		
		public const API_GET_CONFIG 		: String = "/api/config";
		public const API_GET_AUTH_STATUS 	: String = "/api/v2/auth/login/status";
		
		public const API_POST_DEVICE_UPDATE : String = "/api/v2/data/game/device";
		public const API_POST_SESSION_START : String = "/api/v2/data/session/start";
		public const API_POST_SESSION_END 	: String = "/api/v2/data/session/end";
		public const API_POST_EVENTS 		: String = "/api/v2/data/events";
		
		
		public const CONTENT_TYPE_APPLICATION_JSON					: String = "application/json";
		public const CONTENT_TYPE_APPLICATION_X_WWW_FORM_URLENCODED	: String = "application/x-www-form-urlencoded";
	}
}