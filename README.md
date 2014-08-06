# GlassLab SDK

In order for games and other applications to connect to the GlassLab Games Services (GLGS) platform, the GlassLab SDK is required. The SDK allows applications to establish a connection to our servers and create game sessions for data capture. We've provided a library with a plethora of functions available for communicating with our servers. The operations the SDK allows include user authentication, course management, session management, and telemetry and achievement tracking. It is not required to utilize all of these functions to experience the core of GLGS; the emphasis is on telemetry and data collection, which is made to be as simple as possible.

For information on integration and general usage, please see below on supported platforms and platform-specific implementations.

### Supported Platforms:

We currently support the following platforms with the GlassLab SDK:
- Flash (ActionScript 3.0)
- iOS (C++)
- OSX (C++)

In addition to the general documentation provided in this page, you can find more detailed technical documentation for each of our supported platforms. In these sections, we'll cover the tech stack the platform-specific SDK was built upon, integration and utilization steps, client-server communication, telemetry format and expectations, and some samples to help you get started.
- [Technical documentation for Flash SDK](https://github.com/GlasslabGames/GlassLabSDK/tree/master/FlashSDK/ "Technical documentation for Flash SDK")
- [Technical documentation for iOS/OSX SDK](https://github.com/GlasslabGames/GlassLabSDK/tree/master/OSX-iOS/ "Technical documentation for iOS/OSX SDK")

### Client-Server Communication Process:

The diagram below provides a high level into how requests are communicated between the game client and the server:

![Alt text](https://github.com/GlasslabGames/GlassLabSDK/tree/master/docs/Client_Server_Communication_With_SDK.png)

All requests the client makes are put into a queue maintained by the SDK. Examples of such requests include:
- startSession()
- sendTelemEvent()
- endSession()

These are the three basic functions necessary for the core experience of GLGS. It is the game client's responsibility to make these requests at the appropriate times and it is the SDK's responsibility to relay these messages to the server and communicate the responses back to the game client. Any request being made by the game client is inserted into the DISPATCH queue. We control flushing from this queue with three parameters:
- Time interval
- Minimum request count
- Maximum request count

We will flush the dispatch queue on two occasions, 1) a certain amount of time elapses and there is a target minimum number of requests queued up, or 2) we've reached a maximum number of requests the queue can store. We use these three parameters to control the server load.

Once we've met the criteria for dispatch, these requests are made to the server. The server will always respond, with either success or failure, and return a message back to the SDK to be stored in the RESPONSE queue. It is the game client's responsibility (but not requirement) to read from the response queue and perform any desired actions.