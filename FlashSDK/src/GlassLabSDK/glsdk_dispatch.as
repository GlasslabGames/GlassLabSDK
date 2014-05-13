/**
* glsdk_dispatch.as
* GlassLab SDK
*
* A dispatch object represents the data that will be sent along with an HTTP request.
* The dispatch is used internally and defines callback functions for server responses.
*
* @author Ben Dapkiewicz
*
* Copyright (c) 2014 GlassLab. All rights reserved.
*/
package GlassLabSDK {
	
	public class glsdk_dispatch {

		public var m_path : String;					// The API path
		public var m_method : String;				// The method type (GET or POST)
		public var m_postData : Object;				// The post data.
		public var m_contentType : String;			// The content type.
		public var m_successCallback : Function;	// A callback function indicating a successful request.
		public var m_failureCallback : Function;	// A callback function indicating a failed request.
		
		
		/**
		* Parameterized constructor requires all fields for a successful dispatch.
		*
		* param p_path The API path.
		* param p_method The method type.
		* param p_postData The post data. This can be blank or an empty JSON object.
		* param p_contentType The content type.
		* param p_successCallback The success callback function.
		* param p_failureCallback The failure callback function.
		*/
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