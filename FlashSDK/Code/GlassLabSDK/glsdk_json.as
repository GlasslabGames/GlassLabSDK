package GlassLabSDK {
	
	import com.adobe.serialization.json.JSON;

	
	/**
	 * JSON wrapper allows for Flash Player 10+ compliance.
	 * Flash Player 10 uses as3corelib for JSON, which includes "encode" and "decode"
	 * Flash Player 11+ uses a native JSON library, which includes "stringify" and "parse"
	 */
	public class glsdk_json {
		
		// Singleton instance
		private static var m_instance : glsdk_json;
		public static function instance() : glsdk_json {
			if( m_instance == null ) {
				m_instance = new glsdk_json();
			}
			return m_instance;
		}
		
		
		// Stringify and parse functions
		public var stringify : Function;
		public var parse : Function;
		
		
		/**
		 * Constructor sets the correct encode and decode methods, based on supported runtime version.
		 */
		public function glsdk_json() {
			// Flash Player 10
			if( JSON[ "encode" ] ) {
				stringify = JSON[ "encode" ];
				parse = JSON[ "decode" ];
			}
			// Flash Player 11+
			else {
				stringify = JSON[ "stringify" ];
				parse = JSON[ "parse" ];
			}
		}
	}
}