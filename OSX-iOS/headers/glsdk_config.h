//
//  glsdk_config.h
//  GlasslabSDK
//
//  Authors:
//      Ben Dapkiewicz
//
//  Copyright (c) 2014 Glasslab. All rights reserved.
//


#define SDK_VERSION	"0.2"

#define DB_MESSAGE_CAP 32000

#define API_GET_CONFIG        	"/api/config"
#define API_POST_REGISTER		"/api/v2/auth/user/register"
#define API_GET_AUTH_STATUS		"/api/v2/auth/login/status"
#define API_POST_LOGIN        	"/api/user/login"
#define API_POST_LOGOUT        	"/api/user/logout"
#define API_POST_ENROLL       	"/api/v2/lms/course/enroll"
#define API_POST_UNENROLL     	"/api/v2/lms/course/unenroll"
#define API_GET_COURSES       	"/api/v2/lms/courses"
#define API_POST_SESSION_START 	"/api/v2/data/session/start"
#define API_POST_SESSION_END   	"/api/v2/data/session/end"
#define API_POST_DEVICE_UPDATE	"/api/v2/data/game/device"
#define API_POST_SAVEGAME      	"/api/v2/data/game"
#define API_GET_SAVEGAME      	"/api/v2/data/game"
#define API_POST_PLAYERINFO		"/api/v2/data/user/pref"
#define API_GET_PLAYERINFO		"/api/v2/data/user/pref"
#define API_POST_EVENTS       	"/api/v2/data/events"