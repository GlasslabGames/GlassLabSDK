//#define TELEMETRY_DEBUG

using UnityEngine;
using System;
using System.Collections;
using System.Threading;
using System.Runtime.InteropServices;

public class GlasslabSDK {
	// -------------------------------------------------
	// Multithreaded Singleton
	private static volatile GlasslabSDK mInstance;
	private static object syncRoot = new System.Object();
	
	public static GlasslabSDK Instance {
		get {
			if (mInstance == null) {
				lock (syncRoot) {
					if (mInstance == null) 
						mInstance = new GlasslabSDK();
				}
			}
			
			return mInstance; 
		}
	}
	// -------------------------------------------------
	
	private System.IntPtr mInst;
	private bool mInstSet;
	private Thread mLoop;
	private ArrayList mConnect_CBList;
	private ArrayList mDeviceUpdate_CBList;
	private ArrayList mAuthStatus_CBList;
	private ArrayList mRegister_CBList;
	private ArrayList mLogin_CBList;
	private ArrayList mLogout_CBList;
	private ArrayList mEnroll_CBList;
	private ArrayList mUnenroll_CBList;
	private ArrayList mGetCourses_CBList;
	private ArrayList mStartSession_CBList;
	private ArrayList mEndSession_CBList;
	private ArrayList m_GameSave_CBList;
	private ArrayList m_GetGameSave_CBList;
	private ArrayList m_DeleteGameSave_CBList;
	private ArrayList m_GetUserInfo_CBList;
	private char[]    mMsgChars;
	private string    mMsgString;
	private int       mMsgCode;
	
	private bool mDataCaptureEnabled;
	private bool mResetDatabaseOnCreate;
	
	
	public enum Message {
		None = 0,
		Connect,
		DeviceUpdate,
		AuthStatus,
		Register,
		Login,
		Logout,
		Enroll,
		Unenroll,
		GetCourses,
		StartSession,
		EndSession,
		GameSave,
		GetGameSave,
		DeleteGameSave,
		GetUserInfo,
		Event,
		Error
	};
	
	public enum Status {
		Ok = 0,
		Error
	};
	
	public struct Response {
		public Message m_message;
		public string m_data;
	};
	
	public delegate void ResponseCallback( string response = "" );
	public void ResponseCallback_Stub( string response = "" ) {}
	
	
	// Delegate that a debug window could attach to in order to display all telemetry output
	public delegate void OutputStringCallback( string output );
	public static OutputStringCallback TelemetryOutput;
	
	private GlasslabSDK(){
		mConnect_CBList 	 = new ArrayList();
		mDeviceUpdate_CBList = new ArrayList();
		mAuthStatus_CBList   = new ArrayList();
		mRegister_CBList     = new ArrayList();
		mLogin_CBList        = new ArrayList();
		mLogout_CBList       = new ArrayList();
		mEnroll_CBList       = new ArrayList();
		mUnenroll_CBList     = new ArrayList();
		mGetCourses_CBList   = new ArrayList();
		mStartSession_CBList = new ArrayList();
		mEndSession_CBList   = new ArrayList();
		m_GameSave_CBList 	 = new ArrayList();
		m_GetGameSave_CBList = new ArrayList();
		m_DeleteGameSave_CBList = new ArrayList();
		m_GetUserInfo_CBList = new ArrayList();
		mInstSet = false;
		mDataCaptureEnabled = true;
		mResetDatabaseOnCreate = false;
		
		mMsgCode   = 0;
		mMsgChars  = new char[1024];
		for(int i = 0; i < mMsgChars.Length; i++) {
			mMsgChars[i] = '-';
		}
		
		#if !UNITY_EDITOR && CLASSROOM
		mLoop = new Thread( UpdateLoop );
		mLoop.Start ();
		#endif
	}
	
