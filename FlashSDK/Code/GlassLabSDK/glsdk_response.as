package GlassLabSDK {
	
	public class glsdk_response {

		public var m_message : int;
		public var m_data : String;
		
		
		public function glsdk_response( message:int, data:String ) {
			m_message = message;
			m_data = data;
		}
	}
}