//
//  glsdk_data_sync.cpp
//  GlasslabSDK
//
//  Authors:
//      Joseph Sutton
//      Ben Dapkiewicz
//
//  Copyright (c) 2014 Glasslab. All rights reserved.
//

#include "glasslab_sdk.h"
#include "glsdk_config.h"


namespace nsGlasslabSDK {

    /**
     * DataSync constructor creates the SQLite database.
     */
    DataSync::DataSync( Core* core, const char* dbPath ) {
        // Set the Core SDK object
        m_core = core;

        // Set the path for the database
        char result[100];
        strcpy( result, dbPath );
        strcat( result, "/glasslabsdk.db" );

        m_core->logMessage( "Database file:", result );
        //cout << "Database file: " << result << endl;

        // Set database and table names
        m_dbName = result;
        m_configTableName = CONFIG_TABLE_NAME;// "CONFIG";
        m_hmqTableName = MSG_QUEUE_TABLE_NAME;//"MSG_QUEUE";
        m_sessionTableName = SESSION_TABLE_NAME;//"SESSION";
        
        // Open the database
        initDB();

        // Check the SDK version and do a comparison with the stored version
        validateSDKVersion();

        // Create the tables needed (tables that already exist will be ignored)
        createTables();
    }

    /**
     * DataSync deconstructor closes the SQLite database
     */
    DataSync::~DataSync() {
        cout << endl << endl << "Destructor has been called" << endl << endl;
        try {
            m_db.close();
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::~DataSync()", e.errorMessage() );
            //cout << "Exception in ~DataSync() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    
    //--------------------------------------
    //--------------------------------------
    //--------------------------------------
    /**
     * Function opens the SQLite database.
     */
    void DataSync::initDB() {
        try {
            cout << "SQLite Version: " << m_db.SQLiteVersion() << endl;
            cout << "------------------------------------" << endl;

            // Open the database
            m_db.open( m_dbName.c_str() );
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::initDB()", e.errorMessage() );
            //cout << "Exception in initDB() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * Function validates the SDK version by searching for an entry in the CONFIG table.
     * If there is a version mismatch, the database is reset.
     */
    void DataSync::validateSDKVersion() {
        try {
            cout << "Current SDK_VERSION: " << SDK_VERSION << endl;

            // Set a state for if we need to drop the tables and reset
            bool resetTables = false;
            // Set a state for if we need to migrate the contents of one table to another
            // This will occur when columns have either been added or deleted in a table
            bool performMigration = false;

            // If the CONFIG table doesn't exist, be sure to drop it
            if( !m_db.tableExists( m_configTableName.c_str() ) ) {
                resetTables = true;
                cout << m_configTableName << " does not exist!" << endl;
            }
            // The table does exist, check the version field in there
            else {
                m_sql = "select * from " + m_configTableName + ";";
                cout << "SQL: " << m_sql << endl;
                CppSQLite3Query q = m_db.execQuery( m_sql.c_str() );

                // If the table is empty, reset
                if( q.eof() ) {
                    resetTables = true;
                    cout << "No entry exists in " << m_configTableName << endl;
                }
                // There is an entry, grab it
                else {
                    float configSDKVersion = (float)atof( q.fieldValue( 0 ) );
                    cout << "CONFIG entry: " << q.fieldValue( 0 ) << endl;

                    // If the stored SDK version is less than current, update it
                    if( configSDKVersion < (float)atof( SDK_VERSION ) ) {
                        m_sql = "update " + m_configTableName + " set version='" + SDK_VERSION + "'";
                        cout << "SQL: " << m_sql << endl;
                        int nRows = m_db.execDML( m_sql.c_str() );
                        cout << nRows << " rows updated in " << m_configTableName << endl;

                        // Indicate that a table migration is required
                        performMigration = true;
                    }
                }

                // Finalize the query
                q.finalize();
            }

            // Reset the tables if we need to
            if( resetTables ) {
                cout << "Need to drop the tables in " << m_configTableName << endl;
                dropTables();
            }
            // Or migrate the contents if we need to
            else if( performMigration ) {
                cout << "We need to perform a data migration, schemas may have changed." << endl;
                migrateTables();
            }
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::validateSDKVersion()", e.errorMessage() );
            //cout << "Exception in validateSDKVersion() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }


    //--------------------------------------
    //--------------------------------------
    //--------------------------------------
    /**
     * MSG_QUEUE operation.
     *
     * Inserts a new entry into the MSG_QUEUE table.
     */
    void DataSync::addToMsgQ( string deviceId, string path, string coreCB, string clientCB, string postdata, const char* contentType ) {
        if( m_messageTableSize > DB_MESSAGE_CAP ) {
            cout << "------------------------------------" << endl;
            cout << "Database has reached a message cap! No longer inserting events!" << endl;
            cout << "------------------------------------" << endl;
            return;
        }

        // string stream
        ostringstream s;
        
        try {
            //cout << "------------------------------------" << endl;
            s << "INSERT INTO " << m_hmqTableName << ""
            " (deviceId, path, coreCB, clientCB, postdata, contentType, status) "
            "VALUES ('" << deviceId << "', ";

            // Check the API path
            if( path.c_str() == 0 ) {
               s << "''";
            }
            else {
                s << "'";
                s << path;
                s << "'";
            }
            s << ", ";

            // Check the Core Callback key
            if( coreCB.c_str() == 0 ) {
               s << "''";
            }
            else {
                s << "'";
                s << coreCB;
                s << "'";
            }
            s << ", ";
            
            // Check the Client Callback key
            if( clientCB.c_str() == 0 ) {
                s << "''";
            }
            else {
                s << "'";
                s << clientCB;
                s << "'";
            }
            s << ", ";
            
            // Check the postdata
            if( postdata.c_str() == 0 ) {
                s << "''";
            }
            else {
                // Replace all ' characters with escapes: \'
                string characterToSearch = "'";
                string characterToReplace = "''";
                string::size_type n = 0;
                while( ( n = postdata.find( characterToSearch, n ) ) != string::npos ) {
                    postdata.replace( n, 1, characterToReplace );
                    n += 2;
                }

                s << "'";
                s << postdata;
                s << "'";
            }
            s << ", ";
            
            // Check the content type
            if( contentType == 0 ) {
                s << "''";
            }
            else {
                s << "'";
                s << contentType;
                s << "'";
            }
            s << ", 'ready'";
            s << ");";
            m_sql = s.str();
        
            // Execute the insertion
            //cout << "SQL: " << m_sql << endl;
            int nRows = m_db.execDML( m_sql.c_str() );
            //cout << nRows << " rows inserted" << endl;
            //cout << "------------------------------------" << endl;

            // Set the message table size
            //m_sql = "select * from " + m_hmqTableName;
            //CppSQLiteTable t = db.getTable( m_sql.c_str() );
            m_messageTableSize++;
            
            // Debug display
            //displayTable( m_hmqTableName );
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::addToMsgQ()", e.errorMessage() );
            //cout << "Exception in addToMsgQ() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * MSG_QUEUE operation.
     *
     * Removes an existing entry from MSG_QUEUE using the rowId.
     */
    void DataSync::removeFromMsgQ( int rowId ) {
        try {
            // string stream
            ostringstream s;

            // Remove the entry at rowId
            s << "delete from " << m_hmqTableName << " where id=" << rowId;
            m_sql = s.str();
            //cout << "delete SQL: " << m_sql << endl;
            int r = m_db.execDML( m_sql.c_str() );
            //cout << "Deleting result: " << r << endl;

            // Set the message table size
            //m_sql = "select * from " + m_hmqTableName;
            //CppSQLiteTable t = db.getTable( m_sql.c_str() );
            m_messageTableSize--;
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::removeFromMsgQ()", e.errorMessage() );
            //cout << "Exception in removeFromMsgQ() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * MSG_QUEUE operation.
     *
     * Updates the status of an existing entry in MSG_QUEUE using the rowId.
     */
    void DataSync::updateMessageStatus( int rowId, string status ) {
        try {
            // If the status is success, remove the entry from the db
            if( status == "success" ) {
                cout << "Successful request, removing entry from database." << endl;
                removeFromMsgQ( rowId );
            }
            // Else, update the entry's status field
            else {
                // string stream
                ostringstream s;

                // Execute the update operation
                s << "UPDATE " << m_hmqTableName << " SET status='" << status << "' WHERE id='" << rowId << "'";
                m_sql = s.str();
                //cout << "update SQL: " << m_sql << endl;
                int r = m_db.execDML( m_sql.c_str() );
                //cout << "Updating result: " << r << endl;
            }
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::updateMessageStatus()", e.errorMessage() );
            //cout << "Exception in updateMessageStatus() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * MSG_QUEUE operation.
     *
     * Returns the current size of the message queue table.
     */
    int DataSync::getMessageTableSize() {
        return m_messageTableSize;
    }


    //--------------------------------------
    //--------------------------------------
    //--------------------------------------
    /**
     * SESSION operation.
     *
     * Updates an existing session with a valid cookie, or inserts a new entry with
     * the cookie and deviceId.
     */
    void DataSync::updateSessionTableWithCookie( string deviceId, string cookie ) {
        // string stream
        ostringstream s;
        
        try {
            // Display the session table
            //displayTable( m_sessionTableName );
            
            // Look for an existing entry with the device Id
            cout << "------------------------------------" << endl;
            m_sql = "select * from " + m_sessionTableName + " where deviceId='" + deviceId + "';";
            cout << "session SQL: " << m_sql << endl;
            CppSQLite3Query sessionQuery = m_db.execQuery( m_sql.c_str() );

            // If the count is 0, insert a new entry
            if( sessionQuery.eof() ) {
                cout << "EMPTY: need to insert\n";

                // Create a new session entry
                createNewSessionEntry( deviceId, cookie, "" );
            }
            // Otherwise, update an existing entry
            else {
                cout << "FOUND:\n";
                for( int fld = 0; fld < sessionQuery.numFields(); fld++ ) {
                    cout << sessionQuery.fieldValue( fld ) << " | ";
                }
                cout << endl;

                // Update
                cout << "UPDATING " << m_sessionTableName << " with cookie: " << cookie << endl;
                s << "UPDATE " << m_sessionTableName << " SET cookie='" << cookie << "' WHERE deviceId='" << deviceId << "'";
                m_sql = s.str();
            }

            // Finalize the query
            //sessionQuery.finalize();
        
            cout << "SQL: " << m_sql << endl;
            int nRows = m_db.execDML( m_sql.c_str() );
            cout << nRows << " rows inserted" << endl;
            cout << "------------------------------------" << endl;
            
            
            displayTable( m_sessionTableName );
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::updateSessionTableWithCookie()", e.errorMessage() );
            //cout << "Exception in updateSessionTableWithCookie() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * SESSION operation.
     *
     * Updates an existing session with a valid gameSessionId, or inserts a new entry with
     * the gameSessionId and deviceId.
     */
    void DataSync::updateSessionTableWithGameSessionId( string deviceId, string gameSessionId ) {
        // string stream
        ostringstream s;
        
        try {
            // Display the session table
            //displayTable( m_sessionTableName );
            
            // Look for an existing entry with the device Id
            cout << "------------------------------------" << endl;
            m_sql = "select * from " + m_sessionTableName + " where deviceId='" + deviceId + "';";
            cout << "session SQL: " << m_sql << endl;
            CppSQLite3Query sessionQuery = m_db.execQuery( m_sql.c_str() );

            // If the count is 0, insert a new entry
            if( sessionQuery.eof() ) {
                cout << "EMPTY: need to insert\n";

                // Create a new session entry
                createNewSessionEntry( deviceId, "", gameSessionId );
            }
            // Otherwise, update an existing entry
            else {
                cout << "FOUND:\n";
                for ( int fld = 0; fld < sessionQuery.numFields(); fld++ ) {
                    cout << sessionQuery.fieldValue( fld ) << " | ";
                }
                cout << endl;

                // Update
                cout << "UPDATING " << m_sessionTableName << " with gameSessionId: " << gameSessionId << endl;
                s << "UPDATE " << m_sessionTableName << " SET gameSessionId='" << gameSessionId << "', gameSessionEventOrder='" << 1 << "' WHERE deviceId='" << deviceId << "'";
                m_sql = s.str();
            }

            // Finalize the query
            //sessionQuery.finalize();
        
            cout << "SQL: " << m_sql << endl;
            int nRows = m_db.execDML( m_sql.c_str() );
            cout << nRows << " rows inserted" << endl;
            cout << "------------------------------------" << endl;
            
            
            displayTable( m_sessionTableName );
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::updateSessionTableWithGameSessionId()", e.errorMessage() );
            //cout << "Exception in updateSessionTableWithGameSessionId() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * SESSION operation.
     *
     * Updates an existing session with a replacement deviceId, or inserts a new entry with
     * the deviceId. The new deviceId will include a player handle, in the form of "handle_deviceId".
     */
    void DataSync::updateSessionTableWithPlayerHandle( string deviceIdWithHandle ) {
        // string stream
        ostringstream s;
        
        try {
            // Display the session table
            //displayTable( m_sessionTableName );
            
            // Look for an existing entry with the device Id
            cout << "------------------------------------" << endl;
            m_sql = "select * from " + m_sessionTableName + " where deviceId='" + deviceIdWithHandle + "';";
            cout << "session SQL: " << m_sql << endl;
            CppSQLite3Query sessionQuery = m_db.execQuery( m_sql.c_str() );

            // If the count is 0, insert a new entry
            if( sessionQuery.eof() ) {
                cout << "session table missing new device id: " << deviceIdWithHandle << "\n";

                // Create a new session entry
                createNewSessionEntry( deviceIdWithHandle, "", "" );

                // Perform the operation
                cout << "SQL: " << m_sql << endl;
                int nRows = m_db.execDML( m_sql.c_str() );
                cout << nRows << " rows inserted" << endl;
                cout << "------------------------------------" << endl;
            }
            // Otherwise, update an existing entry
            else {
                cout << "FOUND entry with new device Id, we can ignore\n";
            }

            // Finalize the query
            //sessionQuery.finalize();
            
            displayTable( m_sessionTableName );
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::updateSessionTableWithPlayerHandle()", e.errorMessage() );
            //cout << "Exception in updateSessionTableWithPlayerHandle() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * SESSION operation.
     *
     * Removes the session entry associated with the parameter deviceId.
     */
    void DataSync::removeSessionWithDeviceId( string deviceId ) {
        try {
            // Remove the entry with the associated deviceId
            m_sql = "delete from " + m_sessionTableName + " where deviceId='" + deviceId + "';";
            cout << "delete SQL: " << m_sql << endl;
            int r = m_db.execDML( m_sql.c_str() );
            cout << "Deleting result: " << r << endl;
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::removeSessionWithDeviceId()", e.errorMessage() );
            //cout << "Exception in removeSessionWithDeviceId() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * SESSION operation.
     *
     * Gets a cookie stored in the SESSION table using the deviceId.
     */
    const char* DataSync::getCookieFromDeviceId( string deviceId ) {
        // string stream
        ostringstream s;
        
        try {
            // Display the session table
            displayTable( m_sessionTableName );
            
            // Look for an existing entry with the device Id
            m_sql = "select * from " + m_sessionTableName + " where deviceId='" + deviceId + "';";
            CppSQLite3Query sessionQuery = m_db.execQuery( m_sql.c_str() );

            // Finalize the query
            //sessionQuery.finalize();

            // If the count is 0, no entry exists with deviceId, return an empty string
            // The empty string will tell the next get request that we need one to store
            if( sessionQuery.eof() ) {
                cout << "no cookie exists for " << deviceId.c_str() << endl;
                return "";
            }
            // An entry does exist, grab the cookie and return it
            else {
                string cookie = sessionQuery.fieldValue( 0 );
                cout << "cookie exists for " << deviceId.c_str() << ": " << cookie.c_str() << endl;
                return cookie.c_str();
            }
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::getCookieFromDeviceId()", e.errorMessage() );
            //cout << "Exception in getCookieFromDeviceId() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }

        // Return empty string by default
        return "";
    }

    /**
     * SESSION operation.
     *
     * Updates an existing session with player info, including total time played and the current game session event order.
     */
    void DataSync::updatePlayerInfoFromDeviceId( string deviceId, float totalTimePlayed, int gameSessionEventOrder ) {
        // string stream
        ostringstream s;
        
        try {
            // Look for an existing entry with the device Id
            //cout << "------------------------------------" << endl;
            m_sql = "select * from " + m_sessionTableName + " where deviceId='" + deviceId + "';";
            //cout << "session SQL: " << m_sql << endl;
            CppSQLite3Query sessionQuery = m_db.execQuery( m_sql.c_str() );

            // Only continue if an entry exists
            if( !sessionQuery.eof() ) {
                // Update
                s << "UPDATE " << m_sessionTableName << " SET totalTimePlayed='" << totalTimePlayed << "', gameSessionEventOrder='" << gameSessionEventOrder << "' WHERE deviceId='" << deviceId << "'";
                m_sql = s.str();

                //cout << "SQL: " << m_sql << endl;
                int nRows = m_db.execDML( m_sql.c_str() );
                //cout << nRows << " rows inserted" << endl;
                //cout << "------------------------------------" << endl;
            }

            // Finalize the query
            //sessionQuery.finalize();
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::updatePlayerInfoFromDeviceId()", e.errorMessage() );
            //cout << "Exception in updatePlayerInfoFromDeviceId() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * SESSION operation.
     *
     * Get the totalTimePlayed stored in the SESSION table using the deviceId.
     */
    float DataSync::getTotalTimePlayedFromDeviceId( string deviceId ) {
        try {
            // Look for an existing entry with the device Id
            m_sql = "select * from " + m_sessionTableName + " where deviceId='" + deviceId + "';";
            CppSQLite3Query sessionQuery = m_db.execQuery( m_sql.c_str() );

            // Finalize the query
            //sessionQuery.finalize();

            // If the count is 0, no entry exists with deviceId, return a default value of 0.0
            if( sessionQuery.eof() ) {
                cout << "totalTimePlayed does not exist for " << deviceId.c_str() << endl;
                return 0.0;
            }
            // An entry does exist, grab the totalTimePlayed and return it
            else if( sessionQuery.fieldValue( 4 ) != NULL ) {
                float totalTimePlayed = atof( sessionQuery.fieldValue( 4 ) );
                cout << "totalTimePlayed exists for " << deviceId.c_str() << ": " << totalTimePlayed << endl;
                return totalTimePlayed;
            }
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::getTotalTimePlayedFromDeviceId()", e.errorMessage() );
            //cout << "Exception in getTotalTimePlayedFromDeviceId() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }

        // Return 0.0 by default
        return 0.0;
    }

    /**
     * SESSION operation.
     *
     * Update the gameSessionEventOrder stored in the SESSION table using the deviceId.
     */
    void DataSync::updateGameSessionEventOrderWithDeviceId( string deviceId, int gameSessionEventOrder ) {
        // string stream
        ostringstream s;
        
        try {
            // Update the SESSION table with the new gameSessionEventOrder value
            s << "UPDATE " << m_sessionTableName << " SET gameSessionEventOrder='" << gameSessionEventOrder << "' WHERE deviceId='" << deviceId << "';";
            m_sql = s.str();
            cout << "update SQL: " << m_sql << endl;
            int r = m_db.execDML( m_sql.c_str() );
            cout << "Updating gameSessionEventOrder result: " << r << endl;
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::updateGameSessionEventOrderWithDeviceId()", e.errorMessage() );
            //cout << "Exception in updateGameSessionEventOrderWithDeviceId() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * SESSION operation.
     *
     * Get the gameSessionEventOrder stored in the SESSION table using the deviceId.
     */
    int DataSync::getGameSessionEventOrderFromDeviceId( string deviceId ) {
        try {
            // Look for an existing entry with the device Id
            m_sql = "select * from " + m_sessionTableName + " where deviceId='" + deviceId + "';";
            CppSQLite3Query sessionQuery = m_db.execQuery( m_sql.c_str() );

            // Finalize the query
            //sessionQuery.finalize();

            // If the count is 0, no entry exists with deviceId, return a default value of 1
            if( sessionQuery.eof() ) {
                cout << "gameSessionEventOrder does not exist for " << deviceId.c_str() << endl;
                return 1;
            }
            // An entry does exist, grab the gameSessionEventOrder and return it
            else if( sessionQuery.fieldValue( 3 ) != NULL ) {
                int gameSessionEventOrder = atoi( sessionQuery.fieldValue( 3 ) );
                cout << "gameSessionEventOrder exists for " << deviceId.c_str() << ": " << gameSessionEventOrder << endl;
                return gameSessionEventOrder;
            }
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::getGameSessionEventOrderFromDeviceId()", e.errorMessage() );
            //cout << "Exception in getGameSessionEventOrderFromDeviceId() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }

        // Return 1 by default
        return 1;
    }

    /**
     * SESSION operation.
     *
     * Inserts a new session object into SESSION.
     */
    void DataSync::createNewSessionEntry( string deviceId, string cookie, string gameSessionId ) {
        try {
            // Insert
            ostringstream s;
            s << "INSERT INTO " << m_sessionTableName << " VALUES (";

            // Check the cookie
            if( cookie.c_str() == 0 ) {
               s << "''";
            }
            else {
               s << "'";
               s << cookie;
               s << "'";
            }
            s << ", ";

            // Check the deviceId
            if( deviceId.c_str() == 0 ) {
               s << "0";
            }
            else {
               s << "'";
               s << deviceId;
               s << "'";
            }
            s << ", ";
            
            // Check the gameSessionId
            if( gameSessionId.c_str() == 0 ) {
                s << "0";
            }
            else {
                s << "'";
                s << gameSessionId;
                s << "'";
            }
            s << ", ";

            // Include the gameSessionEventOrder (defaults to 1)
            s << "'";
            s << "1";
            s << "'";
            s << ", ";

            // Include the totalTimePlayed (defaults to 0.0)
            s << "'";
            s << "0.0";
            s << "'";

            // Close the SQL statement
            s << ");";

            // Set the SQLite string to execute
            m_sql = s.str();
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::createNewSessionEntry()", e.errorMessage() );
            //cout << "Exception in createNewSessionEntry() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }


    //--------------------------------------
    //--------------------------------------
    //--------------------------------------
    /**
     * Function flushes the MSG_QUEUE table, parsing the data in each entry to send
     * them to Core for an HTTP request to the server. All data must be valid, otherwise
     * it remains in the queue or is removed.
     */
    void DataSync::flushMsgQ() {
        try {
            // Begin display out
            //cout << "\n\n\n-----------------------------------" << endl;
            cout << "\tflushing MSG_QUEUE: " << m_messageTableSize << endl;
            m_core->logMessage( "flushing MSG_QUEUE" );

            // Select all entries in MSG_QUEUE
            m_sql = "select * from " + m_hmqTableName + ";";
            cout << "msgQ SQL: " << m_sql << endl;
            CppSQLite3Query msgQuery = m_db.execQuery( m_sql.c_str() );

            // Finalize the query
            //msgQuery.finalize();

            // Keep a counter for the number of requests made so we can limit it
            int requestsMade = 0;

            // Iterate 
            while ( !msgQuery.eof() )
            {
                // Print the entry to consider
                /*cout << "Entry: ";
                for( int fld = 0; fld < msgQuery.numFields(); fld++ ) {
                    cout << msgQuery.fieldValue( fld ) << "|";
                }
                cout << endl;*/

                /*
                This message will contain the following information:
                - id
                - deviceId
                - path
                - coreCB
                - clientCB
                - postdata
                - contentType
                - status (ready, pending, failed, success)

                A session will contain the following information:
                - cookie
                - deviceId
                - gameSessionId
                - gameSessionEventOrder
                - totalTimePlayed
                */

                // Check the deviceId listed in the message for an entry in the SESSION table
                // If the deviceId is empty, which should not open, we should skip this entry
                // or remove it from MSG_QUEUE (?)
                int rowId = atoi( msgQuery.fieldValue( 0 ) );
                string deviceId = msgQuery.fieldValue( 1 );
                if( deviceId.c_str() != NULL ) {
                    // Select all entries in SESSION with deviceId
                    displayTable( m_sessionTableName );
                    m_sql = "select * from " + m_sessionTableName + " where deviceId='" + deviceId + "';";
                    //cout << "session SQL: " << m_sql << endl;
                    CppSQLite3Query sessionQuery = m_db.execQuery( m_sql.c_str() );

                    // Finalize the query
                    //sessionQuery.finalize();

                    // Only continue if we received an entry from SESSION
                    if( !sessionQuery.eof() ) {
                        // Get the cookie field
                        string cookie = sessionQuery.fieldValue( 0 );

                        // Only continue if the cookie exists
                        if( cookie.c_str() != NULL ) {
                            //cout << "cookie is: " << cookie << endl;

                            // Get the path from MSG_QUEUE
                            string apiPath = msgQuery.fieldValue( 2 );
                            //cout << "api path is: " << apiPath << endl;

                            // We only care about startsession, endsession, and sendtelemetry
                            // Anything else should be ignored (and not present in the queue)
                            // Only continue with endsession and sendtelemetry if gameSessionId
                            // exists in the SESSION entry
                            string gameSessionId = sessionQuery.fieldValue( 2 );
                            //cout << "game session Id is: " << gameSessionId << endl;
                            if( apiPath == API_POST_SESSION_START ||
                                strstr( apiPath.c_str(), API_POST_SAVEGAME ) ||
                                strstr( apiPath.c_str(), API_POST_PLAYERINFO ) ||
                                ( ( apiPath == API_POST_SESSION_END || apiPath == API_POST_EVENTS ) &&
                                   gameSessionId.c_str() != NULL && gameSessionId.c_str() != ""
                                )
                              ) {

                                //cout << "performing the GET request for: " << apiPath << endl;

                                // Get the event information
                                string coreCB = msgQuery.fieldValue( 3 );
                                string clientCB = msgQuery.fieldValue( 4 );
                                string postdata = msgQuery.fieldValue( 5 );
                                const char* contentType = msgQuery.fieldValue( 6 );

                                // If this is a telemetry event or end session, update the postdata to include the correct gameSessionId
                                if( apiPath == API_POST_EVENTS || apiPath == API_POST_SESSION_END ) {
                                    string gameSessionIdTag = "$gameSessionId$";

                                    string::size_type n = 0;
                                    while( ( n = postdata.find( gameSessionIdTag, n ) ) != string::npos ) {
                                        postdata.replace( n, gameSessionIdTag.size(), gameSessionId );
                                        n += gameSessionId.size();
                                    }
                                }

                                // string stream
                                //ostringstream s;
                                char sqlString[ 255 ];
                                // Update the entry's status field
                                //s << "UPDATE " << m_hmqTableName << " SET status='pending' WHERE id='" << rowId << "'";
                                sprintf( sqlString, "UPDATE %s SET status='pending' WHERE id='%d'", m_hmqTableName.c_str(), rowId );
                                //m_sql = s.str();

                                //cout << "update SQL: " << m_sql << endl;
                                int r = m_db.execDML( sqlString );// m_sql.c_str() );
                                //cout << "Updating result: " << r << endl;

                                // Perform the get request using the message information
                                m_core->mf_httpGetRequest( apiPath, coreCB, clientCB, postdata, contentType, rowId );
                                requestsMade++;
                            }
                            else {
                                m_core->displayWarning( "DataSync::flushMsgQ()", "The API path specified was invalid. Removing the entry from the queue." );
                                removeFromMsgQ( rowId );
                            }
                        }
                        else {
                            cout << "cookie for device Id: " << deviceId << " is NULL" << endl;
                        }
                    }
                    else {
                        cout << "no entry from SESSION was found for: " << deviceId << "..." << endl;
                    }
                }
                else {
                    m_core->displayWarning( "DataSync::flushMsgQ()", "The deviceId was NULL for the entry. Removing the entry from the queue." );
                    removeFromMsgQ( rowId );
                }

                // If we've exceeded the max number of requests we can make per flush, exit
                // The next batch of events will be picked up during the next flush
                if( requestsMade >= m_core->config.eventsMaxSize ) {
                    cout << "Exceeded max number of requests we can make, exit." << endl;
                    break;
                }

                // Get the next row in MSG_QUEUE
                //cout << "--- get the next entry in MSG_QUEUE ---" << endl;
                msgQuery.nextRow();
            }
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::flushMsgQ()", e.errorMessage() );
            //cout << "Exception in flushMsgQ() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }

        // End display out
        //cout << "reached the end of MSG_QUEUE" << endl;
        //cout << "-----------------------------------\n\n\n" << endl;
        m_core->logMessage( "reached the end of MSG_QUEUE" );
        //displayTable( m_hmqTableName );
        //displayTable( m_sessionTableName );
    }


    //--------------------------------------
    //--------------------------------------
    //--------------------------------------
    /**
     * Function creates all tables used in the SDK.
     */
    void DataSync::createTables() {
        int r;

        try {
            // Create the CONFIG table
            if( !m_db.tableExists( m_configTableName.c_str() ) ) {
                cout << endl << "Creating " << m_configTableName << " table" << endl;
                
                m_sql = "create table " + m_configTableName + " (version char(256));";

                cout << "SQL: " << m_sql << endl;
                string t2 = m_sql;
                r = m_db.execDML( t2.c_str() );
                
                cout << "Creating table:" << r << endl;

                // Insert the SDK version
                m_sql = "INSERT INTO " + m_configTableName + " VALUES ('" + SDK_VERSION + "');";
                cout << "insert version SQL: " << m_sql << endl;
                int nRows = m_db.execDML( m_sql.c_str() );
                cout << nRows << " rows inserted" << endl;

                cout << "------------------------------------" << endl;
            }

            // Create the MSG_QUEUE table
            if( !m_db.tableExists( m_hmqTableName.c_str() ) ) {
                cout << endl << "Creating " << m_hmqTableName << " table" << endl;
                
                m_sql = "create table " + m_hmqTableName + " ("
                "id integer primary key autoincrement, "
                "deviceId char(256), "
                "path char(256), "
                "coreCB char(256), "
                "clientCB char(256), "
                "postdata text, "
                "contentType char(256), "
                "status char(256) "
                ");";
                
                cout << "SQL: " << m_sql << endl;
                string t1 = m_sql;
                r = m_db.execDML( t1.c_str() );
                cout << "Created table:" << r << endl;
                cout << "------------------------------------" << endl;

                // Initialize the table size to 0
                m_messageTableSize = 0;
            }
            else {
                // Set the message table size
                m_sql = "select * from " + m_hmqTableName;
                CppSQLite3Table t = m_db.getTable( m_sql.c_str() );
                m_messageTableSize = t.numRows();

            }
            
            // Create the SESSION table
            if( !m_db.tableExists( m_sessionTableName.c_str() ) ) {
                cout << endl << "Creating " << m_sessionTableName << " table" << endl;
                
                m_sql = "create table " + m_sessionTableName + " ("
                "cookie char(256), "
                "deviceId char(256), "
                "gameSessionId char(256), "
                "gameSessionEventOrder integer, "
                "totalTimePlayed real "
                ");";

                cout << "SQL: " << m_sql << endl;
                string t2 = m_sql;
                r = m_db.execDML( t2.c_str() );
                
                cout << "Creating table:" << r << endl;
                cout << "------------------------------------" << endl;
            }

            // Display all tables
            displayTable( m_configTableName );
            displayTable( m_hmqTableName );
            displayTable( m_sessionTableName );
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::createTables()", e.errorMessage() );
            //cout << "Exception in createTables() " << e.errorMessage() << " (" << e.errorCode() << ") " << CppSQLite3Exception::errorCodeAsString( e.errorCode() ) << endl;
        }
    }

    /**
     * Function drops all existing tables in the database.
     */
    void DataSync::dropTables() {
        int r;
        
        try {
            // Drop the CONFIG table
            if( m_db.tableExists( m_configTableName.c_str() ) ) {
                cout << endl << "Dropping " << m_configTableName << " table" << endl;
                
                m_sql = "drop table " + m_configTableName + ";";
                
                cout << "SQL: " << m_sql << endl;
                string t1 = m_sql;
                r = m_db.execDML( t1.c_str() );
                cout << "Dropped table:" << r << endl;
                cout << "------------------------------------" << endl;
            }
            
            // Drop the MSG_QUEUE table
            if( m_db.tableExists( m_hmqTableName.c_str() ) ) {
                cout << endl << "Dropping " << m_hmqTableName << " table" << endl;
                
                m_sql = "drop table " + m_hmqTableName + ";";
                
                cout << "SQL: " << m_sql << endl;
                string t1 = m_sql;
                r = m_db.execDML( t1.c_str() );
                cout << "Dropped table:" << r << endl;
                cout << "------------------------------------" << endl;
            }
            
            // Drop the SESSION table
            if( m_db.tableExists( m_sessionTableName.c_str() ) ) {
                cout << endl << "Dropping " << m_sessionTableName << " table" << endl;
                
                m_sql = "drop table " + m_sessionTableName + ";";
                cout << "SQL: " << m_sql << endl;
                string t2 = m_sql;
                r = m_db.execDML( t2.c_str() );
                
                cout << "Dropped table: " << r << endl;
                cout << "------------------------------------" << endl;
            }
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::dropTables()", e.errorMessage() );
            //cout << "Exception in dropTables() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * Function will perform migration for all tables, calling the migrateTable( table ) function.
     */
    void DataSync::migrateTables() {
        int r;
        
        try {
            // Perform migration for the CONFIG table
            string config_schema = "create table " + m_configTableName + "_backup ("
                "version char(256) "
                ");";
            migrateTable( m_configTableName, config_schema );

            // Perform migration for the MSG_QUEUE table
            string message_schema = "create table " + m_hmqTableName + "_backup ("
                "id integer primary key autoincrement, "
                "deviceId char(256), "
                "path char(256), "
                "coreCB char(256), "
                "clientCB char(256), "
                "postdata text, "
                "contentType char(256), "
                "status char(256) "
                ");";
            migrateTable( m_hmqTableName, message_schema );

            // Perform migration for the SESSION table
            string session_schema = "create table " + m_sessionTableName + "_backup ("
                "cookie char(256), "
                "deviceId char(256), "
                "gameSessionId char(256), "
                "gameSessionEventOrder integer, "
                "totalTimePlayed real "
                ");";
            migrateTable( m_sessionTableName, session_schema );

            // Display all tables
            displayTable( m_configTableName );
            displayTable( m_hmqTableName );
            displayTable( m_sessionTableName );
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::migrateTables()", e.errorMessage() );
            //cout << "Exception in migrateTables() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * Function will handle migrating the data from an existing table into a new one sharing
     * the same name. This is to acount for potential changes in schema, including column add
     * and removal. The data in the previous schema will be preserved.
     * 
     * Migration accounting for column operations can be handled via these operations:
     * - CREATE TABLE current (a int, b int, c int);
     * - CREATE TABLE backup (a int, c int, d int);
     * - INSERT INTO backup SELECT a,c,0 FROM current;
     * - DROP TABLE current;
     * - ALTER TABLE backup RENAME TO current;
     */
    void DataSync::migrateTable( string table, string newSchema ) {
        int r;
        
        try {
            // Migrate the contents of the parameter table if it exists
            if( m_db.tableExists( table.c_str() ) ) {
                cout << endl << "Migrating " << table << " table" << endl;

                // Create the backup table with the desired schema
                m_sql = newSchema;
                // Execute.
                cout << "SQL: " << m_sql << endl;
                string t2 = m_sql;
                r = m_db.execDML( t2.c_str() );
                printf( "result: %i\n", r );


                // Get the schema for both the backup and current tables
                m_sql = "select * from " + table + "_backup;";
                CppSQLite3Query backup_q = m_db.execQuery( m_sql.c_str() );
                m_sql = "select * from " + table + ";";
                CppSQLite3Query current_q = m_db.execQuery( m_sql.c_str() );

                // Now we need to construct the insert string to migrate data from current to backup
                string insertString = "";
                int numBackupFields = backup_q.numFields();
                for( int b = 0; b < numBackupFields; b++ ) {
                    bool matchFound = false;

                    // We need to check this backup table field for existence in the current table
                    for( int c = 0; c < current_q.numFields(); c++ ) {
                        // If we have a match, append the value to the insert string
                        //printf( "comparing %s with %s\n", backup_q.fieldName( b ), current_q.fieldName( c ) );
                        if( strcmp( backup_q.fieldName( b ), current_q.fieldName( c ) ) == 0 ) {
                            //printf( "found!\n" );
                            insertString += backup_q.fieldName( b );
                            matchFound = true;
                            break;
                        }
                    }

                    // If there was no match found, set the default value for that data type
                    if( !matchFound ) {
                        insertString += "NULL";
                    }

                    // Append a comma if we haven't yet reached the end of backup fields
                    if( b + 1 < numBackupFields ) {
                        insertString += ",";
                    }
                }

                // Finalize the two select statements
                backup_q.finalize();
                current_q.finalize();


                // Insert shared values the from current into the backup
                m_sql = "insert into " + table + "_backup "
                    "select " + insertString + " from " + table + ";";
                // Execute.
                cout << "SQL: " << m_sql << endl;
                t2 = m_sql;
                r = m_db.execDML( t2.c_str() );
                printf( "result: %i\n", r );

                // Drop the current table
                m_sql = "drop table " + table + ";";
                // Execute.
                cout << "SQL: " << m_sql << endl;
                t2 = m_sql;
                r = m_db.execDML( t2.c_str() );
                printf( "result: %i\n", r );

                // Alter the backup table to rename it as current
                m_sql = "alter table " + table + "_backup "
                    "rename to " + table + ";";
                // Execute.
                cout << "SQL: " << m_sql << endl;
                t2 = m_sql;
                r = m_db.execDML( t2.c_str() );
                printf( "result: %i\n", r );

                // Print final results
                cout << "Migration results:" << r << endl;
                cout << "------------------------------------" << endl;
            }
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::migrateTable()", e.errorMessage() );
            //cout << "Exception in migrateTable() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }
    }

    /**
     * Functions displays the contents of a given table.
     */
    void DataSync::displayTable( string table ) {
        /*try {
            // display out
            cout << "------------------------------------" << endl;
            cout << "all rows in " << table << endl;
            int fld;
            
            m_sql = "select * from " + table + ";";
            cout << "SQL: " << m_sql << endl;
            CppSQLite3Query q = m_db.execQuery( m_sql.c_str() );
            
            for( fld = 0; fld < q.numFields(); fld++ )
            {
                cout << q.fieldName( fld ) << "(" << q.fieldDataType( fld ) << ")|";
            }
            cout << endl;
            
            while( !q.eof() )
            {
                for( int i = 0; i < q.numFields(); i++ ) {
                    cout << q.fieldValue( i ) << " | ";
                }
                cout << "END" << endl;
                q.nextRow();
            }
            q.finalize();
            cout << "------------------------------------" << endl;
        }
        catch( CppSQLite3Exception e ) {
            m_core->displayError( "DataSync::displayTable()", e.errorMessage() );
            //cout << "Exception in displayTable() " << e.errorMessage() << " (" << e.errorCode() << ")" << endl;
        }*/
    }
    
}; // end nsGlasslabSDK