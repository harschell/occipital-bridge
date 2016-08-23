# Welcome to the Bridge Engine Beta 2!

We're glad to have you onboard. We're committed to developing the Bridge Engine, so we take all of your feedback and support very earnestly.

Check out our <a href="https://www.youtube.com/embed/nXB_0DGbamU" target="_blank">Bridge Engine Beta Video Posted to Slack</a>. It's a great example of the robust RGB(D) tracking and fast relocalization available through the engine.   
#### New in version 2: In-app scanning
The Bridge Capture Tool is no longer needed -- scans can be performed from within the Bridge Engine. This means you don't have to set up Provisioning Profiles and Certs to be in the App Group, you can simply sign your apps yourself.

The old `[BEMixedRealityMode start]` will now take you to a scanning menu. There is a new method `[BEMixedRealityMode startWithSavedScene]` that will load the scene from the app Documents folder **Bridge Engine Scene** without asking to scan, as before.


### Please Use the Following Documentation & Resources to Get Up and Running
- [Documentation: Table of Contents, Calibrator, and Bridge Capture Tool Applications](https://github.com/OccipitalOpenSource/bridge-engine-beta/wiki)
- (Deprecated) ~~Instructions on Importing Developer Keys, Certs, and Provisioning Profile~~

### Changelog

##### Version 0.2 changes
 - Added new Rendering Sample (Updated sample names, and provisioning profiles). See [Rendering Documentation](https://github.com/OccipitalOpenSource/bridge-engine-beta/wiki/Documentation:-Advanced-Rendering-with-the-Bridge-Engine))
 - Color-only tracking support - Scan the room with the Structure Sensor, but track in AR with only the the iOS camera!

##### Version 2.0 changes
 - In-app scanning: The Bridge Capture Tool is no longer needed -- scans can be performed from within the Bridge Engine. 


 ### Known Issues
  - **IN-APP SCANNING (v2.0) MAY PERFORM SLOWER THAN EXPECTED. After researching the issue we realized very odd behavior (potential CPU throttling) with iOS. This will be fixed in a future release.**
  - In v2.0, stereo has higher latency than is needed. We will improve latency in a future build. 
