/**
* glsdk_response.as
* GlassLab SDK
*
* A response object represents a server response, including the type of message and
* accompanying JSON data. It is possible for the JSON data to be empty, which usually
* indicates success.
*
* @author Ben Dapkiewicz
*
* Copyright (c) 2014 GlassLab. All rights reserved.
*/
package GlassLabSDK {
	
	public class glsdk_response {

		public var m_message : int;	// The message type referenced from glsdk_const.
		public var m_data : String;	// The actual response data in JSON form.
		
		
		/**
		* Parameterized constructor requires all fields for the response object.
		*
		* param message An int referring to one of the message response constant.
		* param data The response data in JSON form.
		*/
		public function glsdk_response( message:int, data:String ) {
			m_message = message;
			m_data = data;
		}
	}
}