	public void Connect(string dataPath, string clientId, string uri = "", ResponseCallback cb = null){
		string deviceUUID = SystemInfo.deviceUniqueIdentifier;
		
		if (cb != null) {
			mConnect_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mConnect_CBList.Add (tempCB);
		}
		
		if( mInstSet ) {
			GlasslabSDK_Connect( mInst, clientId, uri );
		}
		else {
			mInst = GlasslabSDK_CreateInstance (clientId, deviceUUID, dataPath, uri);
			mInstSet = true;
			
			Debug.Log ( dataPath );
			iPhone.SetNoBackupFlag( dataPath + "/glasslabsdk.db" );
		}

		// If the client requests to reset the database, do so
		if( mInstSet && mResetDatabaseOnCreate ) {
			// We don't want to do this again!
			mResetDatabaseOnCreate = false;

			// Reset the database
			GlasslabSDK_ResetDatabase( mInst );
		}
	}
	
	private void UpdateLoop(){
		while(true) {
			
			mMsgCode   = GlasslabSDK_ReadTopMessageCode (mInst);
			if( mMsgCode != 0 ) {
				Debug.Log( "mMsgCode: " + mMsgCode);
			}
			
			IntPtr responsePtr = GlasslabSDK_ReadTopMessageString (mInst);
			mMsgString = System.Runtime.InteropServices.Marshal.PtrToStringAuto( responsePtr );
			//Debug.Log( "mMsgString " + mMsgString );
			
			switch(mMsgCode){
			case (int)GlasslabSDK.Message.Connect: {
				if(mConnect_CBList.Count > 0){
					Debug.Log ( "in CONNECT callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)mConnect_CBList[0];
					mConnect_CBList.RemoveAt (0);
					cb( mMsgString );
				}
			} break;
				
			case (int)GlasslabSDK.Message.DeviceUpdate: {
				if(mDeviceUpdate_CBList.Count > 0){
					Debug.Log ( "in DEVICE UPDATE callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)mDeviceUpdate_CBList[0];
					mDeviceUpdate_CBList.RemoveAt (0);
					cb();
				}
			} break;
				
			case (int)GlasslabSDK.Message.AuthStatus: {
				if(mAuthStatus_CBList.Count > 0){
					Debug.Log ( "in AUTH STATUS callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)mAuthStatus_CBList[0];
					mAuthStatus_CBList.RemoveAt (0);
					cb( mMsgString );
				}
			} break;
				
			case (int)GlasslabSDK.Message.Register: {
				if(mRegister_CBList.Count > 0){
					ResponseCallback cb = (ResponseCallback)mRegister_CBList[0];
					mRegister_CBList.RemoveAt (0);
					cb();
				}
			} break;
				
			case (int)GlasslabSDK.Message.Login: {
				if(mLogin_CBList.Count > 0){
					Debug.Log ( "in LOGIN callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)mLogin_CBList[0];
					mLogin_CBList.RemoveAt (0);
					cb( mMsgString );
				}
			} break;
				
			case (int)GlasslabSDK.Message.Logout: {
				if(mLogout_CBList.Count > 0){
					Debug.Log ( "in LOGOUT callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)mLogout_CBList[0];
					mLogout_CBList.RemoveAt (0);
					cb();
				}
			} break;
				
			case (int)GlasslabSDK.Message.Enroll: {
				if(mEnroll_CBList.Count > 0){
					Debug.Log ( "in ENROLL callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)mEnroll_CBList[0];
					mEnroll_CBList.RemoveAt (0);
					cb( mMsgString );
				}
			} break;
				
			case (int)GlasslabSDK.Message.Unenroll: {
				if(mUnenroll_CBList.Count > 0){
					ResponseCallback cb = (ResponseCallback)mUnenroll_CBList[0];
					mUnenroll_CBList.RemoveAt (0);
					cb();
				}
			} break;
				
			case (int)GlasslabSDK.Message.GetCourses: {
				if(mGetCourses_CBList.Count > 0){
					Debug.Log ( "in GET COURSES callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)mGetCourses_CBList[0];
					mGetCourses_CBList.RemoveAt (0);
					cb( mMsgString );
				}
			} break;
				
			case (int)GlasslabSDK.Message.StartSession: {
				if(mStartSession_CBList.Count > 0){
					Debug.Log ( "in START SESSION callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)mStartSession_CBList[0];
					mStartSession_CBList.RemoveAt (0);
					cb();
				}
			} break;
				
			case (int)GlasslabSDK.Message.EndSession: {
				if(mEndSession_CBList.Count > 0){
					Debug.Log ( "in END SESSION callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)mEndSession_CBList[0];
					mEndSession_CBList.RemoveAt (0);
					cb();
				}
			} break;
				
			case (int)GlasslabSDK.Message.GameSave: {
				if(m_GameSave_CBList.Count > 0){
					Debug.Log ( "in POST GAME SAVE callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)m_GameSave_CBList[0];
					m_GameSave_CBList.RemoveAt (0);
					cb();
				}
			} break;
				
			case (int)GlasslabSDK.Message.GetGameSave: {
				if(m_GetGameSave_CBList.Count > 0){
					Debug.Log ( "in GET GAME SAVE callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)m_GetGameSave_CBList[0];
					m_GetGameSave_CBList.RemoveAt (0);
					cb( mMsgString );
				}
			} break;
				
			case (int)GlasslabSDK.Message.DeleteGameSave: {
				if(m_DeleteGameSave_CBList.Count > 0){
					Debug.Log ( "in DELETE GAME SAVE callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)m_DeleteGameSave_CBList[0];
					m_DeleteGameSave_CBList.RemoveAt (0);
					cb( mMsgString );
				}
			} break;
				
			case (int)GlasslabSDK.Message.GetUserInfo: {
				if(m_GetUserInfo_CBList.Count > 0){
					Debug.Log ( "in GET USER INFO callback: " + mMsgString );
					ResponseCallback cb = (ResponseCallback)m_GetUserInfo_CBList[0];
					m_GetUserInfo_CBList.RemoveAt (0);
					cb( mMsgString );
				}
			} break;
				
			case (int)GlasslabSDK.Message.Event: {
			} break;
				
				// do nothing
			default: break;
			}
			
			GlasslabSDK_PopMessageStack (mInst);
			GlasslabSDK_SendTelemEvents( mInst );
			
			Thread.Sleep( 100 );
		}
	}
	
	~GlasslabSDK(){
		GlasslabSDK_FreeInstance (mInst);
		mInstSet = false;
	}
	
	public void SetDataCaptureEnabled( bool state ) {
		mDataCaptureEnabled = state;
	}

	public void ResetDatabaseOnCreate() {
		mResetDatabaseOnCreate = true;
	}
	
	// ----------------------------
	public void SetName(string name) {
		GlasslabSDK_SetName (mInst, name);
	}
	
	public void SetVersion(string version) {
		GlasslabSDK_SetVersion (mInst, version);
	}
	
	public void SetGameLevel(string gameLevel) {
		GlasslabSDK_SetGameLevel (mInst, gameLevel);
	}
	
	public void SetUserId(int userId) {
		GlasslabSDK_SetUserId (mInst, userId);
	}
	
	public void SetPlayerHandle(string handle) {
		GlasslabSDK_SetPlayerHandle( mInst, handle );
	}
	
	public void RemovePlayerHandle(string handle) {
		
	}
	
	public void SetCookie(string cookie) {
		GlasslabSDK_SetCookie( mInst, cookie );
	}
	
	public void SetAutoSessionManagement(bool state) {
		GlasslabSDK_SetAutoSessionManagement( mInst, state );
	}
	
	// ----------------------------
	public void DeviceUpdate(ResponseCallback cb = null) {
		if (cb != null) {
			mDeviceUpdate_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mDeviceUpdate_CBList.Add (tempCB);
		}
		
		GlasslabSDK_DeviceUpdate (mInst);
	}
	public void AuthStatus(ResponseCallback cb = null) {
		if (cb != null) {
			mAuthStatus_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mAuthStatus_CBList.Add (tempCB);
		}
		
		GlasslabSDK_AuthStatus (mInst);
	}
	public void RegisterStudent(string username, string password, string firstName, string lastInitial, ResponseCallback cb = null) {
		if (cb != null) {
			mRegister_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mRegister_CBList.Add (tempCB);
		}
		
		GlasslabSDK_RegisterStudent (mInst, username, password, firstName, lastInitial);
	}
	public void RegisterInstructor(string name, string email, string password, bool newsletter, ResponseCallback cb = null) {
		if (cb != null) {
			mRegister_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mRegister_CBList.Add (tempCB);
		}
		
		GlasslabSDK_RegisterInstructor (mInst, name, email, password, newsletter);
	}
	
	public void Login(string username, string password, string type = null, ResponseCallback cb = null) {
		if (cb != null) {
			mLogin_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mLogin_CBList.Add (tempCB);
		}
		
		GlasslabSDK_Login (mInst, username, password, type);
	}
	public void Login(string username, string password, ResponseCallback cb) {
		this.Login (username, password, null, cb);
	}
	
	public void Logout(ResponseCallback cb = null) {
		if (cb != null) {
			mLogout_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mLogout_CBList.Add (tempCB);
		}
		
		GlasslabSDK_Logout (mInst);
	}
	
	public void Enroll(string courseCode, ResponseCallback cb = null) {
		if (cb != null) {
			mEnroll_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mEnroll_CBList.Add (tempCB);
		}
		
		GlasslabSDK_Enroll (mInst, courseCode);
	}
	
	public void Unenroll(string courseId, ResponseCallback cb = null) {
		if (cb != null) {
			mUnenroll_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mUnenroll_CBList.Add (tempCB);
		}
		
		GlasslabSDK_UnEnroll (mInst, courseId);
	}
	
	public void GetCourses(ResponseCallback cb = null) {
		if (cb != null) {
			mGetCourses_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mGetCourses_CBList.Add (tempCB);
		}
		
		GlasslabSDK_GetCourses (mInst);
	}
	
	public void StartSession(ResponseCallback cb = null) {
		if( !mDataCaptureEnabled )	return;
		
		if (cb != null) {
			mStartSession_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mStartSession_CBList.Add (tempCB);
		}
		
		GlasslabSDK_StartSession (mInst);
	}
	
	public void EndSession(ResponseCallback cb = null) {
		if( !mDataCaptureEnabled )	return;
		
		if (cb != null) {
			mEndSession_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			mEndSession_CBList.Add (tempCB);
		}
		
		GlasslabSDK_EndSession (mInst);
	}
	
	public void CancelRequest(string key) {
		GlasslabSDK_CancelRequest( mInst, key );
	}
	
	public void SaveGame( string gameData, ResponseCallback cb = null ) {
		#if !UNITY_EDITOR && CLASSROOM
		if (cb != null) {
			m_GameSave_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			m_GameSave_CBList.Add (tempCB);
		}
		
		GlasslabSDK_SaveGame( mInst, gameData );
		#endif
	}
	
	public void GetSaveGame(ResponseCallback cb = null) {
		#if !UNITY_EDITOR && CLASSROOM
		if (cb != null) {
			m_GetGameSave_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			m_GetGameSave_CBList.Add (tempCB);
		}
		
		GlasslabSDK_GetSaveGame( mInst );
		#endif
	}
	
	public void DeleteSaveGame(ResponseCallback cb = null) {
		#if !UNITY_EDITOR && CLASSROOM
		if (cb != null) {
			m_DeleteGameSave_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			m_DeleteGameSave_CBList.Add (tempCB);
		}
		
		GlasslabSDK_DeleteSaveGame( mInst );
		#endif
	}
	
	public void GetUserInfo(ResponseCallback cb = null) {
		#if !UNITY_EDITOR && CLASSROOM
		if (cb != null) {
			m_GetUserInfo_CBList.Add (cb);
		} else {
			ResponseCallback tempCB = ResponseCallback_Stub;
			m_GetUserInfo_CBList.Add (tempCB);
		}
		
		GlasslabSDK_GetUserInfo( mInst );
		#endif
	}
	
	public void SaveAchievement( string item, string group, string subGroup ) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_SaveAchievement(mInst, item, group, subGroup);
		#else
		#if TELEMETRY_DEBUG
		Debug.Log( "---- ACHIEVEMENT: " + item + ", " + group + ", " + subGroup );
		#endif
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( "---- ACHIEVEMENT: " + item + ", " + group + ", " + subGroup );
	}
	
	// ----------------------------
	public void AddTelemEventValue(string key, string value) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_AddTelemEventValue_ccp   (mInst, key, value);
		#else
		#if TELEMETRY_DEBUG
		Debug.Log( "---------- EVENT: " + key + ": " + value );
		#endif
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( key + ": " + value );
	}
	public void AddTelemEventValue(string key, sbyte  value) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_AddTelemEventValue_int8  (mInst, key, value);
		#else
		#if TELEMETRY_DEBUG
		Debug.Log( "---------- EVENT: " + key + ": " + value );
		#endif
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( key + ": " + value.ToString() );
	}
	public void AddTelemEventValue(string key, short  value) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_AddTelemEventValue_int16 (mInst, key, value);
		#else
		#if TELEMETRY_DEBUG
		Debug.Log( "---------- EVENT: " + key + ": " + value );
		#endif
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( key + ": " + value.ToString() );
	}
	public void AddTelemEventValue(string key, int    value) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_AddTelemEventValue_int32 (mInst, key, value);
		#else
		
		#if TELEMETRY_DEBUG
		Debug.Log( "---------- EVENT: " + key + ": " + value );
		#endif
		
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( key + ": " + value.ToString() );
	}
	public void AddTelemEventValue(string key, byte   value) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_AddTelemEventValue_uint8 (mInst, key, value);
		#else
		Debug.Log( "---------- EVENT: " + key + ": " + value );
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( key + ": " + value.ToString() );
	}
	public void AddTelemEventValue(string key, ushort value) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_AddTelemEventValue_uint16(mInst, key, value);
		#else
		#if TELEMETRY_DEBUG
		Debug.Log( "---------- EVENT: " + key + ": " + value );
		#endif
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( key + ": " + value.ToString() );
	}
	public void AddTelemEventValue(string key, uint   value) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_AddTelemEventValue_uint32(mInst, key, value);
		#else
		#if TELEMETRY_DEBUG
		Debug.Log( "---------- EVENT: " + key + ": " + value );
		#endif
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( key + ": " + value.ToString() );
	}
	public void AddTelemEventValue(string key, float  value) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_AddTelemEventValue_float (mInst, key, value);
		#else
		#if TELEMETRY_DEBUG
		Debug.Log( "---------- EVENT: " + key + ": " + value );
		#endif
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( key + ": " + value.ToString() );
	}
	public void AddTelemEventValue(string key, double value) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_AddTelemEventValue_double(mInst, key, value);
		#else
		#if TELEMETRY_DEBUG
		Debug.Log( "---------- EVENT: " + key + ": " + value );
		#endif
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( key + ": " + value.ToString() );
	}
	public void AddTelemEventValue(string key, bool value) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_AddTelemEventValue_bool(mInst, key, value);
		#else
		#if TELEMETRY_DEBUG
		Debug.Log( "---------- EVENT: " + key + ": " + value );
		#endif
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( key + ": " + value.ToString() );
	}
	
	public void SaveTelemEvent(string name) {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_SaveTelemEvent (mInst, name);
		#else
		#if TELEMETRY_DEBUG
		Debug.Log( "---- TELEMETRY: " + name );
		#endif
		#endif
		
		if( TelemetryOutput != null ) TelemetryOutput( "---- EVENT: " + name + "\n" );
	}
	public void ClearTelemEventValues() {
		if( !mDataCaptureEnabled )	return;
		
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_ClearTelemEventValues (mInst);
		#endif
	}
	
	// ----------------------------
	public int GetUserId() {
		#if !UNITY_EDITOR && CLASSROOM
		int userId = GlasslabSDK_GetUserId( mInst );
		return userId;
		#else
		return -1;
		#endif
	}
	
	// ----------------------------
	public string GetCookie( bool fullCookie = false ) {
		#if !UNITY_EDITOR && CLASSROOM
		// Get the entire cookie string
		string cookie = (string)GlasslabSDK_GetCookie(mInst);
		Debug.Log("Cookie: "+cookie);

		if( fullCookie ) {
			return cookie;
		}

		// Parse the cookie portion
		// Between "connect.sid=" and ";"
		string parsedCookie = "";
		
		// Get the index of "connect.sid="
		int indexOfFirst = cookie.IndexOf( "connect.sid=" );
		if( indexOfFirst != -1 ) {
			string sub1 = cookie.Substring( indexOfFirst + 12 );
			
			// Get the next index of ";"
			int indexOfSecond = sub1.IndexOf( ";" );
			if( indexOfSecond != -1 ) {
				// Get the parsed cookie
				parsedCookie = sub1.Substring( 0, indexOfSecond );
				Debug.Log( "Parsed cookie is: " + parsedCookie );
			}
		}
		
		//connect.sid=s%3AYDGjCfDfV071rTWpki1bFaeK.%2FzUs5B2qi66zYOetVS87ONjBLHFJAS2uezXz7ikzHL4; Path=/
		//s%3AYDGjCfDfV071rTWpki1bFaeK.%2FzUs5B2qi66zYOetVS87ONjBLHFJAS2uezXz7ikzHL4
		
		// Returned the parsed cookie
		return parsedCookie;
		#else
		return "";
		#endif
	}
	
	// ----------------------------
	public string PopLogQueue() {
		#if !UNITY_EDITOR && CLASSROOM
		// Get the entire cookie string
		string log = (string)GlasslabSDK_PopLogQueue(mInst);
		if( log != null ) {
			return log;
		}
		else {
			return "";
		}
		#else
		return "";
		#endif
	}
	
	// ----------------------------
	public void UpdatePlayerInfoKey(string key, string value) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_UpdatePlayerInfoKey_ccp   (mInst, key, value);
		#endif
	}
	public void UpdatePlayerInfoKey(string key, sbyte  value) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_UpdatePlayerInfoKey_int8  (mInst, key, value);
		#endif
	}
	public void UpdatePlayerInfoKey(string key, short  value) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_UpdatePlayerInfoKey_int16 (mInst, key, value);
		#endif
	}
	public void UpdatePlayerInfoKey(string key, int    value) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_UpdatePlayerInfoKey_int32 (mInst, key, value);
		#endif
	}
	public void UpdatePlayerInfoKey(string key, byte   value) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_UpdatePlayerInfoKey_uint8 (mInst, key, value);
		#endif
	}
	public void UpdatePlayerInfoKey(string key, ushort value) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_UpdatePlayerInfoKey_uint16(mInst, key, value);
		#endif
	}
	public void UpdatePlayerInfoKey(string key, uint   value) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_UpdatePlayerInfoKey_uint32(mInst, key, value);
		#endif
	}
	public void UpdatePlayerInfoKey(string key, float  value) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_UpdatePlayerInfoKey_float (mInst, key, value);
		#endif
	}
	public void UpdatePlayerInfoKey(string key, double value) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_UpdatePlayerInfoKey_double(mInst, key, value);
		#endif
	}
	public void UpdatePlayerInfoKey(string key, bool value) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_UpdatePlayerInfoKey_bool(mInst, key, value);
		#endif
	}
	public void RemovePlayerInfoKey(string key) {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_RemovePlayerInfoKey(mInst, key);
		#endif
	}
	
	// ----------------------------
	public void StartGameTimer() {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_StartGameTimer(mInst);
		#endif
	}
	public void StopGameTimer() {
		#if !UNITY_EDITOR && CLASSROOM
		GlasslabSDK_StopGameTimer(mInst);
		#endif
	}
	
	
	//#if UNITY_IOS
	//[DllImport ("__Internal")]
	//#elif
	//[DllImport("GlasslabSDK")]
	//#endif
	//[DllImport("GlasslabSDK")]
	//public static extern int [] glClient_CreateInstance();
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern System.IntPtr GlasslabSDK_CreateInstance(string dataPath, string clientId, string deviceId, string uri);
	
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_FreeInstance(System.IntPtr inst);
	
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern int GlasslabSDK_GetLastStatus(System.IntPtr inst);
	
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_PopMessageStack(System.IntPtr inst);
	
	[DllImport ("__Internal")]
	private static extern int GlasslabSDK_ReadTopMessageCode(System.IntPtr inst);
	
	[DllImport ("__Internal")]
	private static extern IntPtr GlasslabSDK_ReadTopMessageString(System.IntPtr inst);
	
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SetName(System.IntPtr inst, string name);
	
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SetVersion(System.IntPtr inst, string version);
	
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SetGameLevel(System.IntPtr inst, string gameLevel);
	
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SetUserId(System.IntPtr inst, int userId);
	
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SetPlayerHandle(System.IntPtr inst, string handle);
	
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_RemovePlayerHandle(System.IntPtr inst, string handle);
	
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SetCookie(System.IntPtr inst, string cookie);
	
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SetAutoSessionManagement(System.IntPtr inst, bool state);
	
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_Connect(System.IntPtr inst, string gameId, string uri);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_DeviceUpdate(System.IntPtr inst);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AuthStatus(System.IntPtr inst);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_RegisterStudent(System.IntPtr inst, string username, string password, string firstName, string lastInitial);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_RegisterInstructor(System.IntPtr inst, string name, string email, string password, bool newsletter);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_GetUserInfo(System.IntPtr inst);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_Login(System.IntPtr inst, string username, string password, string type);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_Logout(System.IntPtr inst);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_Enroll(System.IntPtr inst, string courseCode);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UnEnroll(System.IntPtr inst, string courseId);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_GetCourses(System.IntPtr inst);
	
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_StartSession(System.IntPtr inst);
	
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_EndSession(System.IntPtr inst);
	
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_CancelRequest(System.IntPtr inst, string key);
	
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SaveGame(System.IntPtr inst, string gameData);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_GetSaveGame(System.IntPtr inst);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_DeleteSaveGame(System.IntPtr inst);
	
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SaveAchievement(System.IntPtr inst, string item, string group, string subGroup);
	
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AddTelemEventValue_ccp   (System.IntPtr inst, string key, string value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AddTelemEventValue_int8  (System.IntPtr inst, string key, sbyte value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AddTelemEventValue_int16 (System.IntPtr inst, string key, short value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AddTelemEventValue_int32 (System.IntPtr inst, string key, int value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AddTelemEventValue_uint8 (System.IntPtr inst, string key, byte value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AddTelemEventValue_uint16(System.IntPtr inst, string key, ushort value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AddTelemEventValue_uint32(System.IntPtr inst, string key, uint value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AddTelemEventValue_float (System.IntPtr inst, string key, float value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AddTelemEventValue_double(System.IntPtr inst, string key, double value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_AddTelemEventValue_bool	(System.IntPtr inst, string key, bool value);
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SaveTelemEvent(System.IntPtr inst, string name);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_SendTelemEvents(System.IntPtr inst);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_ClearTelemEventValues(System.IntPtr inst);
	
	
	// ----------------------------
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UpdatePlayerInfoKey_ccp   (System.IntPtr inst, string key, string value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UpdatePlayerInfoKey_int8  (System.IntPtr inst, string key, sbyte value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UpdatePlayerInfoKey_int16 (System.IntPtr inst, string key, short value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UpdatePlayerInfoKey_int32 (System.IntPtr inst, string key, int value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UpdatePlayerInfoKey_uint8 (System.IntPtr inst, string key, byte value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UpdatePlayerInfoKey_uint16(System.IntPtr inst, string key, ushort value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UpdatePlayerInfoKey_uint32(System.IntPtr inst, string key, uint value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UpdatePlayerInfoKey_float (System.IntPtr inst, string key, float value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UpdatePlayerInfoKey_double(System.IntPtr inst, string key, double value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_UpdatePlayerInfoKey_bool	 (System.IntPtr inst, string key, bool value);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_RemovePlayerInfoKey(System.IntPtr inst, string key);


	// ----------------------------
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_StartGameTimer(System.IntPtr inst);
	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_StopGameTimer(System.IntPtr inst);


	[DllImport ("__Internal")]
	private static extern void GlasslabSDK_ResetDatabase(System.IntPtr inst);


	[DllImport ("__Internal")]
	private static extern int GlasslabSDK_GetUserId(System.IntPtr inst);


	//[DllImport("<path to DLL>", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
	//[return: MarshalAs(UnmanagedType.LPStr)]
	[DllImport ("__Internal", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
	[return: MarshalAs(UnmanagedType.LPStr)]
	private static extern string GlasslabSDK_GetCookie(System.IntPtr inst);


	// ----------------------------
	[DllImport ("__Internal", CharSet = CharSet.Ansi, CallingConvention = CallingConvention.StdCall)]
	[return: MarshalAs(UnmanagedType.LPStr)]
	private static extern string GlasslabSDK_PopLogQueue(System.IntPtr inst);
}