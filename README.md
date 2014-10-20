# GlassLab SDK

[Visit the **Javascript Alpha SDK** for **Web** developers!](https://github.com/GlasslabGames/GlassLabSDK-js/ "Visit the **Javascript Alpha SDK** for **Web** developers!")

[Visit the **C++ SDK** for **iOS / OSX / Windows** developers!](https://github.com/GlasslabGames/GlassLabSDK-cpp/ "Visit the **C++ SDK** for **iOS / OSX / Windows** developers!")

[Visit the **AS3 SDK** page for **Flash / Flex** developers!](https://github.com/GlasslabGames/GlassLabSDK-as3/ "Visit the **AS3 SDK** page for **Flash / Flex** developers!")

In order for games and other applications to connect to the GlassLab Game Services (GLGS) platform, the GlassLab SDK is required. The SDK allows applications to establish a connection to our servers and create game sessions for data capture. We've provided a library with a plethora of functions available for communicating with our servers. The operations the SDK allows include user authentication, course management, session management, telemetry tracking, and reporting. It is not required to utilize all of these functions to experience the core of GLGS; the emphasis is on telemetry and data collection, which is made to be as simple as possible.

For information on integration and general usage, please see below on supported platforms and platform-specific implementations.

### Supported Platforms:

We currently support the following platforms with the GlassLab SDK:
- Web (Javascript Alpha)
- Flash/Flex (ActionScript 3.0)
- iOS (C++)
- OSX (C++)
- Windows (C++)

In addition to the general documentation provided in this page, you can find more detailed technical documentation for each of our supported platforms. In these sections, we'll cover the tech stack each of the platform-specific SDKs were built upon, integration and utilization steps, client-server communication, telemetry format and expectations, and some samples to help you get started.

### Implementation Process

In order to accelerate development, we suggest a four-step implementation process of the SDK. Each step of this process allows the developer to verify the core features of the SDK, starting with an immediate and basic integration, following with telemetry verification, and ending with a link on Playfully.org.

1) SDK Integration

Integrating the SDK for the desired platform is very simple and requires only the library, located in the "lib" directory, and associated header files (if you're using the C++ SDK). Each SDK repository has integration steps specific to the target platform included. There are also example projects that show how the library integration works, in addition to demonstrating the core features.

Once the integration is successful, the first API call to make is connect(). This is an on-demand HTTP request that will fire immediately and you can listen for the results in the message stack (described in the next section). If the result of the connect() function is success then you are free to communicate with the Playfully.org server; if the result is a failure the response will indicate how to best proceed.

2) Sessions and Telemetry

The core feature of the SDK is telemetry. In order to send telemetry, a game session must be active. Once a game session is active, you can send any amount of telmemetry, with any amount of data, and then close the game session. All of this can be accomplished with the following SDK calls:
- startSession()
- sendTelemEvent()
- endSession()

These three functions are described further in the section below.

3) Authentication

Before the game can be released, Playfully.org authentication must be integrated. Authentication can be handled manually, using SDK calls, or with the Playfully.org webviews. If you desire to handle authentication manually, you can take advantage of the following SDK functions:
- register()
- login()
- enroll()
- unenroll()

Authenticating a user occurs with register() and login(), but users can also handle class management with enroll() and unenroll(). Note that by using these SDK functions manually, you will have to build the UI as well.

You can also choose to integrate the Playfully.org webviews, which handle the authentication and class management automatically. The webviews are designed to handle all inputs, outputs, transitions, and errors so that the developers needs only open them and respond to the results. The URL of the webview will have search parameters appended when operations are either successful or unsuccessful, allowing the developer to react accordingly. The main webview to integrate into your project can be found at this URL: http://developer.playfully.org/sdk/login

Finally, if you are building a Playfully-embedded application, using either the Flash SDK or the Javascript SDK, the authentication step will not be necessary because it is handled automatically before users can access the game page.

4) Reporting

The last implementation step allows the developer to surface the raw data collected as human-readable, actionable data on the Playfully.org dashboards. Currently, there are three types of reporting:
- Learning progress
- Shout Out, Watch Out, What's Next (SOWOWN)
- Competency

Learning progress reporting includes achievements and total time played. While total time played is handled automatically when the game timer starts, achievements must be called from the game code. All achievements adhere to the same format and require three fields: item, group, and subGroup. The keys associated with these fields reside on the Playfully.org servers and therefore the developer must work with the GlassLab team to complete the integration.

The other two parts of reporting, SOWOWN and competency, both rely on telemetry sent from the client to be calculated and are handled entirely server-side. The developer will need to collaborate with the GlassLab team for the implementation of the logic that governs these reporting features.

### Client-Server Communication Process:

The diagram below provides a high level overview of how requests are communicated between the game client and the server:

![Alt text](https://github.com/GlasslabGames/GlassLabSDK/blob/master/docs/Client_Server_Communication_With_SDK.png)

All requests made by the client are put into a queue maintained by the SDK. Examples of such requests include:
- startSession()
- sendTelemEvent()
- endSession()

These are the three basic functions necessary for the core experience of GLGS. It is the game client's responsibility to make these requests at the appropriate times and it is the SDK's responsibility to relay these messages to the server and communicate the responses back to the game client. Any request being made by the game client is inserted into the DISPATCH queue. We control flushing from this queue with three parameters:
- Time interval
- Minimum request count
- Maximum request count

We will flush the dispatch queue based on two protocols, 1) a certain amount of time elapses and there is a target minimum number of requests queued up, or 2) we've reached a maximum number of requests the queue can store. We use three parameters to control the server load.

Once we've met the criteria for dispatch, these requests are made to the server. The server will always respond, with either success or failure, and return a message back to the SDK to be stored in the RESPONSE queue. It is the game client's responsibility (but not requirement) to read from the response queue and react accordingly.

### License

The GlassLab SDK is under the BSD license: [SDK license](https://github.com/GlasslabGames/GlassLabSDK/blob/master/LICENSE "SDK license")

[Visit the **C++ SDK** for **iOS / OSX / Windows** developers!](https://github.com/GlasslabGames/GlassLabSDK-cpp/ "Visit the **C++ SDK** for **iOS / OSX / Windows** developers!")

[Visit the **AS3 SDK** page for **Flash / Flex** developers!](https://github.com/GlasslabGames/GlassLabSDK-as3/ "Visit the **AS3 SDK** page for **Flash / Flex** developers!")