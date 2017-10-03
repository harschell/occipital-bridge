Bridge Engine for Unity Package
===============================

This folder contains the build components for assembling the full `BridgeEngine.unitypackage`

The Unity project `BridgeEngineUnityPackage` is the base for building `BridgeEngine.unitypackage`

Example scene can be found in "Assets/BridgeEngine/Example/Example.unity"

Most of the native interop code is contained in "Assets/BridgeEngine/Plugins".
The C# side of the interop code is contained in "Assets/BridgeEngine/Scripts".

If you're interested in starting a fresh Unity project from scratch, you can follow along
with `BridgeEngineUnity-Getting-Started.pdf`, and load the Models and Scripts from
`Assets/BridgeEngine/Example` folder.

Special note about GoogleVRDummy.cs
------------------------------------

* Please don't check-in the removal of GoogleVRDummy.cs *

When loading either Unity project the runtime scripts detect
and deletes GoogleVRDummy.cs here:

 ./BridgeEngineUnityPackage/Assets/BridgeEngine/Scripts/GoogleVRDummy.cs

This is a stub of GoogleVR, and is needed if GoogleVR is not present at install time of
the unitypackage. GoogleVR is detected and the script is deleted to clear up the warnings.
Because the BridgeEngine requires a namespace stub for the GoogleVR related components,
automatic removal is needed to make the installed GoogleVR work correctly.

A backup copy is stored in:

 ./CopyScriptsOnBuild/GoogleVRDummy.cs

Before packaging `BridgeEngine.unitypackage` make sure to copy back
or restore `GoogleVRDummy.cs`. If not then installation of the package will fail for
projects missing GoogleVR.

* Please don't check-in the removal of GoogleVRDummy.cs *

Special note about iOS 11
------------------------------------
iOS 11 and XCode 9 require any access to `[UIApplication sharedApplication].delegate` to happen on the main thread.  Due to this, to use iOS 11 with the `5.5.x` version of Unity you'll need to make a small change in the Unity code base.

1. Export the Unity project to an Xcode project.
2. Open the project in Xcode 9
3. Open the file `iPhone_Sensors.mm` and go to `sMotionManager startAccelerometerUpdatesToQueue` on line 83.
4. Replace `sMotionManager startAccelerometerUpdatesToQueue` with the code below:


		[sMotionManager startAccelerometerUpdatesToQueue: sMotionQueue withHandler:^(CMAccelerometerData* data, NSError* error) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                Vector3f res = UnityReorientVector3(data.acceleration.x, data.acceleration.y, data.acceleration.z);
                UnityDidAccelerate(res.x, res.y, res.z, data.timestamp);
                });
            }];

     