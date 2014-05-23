//
//  glsdk_data_sync.h
//  GlasslabSDK
//
//  Authors:
//      Joseph Sutton
//      Ben Dapkiewicz
//
//  Copyright (c) 2014 Glasslab. All rights reserved.
//

/* ---------------------------- */
#ifndef GLASSLABSDK_DATASYNC
#define GLASSLABSDK_DATASYNC
/* ---------------------------- */


namespace nsGlasslabSDK {

    class Core;
    
    class DataSync {
    public:
        DataSync( Core* core, const char* dbPath );
        ~DataSync();
        
        // Message Queue (MSG_QUEUE) table operations
        void addToMsgQ( string deviceId, string path, string coreCB, string clientCB, string postdata, const char* contentType );
        void removeFromMsgQ( int rowId );
        void updateMessageStatus( int rowId, string status );

        // Session (SESSION) table operations
        void updateSessionTableWithCookie( string deviceId, string cookie );
        void updateSessionTableWithGameSessionId( string deviceId, string gameSessionId );
        void updateSessionTableWithPlayerHandle( string deviceIdWithHandle, string oldDeviceId );
        void removeSessionWithDeviceId( string deviceId );
        const char* getCookieFromDeviceId( string deviceId );

        // Function flushes MSG_QUEUE, converting all stored API events into HTTP requests on Core
        void flushMsgQ();

        
    private:
        // Initialization and validation
        void initDB();
        void validateSDKVersion();

        // Table create/drop/migrate functions
        void createTables();
        void dropTables();
        void migrateTables();
        void migrateTable( string table, string newSchema );
        // Debug display
        void displayTable( string table );

        // Helper function for creating a new SESSION entry
        void createNewSessionEntry( string deviceId, string cookie, string gameSessionId );

        // The SQLite database to store all API events and session information
        CppSQLite3DB m_db;

        // Core reference
        Core* m_core;
        
        // Names
        string m_dbName;
        string m_configTableName;
        string m_sessionTableName;
        string m_hmqTableName;
        string m_sql;

        // Event counts
        int m_messageTableSize;
    };
};

/* ---------------------------- */
#endif /* defined(GLASSLABSDK_DATASYNC) */
/* ---------------------------- */