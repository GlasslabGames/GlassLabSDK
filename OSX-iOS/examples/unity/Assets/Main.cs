using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
using System.Collections;
using System.Threading;
using System.Runtime.InteropServices;

public class Main : MonoBehaviour {
	private GlasslabSDK glsdk;

	void Start () {
		glsdk = GlasslabSDK.Instance;

		glsdk.Connect ("SC-1", "http://192.168.1.141:8000");
		glsdk.SetName ("SimCityEdu");
		glsdk.SetVersion ("1.2.4156");
		glsdk.SetGameLevel ("397255e0-fee0-11e2-ab09-1f14110c1a8d");

		glsdk.EnableFileLogging (Application.persistentDataPath);
		
		Debug.Log("Login...");
		glsdk.Login ("test2", "test", LoginDone);
	}

	private void LoginDone(){
		Debug.Log("Start Session...");
		glsdk.StartSession (StartSessionDone);
	}

	private void StartSessionDone(){
		Debug.Log("Saving Events...");
		for(int i = 1; i < 4; i++){
			glsdk.AddTelemEventValue ("string key", "asd");
			glsdk.AddTelemEventValue ("int key",    i);
			glsdk.AddTelemEventValue ("float key",  i * 1.23);
			
			glsdk.SaveTelemEvent ("$ScenarioScore"); // clears all added event values
			Thread.Sleep (1);
		}
		Debug.Log("Done Saving Events");

		Thread.Sleep (2);
		Debug.Log("End Session...");
		glsdk.EndSession (EndSessionDone);
	}

	private void EndSessionDone(){
		Debug.Log("all done!");
	}
}
