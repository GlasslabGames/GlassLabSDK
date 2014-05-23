//
//  glasslab_sdk.cpp
//  GlasslabSDK
//
//  Authors:
//      Joseph Sutton
//      Ben Dapkiewicz
//
//  Copyright (c) 2014 Glasslab. All rights reserved.
//

#include "glasslab_sdk.h"


GlasslabSDK::GlasslabSDK( const char* dataPath, const char* clientId, const char* deviceId, const char* uri ) {
    m_core = new nsGlasslabSDK::Core( this, dataPath, clientId, deviceId, uri );
}


nsGlasslabSDK::Const::Status GlasslabSDK::getLastStatus() {
    if( m_core != NULL ) return m_core->getLastStatus();
    else return nsGlasslabSDK::Const::Status_Error;
}

nsGlasslabSDK::Const::Response* GlasslabSDK::popMessageStack() {
    if( m_core != NULL ) return m_core->popMessageStack();
    else {
        nsGlasslabSDK::Const::Response* response = new nsGlasslabSDK::Const::Response();
        response->m_message = nsGlasslabSDK::Const::Message_Error;
        response->m_data = "";
        return response;//nsGlasslabSDK::Const::Message_Error;
    }
}


void GlasslabSDK::deviceUpdate() {
    if( m_core != NULL ) m_core->deviceUpdate();
}

void GlasslabSDK::authStatus() {
    if( m_core != NULL ) m_core->authStatus();
}

void GlasslabSDK::registerStudent( const char* username, const char* password, const char* firstName, const char* lastInitial, string cb ) {
    if( m_core != NULL ) m_core->registerStudent( username, password, firstName, lastInitial, cb );
}

void GlasslabSDK::registerInstructor( const char* name, const char* email, const char* password, bool newsletter, string cb ) {
    if( m_core != NULL ) m_core->registerInstructor( name, email, password, newsletter, cb );
}

void GlasslabSDK::login( const char* username, const char* password, const char* type, string cb ) {
    if( m_core != NULL ) m_core->login( username, password, type, cb );
}

void GlasslabSDK::login( const char* username, const char* password, string cb ) {
    this->login( username, password, NULL, cb );
}

void GlasslabSDK::enroll( const char* courseCode, string cb ) {
    if( m_core != NULL ) m_core->enroll( courseCode, cb );
}

void GlasslabSDK::unenroll( const char* courseId, string cb ) {
    if( m_core != NULL ) m_core->unenroll( courseId, cb );
}

void GlasslabSDK::getCourses( string cb ) {
    if( m_core != NULL ) m_core->getCourses( cb );
}

void GlasslabSDK::logout( string cb ) {
    if( m_core != NULL ) m_core->logout( cb );
}

void GlasslabSDK::startSession( string cb ) {
    if( m_core != NULL ) m_core->startSession( cb );
}

void GlasslabSDK::endSession( string cb ) {
    if( m_core != NULL ) m_core->endSession( cb );
}

void GlasslabSDK::saveGame(const char* gameData, string cb) {
    if( m_core != NULL ) m_core->saveGame(gameData, cb);
}

void GlasslabSDK::sendTelemEvents() {
    if( m_core != NULL ) m_core->sendTelemEvents();
}

void GlasslabSDK::cancelRequest( const char* key ) {
    if( m_core != NULL ) m_core->cancelRequest( key );
}


