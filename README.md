# Welcome to the Bridge Engine Beta 5!

We're glad to have you onboard. We're committed to enhancing Bridge Engine, so we take all of your feedback and support very earnestly.

Check out the <a href="https://www.youtube.com/watch?v=qbkwew3bfWU&list=PLxCu2yuPufWPjCthmZYOOJG9ieRnGAL79" target="_blank">Occipital Youtube Playlist for recent videos on Bridge Engine</a>.  

#### 

#### Beta 5: Bridge Controller 
Bridge Engine now supports the official controller with 3DOF rotational tracking, a capacitive touchpad plus buttons a trigger. Additionally, we've loaded the Beta with lots of small updates! The BRIDGET sample has improvements to the portal and scan effect; The Unity plugin has matured with a simplified Unity package; We added Realistic 3D positional audio support; and you can now record your screen directly from the app using ReplayKit. Stereo scanning has been temporarly disabled while we address a known issue, but it will be back in the next release.'' 


#### New in Beta 4: Stereo Scanning 

We have two really exciting updates in Beta 4. The first is stereo scanning, now you can put your Bridge on and build a map directly! Bridget’s also getting an upgrade! Bridge Engine Beta 4 adds an experimental feature that you may have seen in our videos - a portal into virtual reality. You can can access this new feature immediately to integrate into you own apps for Bridge. Additionally there are a handful of smaller features and updates.

#### Beta 3 Update 1: Bridget sample

We've just released the source of the Bridget sample, based on `OpenBE`, a Bridge Engine open source library containing Bridget's core functions like path planning, animation and scripting, as well as additional UI components, audio, and general mixed reality tools to help you develop with Bridge Engine.

#### New in Beta 3: Bridge Headset Support & Rendering Overhaul
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

### Beta 5 changes

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
