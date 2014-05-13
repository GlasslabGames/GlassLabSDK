/*

==========================
=== GlassLab Flash SDK ===
==========================

This Flash-compatible GlassLab SDK allows games and other applications to connect
to the GlassLab Games Services platform. The primary purpose of integrating this
library into your project is to track game sessions and store telemetry for those
sessions.

This package includes the GlassLabSDK.swc library file, the source code, and some
examples on how to use it.

Supported runtimes:
- Flash Player 10+

Libraries used:
- as3corelib (This is used for FP10 JSON compatibility. Should FP11+ be detected,
native JSON functionality will be used instead for a performance boost. Note that
only a small subset of this library is used: serialization.)


 Integration
=============

There are two ways you can integrate the SDK into your project: linking the .swc or
using the source code directly.

1) GlassLabSDK.swc

The .swc library contains all source files required to use the SDK. To use this,
add the GlassLabSDK.swc to your library paths within the .fla properties. To use the
SDK classes, be sure to include the following import statement:
- import GlassLabSDK.*

2) GlassLab SDK src

The source files are also available to be included in the project. Simply drop the
GlassLabSDK folder in an appropriate folder and include the following import statement
in the file you wish to reference it from:
- import GlassLabSDK.*


 Establish a connection
========================

To begin, you can establish a connection with a GlassLab server by calling the connect
function in glsdk_core.


 API subclass
==============

It is recommended to create an API subclass that inherits from glsdk_core.as in order
to make calls to the SDK and receive response information from the server.

Recommended functions to utilize:
- startSession
- endSession
- saveTelemEvent
- popMessageQueue

When popMessageQueue is called the glsdk_core base will return the first received response
message from the server with a message type and associated JSON data. A list of possible
messages can be found in glsdk_cosnt.as.


 Sample API
============

A sample API is provided in the examples folder.

To use this sample, focus the canvas and use the following keys:
- start a ession with S
- end the ession with E
- send telemetry with T

Success and failure from the server is determined by order of calls received.
Keep the following in mind:
- You cannot send telemetry if no session is active. Call start session first.
- You cannot close a session that doesn't exist. Call start session first.

*/