void GlasslabSDK::addTelemEventValue( const char* key, const char* value ) { if( m_core != NULL ) m_core->addTelemEventValue( key, value ); }
void GlasslabSDK::addTelemEventValue( const char* key, int8_t value )      { if( m_core != NULL ) m_core->addTelemEventValue( key, value ); }
void GlasslabSDK::addTelemEventValue( const char* key, int16_t value )     { if( m_core != NULL ) m_core->addTelemEventValue( key, value ); }
void GlasslabSDK::addTelemEventValue( const char* key, int32_t value )     { if( m_core != NULL ) m_core->addTelemEventValue( key, value ); }
void GlasslabSDK::addTelemEventValue( const char* key, uint8_t value )     { if( m_core != NULL ) m_core->addTelemEventValue( key, value ); }
void GlasslabSDK::addTelemEventValue( const char* key, uint16_t value )    { if( m_core != NULL ) m_core->addTelemEventValue( key, value ); }
void GlasslabSDK::addTelemEventValue( const char* key, uint32_t value )    { if( m_core != NULL ) m_core->addTelemEventValue( key, value ); }
void GlasslabSDK::addTelemEventValue( const char* key, float value )       { if( m_core != NULL ) m_core->addTelemEventValue( key, value ); }
void GlasslabSDK::addTelemEventValue( const char* key, double value )      { if( m_core != NULL ) m_core->addTelemEventValue( key, value ); }

void GlasslabSDK::clearTelemEventValues() {
    if( m_core != NULL ) m_core->clearTelemEventValues();
}

void GlasslabSDK::saveTelemEvent( const char* name ) {
    if( m_core != NULL ) m_core->saveTelemEvent( name );
}

void GlasslabSDK::saveAchievementEvent( const char* item, const char* group, const char* subGroup ) {
    if( m_core != NULL ) m_core->saveAchievementEvent( item, group, subGroup );
}


void GlasslabSDK::updatePlayerInfoKey( const char* key, const char* value ) { if( m_core != NULL ) m_core->updatePlayerInfoKey( key, value ); }
void GlasslabSDK::updatePlayerInfoKey( const char* key, int8_t value )      { if( m_core != NULL ) m_core->updatePlayerInfoKey( key, value ); }
void GlasslabSDK::updatePlayerInfoKey( const char* key, int16_t value )     { if( m_core != NULL ) m_core->updatePlayerInfoKey( key, value ); }
void GlasslabSDK::updatePlayerInfoKey( const char* key, int32_t value )     { if( m_core != NULL ) m_core->updatePlayerInfoKey( key, value ); }
void GlasslabSDK::updatePlayerInfoKey( const char* key, uint8_t value )     { if( m_core != NULL ) m_core->updatePlayerInfoKey( key, value ); }
void GlasslabSDK::updatePlayerInfoKey( const char* key, uint16_t value )    { if( m_core != NULL ) m_core->updatePlayerInfoKey( key, value ); }
void GlasslabSDK::updatePlayerInfoKey( const char* key, uint32_t value )    { if( m_core != NULL ) m_core->updatePlayerInfoKey( key, value ); }
void GlasslabSDK::updatePlayerInfoKey( const char* key, float value )       { if( m_core != NULL ) m_core->updatePlayerInfoKey( key, value ); }
void GlasslabSDK::updatePlayerInfoKey( const char* key, double value )      { if( m_core != NULL ) m_core->updatePlayerInfoKey( key, value ); }
void GlasslabSDK::removePlayerInfoKey( const char* key )                    { if( m_core != NULL ) m_core->removePlayerInfoKey( key ); }


void GlasslabSDK::setName( const char* name ) {
    if( m_core != NULL ) m_core->setName( name );
}

void GlasslabSDK::setVersion( const char* version ) {
    if( m_core != NULL ) m_core->setVersion( version );
}

void GlasslabSDK::setGameLevel( const char* gameLevel ) {
    if( m_core != NULL ) m_core->setGameLevel( gameLevel );
}

void GlasslabSDK::setUserId( int userId ) {
    if( m_core != NULL ) m_core->setUserId( userId );
}

void GlasslabSDK::setPlayerHandle( const char* handle ) {
    if( m_core != NULL ) m_core->setPlayerHandle( handle );
}

void GlasslabSDK::removePlayerHandle( const char* handle ) {
    if( m_core != NULL ) m_core->removePlayerHandle( handle );
}


const char* GlasslabSDK::getCookie() {
    if( m_core != NULL ) {
        return m_core->getCookie();
    }
    else {
        return "";
    }
}