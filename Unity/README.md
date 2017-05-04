Bridge Engine for Unity Package
===============================

The Unity project `BridgeEngineUnityPackage` is for building the
`BridgeEngine.unitypackage` (pre-built package included) for development and includes an
example scenes "Assets/Scenes/MainExample.unity".

If you're interested in starting a fresh Unity project from scratch, you can follow along
with `BridgeEngineUnity-Getting-Started.pdf`, and copy in Models and Scripts from
`GettingStartedAssets`.

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
