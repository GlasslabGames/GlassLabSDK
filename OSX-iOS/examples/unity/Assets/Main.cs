using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
using System.Collections;
using System.Threading;
using System.Runtime.InteropServices;

public class Main : MonoBehaviour {
	private GlasslabSDK glsdk;

	void Start() {
		glsdk = GlasslabSDK.Instance;

		glsdk.Connect( "MAG-1", "http://myURL.org" );
		glsdk.SetName( "My Awesome Game" );
		glsdk.SetVersion( "1.0" );
		
		Debug.Log( "Login..." );
		glsdk.Login( "testUsername", "testPassword", LoginDone );
	}

	private void LoginDone( string response ) {
		Debug.Log( "Login complete: " + response );

		Debug.Log( "Start Session..." );
		glsdk.StartSession( StartSessionDone );
	}

	private void StartSessionDone( string response ) {
		Debug.Log( "Start Session complete: " + response );

		Debug.Log( "Saving Events..." );
		for( int i = 1; i < 4; i++ ){
			glsdk.AddTelemEventValue( "string key", "asd" );
			glsdk.AddTelemEventValue( "int key", i );
			glsdk.AddTelemEventValue( "float key", i * 1.23 );
			
			glsdk.SaveTelemEvent( "SampleEvent" );

			Thread.Sleep( 1 );
		}
		Debug.Log( "Done Saving Events" );

		Thread.Sleep( 2 );
		
		Debug.Log( "End Session..." );
		glsdk.EndSession( EndSessionDone );
	}

	private void EndSessionDone( string response ) {
		Debug.Log( "End Session complete: " + response );
	}
}