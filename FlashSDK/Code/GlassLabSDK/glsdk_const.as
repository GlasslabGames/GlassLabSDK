package GlassLabSDK {
	
	public class glsdk_const {

		public static const MESSAGE_CONNECT 		: int = 0;
		public static const MESSAGE_DEVICE_UPDATE 	: int = 1;
		public static const MESSAGE_SESSION_START 	: int = 2;
		public static const MESSAGE_SESSION_END 	: int = 3;
		public static const MESSAGE_EVENTS 			: int = 4;
		public static const MESSAGE_ERROR 			: int = 5;
		
		public static const TELEMETRY_DISPATCH_TIMER	: int = 5000;	// In milliseconds
		public static const TELEMETRY_DISPATCH_CHUNK	: int = 16;		// Dispatch 16 telemetry events per tick
	}
}