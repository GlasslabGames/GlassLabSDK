#!/bin/bash

UNITY_DIR="../../../Hiro/uHiro/Assets/Plugins/iOS"
EXPORT_UNITY_DIR="../../../Hiro/uHiro/export/Libraries"

cp ../lib/ios/libGlasslabSDK.a $UNITY_DIR
cp ../platforms/unity/GlasslabSDK.cs $UNITY_DIR

cp ../lib/ios/libGlasslabSDK.a $EXPORT_UNITY_DIR
cp ../platforms/unity/GlasslabSDK.cs $EXPORT_UNITY_DIR

