# Welcome to the Bridge Engine Beta 6!

We're glad to have you onboard. We're committed to enhancing Bridge Engine, so we take all of your feedback and support very earnestly.

Check out the <a href="https://www.youtube.com/watch?v=qbkwew3bfWU&list=PLxCu2yuPufWPjCthmZYOOJG9ieRnGAL79" target="_blank">Occipital Youtube Playlist for recent videos on Bridge Engine</a>.  

#### KNOWN ISSUES
- In some cases, doing scanning and using the mono rendering mode will lead to rendering SceneKit elements with incorrect occlusion with the real world.
- iOS 11 support is still underway. On iOS 11, you will experience thread sanitizer warnings when you run Bridge Engine. Additionally, running with mono rendering will render a black screen instead of the camera view, and object selection in mono is temperamental. This will be addressed in a future update, but for now you can still prepare for iOS 11 by running Bridge Engine in debug mode.
- Unity 5.6 requires a newer version of GoogleVR which we don't support at this time. Please develop on <a href="https://unity3d.com/get-unity/download/archive" target="_blank">Unity 5.5.3f1</a> when using Bridge Engine for Unity package.
- Unity plugin Mixed Reality limitations: 1) Currently, rendering is stereo (in-headset) only, and 2) Casting shadows onto the real world is not yet supported. These are temporary limitations and will be addressed later.

### New in Beta 6: Mixed Reality in Unity & Major UI/UX Updates
We have two major things happening in this release.

First, and most significant to many developers: **The Bridge Engine Unity Plugin now supports Mixed Reality** (with camera passthrough and real world occlusion)! Now you can scan your surroundings and create full Mixed Reality scenes with projects build from Unity! This plugin is still in beta, so please report any issues you find.

The second thing is a series of general UX improvements across the board:

- Stereo Scanning UX is improved: Now, the selection menu will always remain upright.
- Markup is improved, it now projects where an object will be placed and has an updated UI.  Use a custom markup object by implementing the `- (BOOL) mixedRealityBridgeShouldProjectMarkupNode:(NSString *)markupName position:(SCNVector3)position eulerAngles:(SCNVector3)eulerAngles` delegate method.
- Debug Settings have been redesigned.
- Performance has been improved: You may notice a significant in-experience FPS increase.
- New sample! The Laser Manipulator, which demonstrates use of Bridge Controller's touchpad and 3-DoF tracking.

#### Beta 5.2: Maintenance Release
We're cleaning up a few odds and ends. Keep up the great feedback!

The biggest issue we cleared up was an unusual case of iOS 10's whole audio system stopping from playing any audio when OpenBE's `AudioEngine` attempted to play an audio clip. Get this update to clear it up. No code changes required.

There is a new Bridge Engine option `kBEAutoExposeWhileRelocalizing` that you can try out. This will enable the color camera to auto expose while relocalizing, which can re-establish a lock in changing light conditions. Let us know what you think.

Other odds and ends:

- Improved pathfinding performance, both speed and quality.  Please let us know if Bridget gets stuck anywhere!
- Baked in some lighting onto the Bridge Controller model, so you can see it in all light conditions.
- Improved the in-headset scanning UI; you can tap through with no controller needed, and improved the in-headset hud instructions.

#### Beta 5.1: Stereo Scanning
Keep your iPhone in the Bridge Headset and scan your world by looking around!  In-headset scanning is re-enabled however the feature is still in beta, please give us your feedback.

Also featured in this release:

- Unity 5.5 and GoogleVR 1.4 fixes, picks up the correct GoogleVR release when downloading
- BE For Unity - tracking of reticle works even if no raycasts hit a collider
- Brand new Bridge Controller model, you'll see it in Bridget Sample when one is connected and you look down
- Corrected Bridge controller rotation, works better in all orientations
- Corrected Bridge controller touchpad tracking and state updates, touch.y is +1 for front tip of controller
- Debug setting UI at start of samples, makes for easier record and playback development workflow
- Debug option for manual Bridge controller selection, for crowded environments like hackathons
- Improved pathfinding, respects surfaces above Bridget and what is scanned floor
- Audio Engine init thread safety checks, so iOS 10 audio doesn't stop working

