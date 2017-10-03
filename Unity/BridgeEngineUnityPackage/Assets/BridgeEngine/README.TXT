Bridge Engine for Unity

This SDK provides iOS developers with the easiest way to add 6DOF tracking to their Unity projects.
Please visit https://bridge.occipital.com for more information about the Bridge headset and the latest version of this SDK.

GETTING STARTED
===============

There are three examples in the BridgeEngine/Example/Scenes:
VR Example.unity - Demonstrates full VR immersion with a Collision Avoidance shader
MR Example.unity - Demonstrates Mixed Reality with live color pass through and Collision Avoidance
Mono Example.unity - Demonstrates stand-alone Bridge Engine mono rendering without GoogleVR.

• Build your iOS Project
• Connect the Structure Sensor
• Connect a Bridge Controller
• Scan a scene for tracking on
• Enjoy!

How to use in your own GoogleVR projects:
• Add to your scene:
  BridgeEngine/BridgeEngineMain.prefab

Bridge Engine for Unity builds on top of the GoogleVR pointing and event system
• To add Bridge Controller support, add to your scene:
  BridgeEngine/Prefab/BridgeController.prefab
