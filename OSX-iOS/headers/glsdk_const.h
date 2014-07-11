//
//  glsdk_const.h
//  GlasslabSDK
//
//  Authors:
//      Joseph Sutton
//  Copyright (c) 2014 Glasslab. All rights reserved.
//

/* ---------------------------- */
#ifndef GLASSLABSDK_CONST
#define GLASSLABSDK_CONST
/* ---------------------------- */


namespace nsGlasslabSDK {
    
    typedef struct _glConfig {
        int eventsPeriodSecs;
        int eventsMinSize;
        int eventsMaxSize;
        int eventsDetailLevel;
    } glConfig;

    class Const {
    public:
        enum Status {
            Status_Ok = 0,
            Status_Error
        };
        
        enum Message {
            Message_None = 0,
            Message_Connect,
            Message_DeviceUpdate,
            Message_AuthStatus,
            Message_Register,
            Message_Login,
            Message_Logout,
            Message_Enroll,
            Message_UnEnroll,
            Message_GetCourses,
            Message_StartSession,
            Message_EndSession,
            Message_GameSave,
            Message_SavePlayerInfo,
            Message_GetPlayerInfo,
            Message_SendTotalTimePlayed,
            Message_Event,
            Message_Error
        };

        struct Response {
            Message m_message;
            std::string m_data;
        };
    };

    typedef void(*ClientCallback_Func)();
    
}; // end nsGlasslabSDK

/* ---------------------------- */
#endif /* defined(GLASSLABSDK_CONST) */
/* ---------------------------- */