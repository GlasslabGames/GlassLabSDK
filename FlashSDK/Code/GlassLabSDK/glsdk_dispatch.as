package GlassLabSDK {
	
	public class glsdk_dispatch {

		public var m_path : String;
		public var m_method : String;
		public var m_postData : Object;
		public var m_contentType : String;
		public var m_successCallback : Function;
		public var m_failureCallback : Function;
		
		
		public function glsdk_dispatch( p_path:String, p_method:String, p_postData:Object, p_contentType:String, p_successCallback:Function, p_failureCallback:Function ) {
			m_path = p_path;
			m_method = p_method;
			m_postData = p_postData;
			m_contentType = p_contentType;
			m_successCallback = p_successCallback;
			m_failureCallback = p_failureCallback;
		}
	}
}