### New in Beta 5: Bridge Controller
Bridge Engine now supports the official controller with 3-DoF rotational tracking, a capacitive touchpad, a trigger & multiple buttons. Additionally, we've loaded the beta with lots of small updates! The BRIDGET sample has improvements to the portal and scan effect; The Unity plugin has matured with a simplified Unity package; We added realistic 3D positional audio support; and you can now record your screen directly from the app using ReplayKit. Note: *Stereo scanning has been temporarly disabled while we address a known issue, but it will be back in the next release.*


### New in Beta 4: Stereo Scanning

We have two really exciting updates in Beta 4. The first is stereo scanning, now you can put your Bridge on and build a map directly! Bridget’s also getting an upgrade! Bridge Engine Beta 4 adds an experimental feature that you may have seen in our videos - a portal into virtual reality. You can can access this new feature immediately to integrate into you own apps for Bridge. Additionally there are a handful of smaller features and updates.

#### Beta 3 Update 1: Bridget sample

We've just released the source of the Bridget sample, based on `OpenBE`, a Bridge Engine open source library containing Bridget's core functions like path planning, animation and scripting, as well as additional UI components, audio, and general mixed reality tools to help you develop with Bridge Engine.

### New in Beta 3: Bridge Headset Support & Rendering Overhaul
- It turns out we were working on a whole headset to go along with Bridge Engine! Learn more at the [Bridge website](https://bridge.occipital.com)
- Full-resolution rendering - critical for VR
- Forward rendering pipeline. This means compositing onto a global depth buffer with the room geometry, with all SceneKit material controls available like depth testing, rendering order and blending modes.

#### Get Involved
Want to help us expand the capabilities of Bridge Engine? We'd love contributions in the form of pull requests. Soon, we will formalize how to best contribute to Bridge Engine, but feel free to contact us and get involved here on Github.

### Please Use the Following Documentation & Resources to Get Up and Running
- Open `Reference/html/index.html` in your browser to view documentation
- [Documentation: Table of Contents and Calibrator App](https://github.com/OccipitalOpenSource/bridge-engine-beta/wiki)
- Note that Bridge Engine is not compatible with the iOS simulator.

### Changelog

##### Beta 6 changes

- Unity plugin: Now supports Mixed Reality
- New sample! The Laser Manipulator
- Stereo Scanning UX updates
- Markup redesign
- Debug settings simplified 
- Performance: Significant FPS improvements

##### Beta 5 changes

- Bridge controller support
- Quicker robot scan-beam and portal improvements
- Unity improvements
- Added Spatial Audio support
- Added "ReplayKit" Screen Recording
- Exports texture OBJ of scanned world into the BridgeEngineScene folder

##### Beta 4 changes
- OpenBE: portal rendering code
- Supports in-headset scanning
- Exposes additional rendering information like system rendering order and shadow controls

##### Beta 3 Update 1 changes
- Added the Bridget sample
- Fixed OCC recording
- Fixed the layout and size of UI elements

##### Beta 3 changes
- Complete rendering overhaul
- Unity Package supporting inside-out tracking on iOS
- Bluetooth Controller integration
- Improved tracking and relocalization

##### Beta 2 changes
- In-app scanning: Scans can be performed from within the Bridge Engine.

##### Beta 1 changes
- Added new Rendering Sample (Updated sample names, and provisioning profiles). See [Rendering Documentation](https://github.com/OccipitalOpenSource/bridge-engine-beta/wiki/Documentation:-Advanced-Rendering-with-the-Bridge-Engine))
- Color-only tracking support - Scan the room with the Structure Sensor, but track in AR with only the the iOS camera!
