GlassLab Flash SDK
===================

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
===========

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
======================

To begin, you can establish a connection with a GlassLab server by calling the connect
function in glsdk_core.


API subclass
============

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
==========

A sample API is provided in the examples folder.

To use this sample, focus the canvas and use the following keys:
- start a ession with S
- end the ession with E
- send telemetry with T

Success and failure from the server is determined by order of calls received.
Keep the following in mind:
- You cannot send telemetry if no session is active. Call start session first.
- You cannot close a session that doesn't exist. Call start session first.


Telemetry Format and Examples
=============================

Adding custom telemetry to the server message queue is fairly straightforward and allows for
some flexibility. Telemetry events adhere to a specific data schema that the SDK will construct
automatically. When creating a new telemetry event to be sent to the system, the user specifies
the name of the event and as many custom parameters as necessary. Telemetry events can be as 
simple as triggers, containing no custom paramters:
 - "Player_jump" : {}
Or they can be more descriptive and reusable:
 - "Player_take_damage" : { amount : "10" }

The SDK functions required to write telemetry events are as follows:
 - addTelemEventValue_string( key, value )
 - addTelemEventValue_int( key, value )
 - addTelemEventValue_uint( key, value )
 - addTelemEventValue_number( key, value )
 - saveTelemEvent( eventName )

The "addTelemEventValue_[type]" functions allow for custom parameters to be sent with each
telemetry event and are therefore not required. In the above example, we created a parameter
keyed as "amount" with the value "10". It is important to note that the telemetry parameters
must be added before a telemetry event is saved. These parameters are simply stored locally
until "saveTelemEvent( eventName )" is called, at which point they are appended to the event
named "eventName" and then reset.

The code below demonstrates how we can write the aforementioned telemetry examples:

```
// Send the "Player_take_damage" event with amount parameter
SDK.addTelemEventValue_int( "amount", 10 );
SDK.saveTelemEvent( "Player_take_damage" );

// Send the "Player_jump" event
SDK.saveTelemEvent( "Player_jump" );
```

Note that the parameter "amount" with value "10" will not be sent along with the "Player_jump"
event because it was flushed after the "Player_take_damage" event was saved.

A few more examples:

```
// The player selected the "Read More" Icon in the game
SDK.saveTelemEvent( "action_Read_More" );

// The player explains reasoning using the wheel interface
// Her reasoning was considered correct
SDK.addTelemEventValue_int( "correct", 1 );
SDK.saveTelemEvent( "RWheel" );
```