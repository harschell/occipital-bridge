/**********************************************************************
  This file is part of the Structure SDK.
  Copyright © 2015 Occipital, Inc. All rights reserved.
  http://structure.io
**********************************************************************/

using UnityEngine;
using System.Collections;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Xml;
using System.IO;
using System.Threading;
using Debug = UnityEngine.Debug;

#if UNITY_EDITOR

using UnityEditor;
using UnityEditor.Callbacks;

// If you get a "missing assembly reference" on the below line, this is because you do not have Unity iOS Build Support installed.
// xcodeapi added as it said here:
// http://forum.unity3d.com/threads/how-can-you-add-items-to-the-xcode-project-targets-info-plist-using-the-xcodeapi.330574/
using BridgeEngine.iOS.Xcode;

using PlistEntry = System.Collections.Generic.KeyValuePair<string, BridgeEngine.iOS.Xcode.PlistElement>; 

// IOSArchitectures taken from: http://forum.unity3d.com/threads/4-6-ios-64-bit-beta.290551/page-11
enum IOSArchitectures : int
{
	Armv7 = 0,
	Arm64 = 1,
	Universal = 2,
};

[InitializeOnLoad]
public class BEUnityPluginOnLoad : MonoBehaviour
{
	static string[] assetsToCopy = new string[] {
		"StartingUnity-mono.png",
		"StartingUnity-stereo.png"
	};

	static string[] frameworksToAdd = new string[] {
		"ExternalAccessory.framework",
		"CoreBluetooth.framework",
		"GLKit.framework",
		"ReplayKit.framework"
	};

	static BEUnityPluginOnLoad ()
	{
		// // Check we are using the compatible Unity version.  (Temporary Limitation)
		// bool isVersion5_5_x = Application.unityVersion.StartsWith("5.5");
		// if( isVersion5_5_x == false ) {
		// 	EditorUtility.DisplayDialog("Incompatible Unity Version", "BridgeEngine currently requires version 5.5 of unity to run correctly. This is a temporary limitation.", "Got It" );
		// }

		// Check if we have the BEUnityEditorPlugin.bundle
        if (Directory.Exists("Assets/BridgeEngine/Plugins/Editor/BEUnityEditorPlugin.bundle") == false) {
			EditorUtility.DisplayDialog("Missing BEUnityEditorPlugin.bundle", "The BEUnityEditorPlugin native plugin is needed for controller interaction in Unity.  Probably needs building.", "Got It" );
		}

		#if UNITY_5_5_OR_NEWER
		PlayerSettings.iOS.targetOSVersionString = "9.3";
		#else
		PlayerSettings.iOS.targetOSVersion = iOSTargetOSVersion.iOS_9_3;
		#endif

		// FIXME: Need to pass color camera via OpenGL ES2 sharedcontext texture for now, however we should be passing the CVPixelBuffer and allow working with any Graphics API.
		PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.iOS, false);
		PlayerSettings.SetGraphicsAPIs(BuildTarget.iOS, new UnityEngine.Rendering.GraphicsDeviceType[] {UnityEngine.Rendering.GraphicsDeviceType.OpenGLES2});

		// We need VR mode enabled.
		PlayerSettings.virtualRealitySupported = true;

        // UNITY FIXME: ... But there's no API for adding the Cardboard SDK.

		// Use IL2CPP (the only arm64-capable one) as a scripting backend.
		PlayerSettings.SetScriptingBackend( BuildTargetGroup.iOS, ScriptingImplementation.IL2CPP );
    	
		// Assuming you want to build Arm64 only.
		PlayerSettings.SetArchitecture( BuildTargetGroup.iOS, (int)IOSArchitectures.Arm64);
		
		// Fix for iOS 10, required Camera Description for else app will crash.
		//   cameraUsageDescription: Required for GoogleVR barcode scanning.
		var cameraUsageDesc = PlayerSettings.iOS.cameraUsageDescription;
		if( cameraUsageDesc == null || cameraUsageDesc.Length == 0 ) {
			PlayerSettings.iOS.cameraUsageDescription = "Required for Bridge Engine to work.";
		}
		
		// Set screen rotation locks.
		PlayerSettings.allowedAutorotateToPortrait = false;
		PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
		PlayerSettings.allowedAutorotateToLandscapeRight = false;
		PlayerSettings.allowedAutorotateToLandscapeLeft = true; 
		
		// Tune up the accelerometer frequency.
		PlayerSettings.accelerometerFrequency = 100; 

		// Remove Skybox default on MainCamera if we can find it.
		Camera mainCamera = Camera.main;
		if( mainCamera != null ) {
			// Check for camera defaults.
			Color defaultColor = new Color(49/255.0f, 77/255.0f, 121/255.0f, 0);
			if( mainCamera.clearFlags == CameraClearFlags.Skybox && mainCamera.backgroundColor == defaultColor) {
				Debug.Log("MainCamera is using Default Colour, setting it to Black for better MR experience");
				// Reset to black.
				mainCamera.clearFlags = CameraClearFlags.SolidColor;
				mainCamera.backgroundColor = Color.black;
			}
		}

		EditorApplication.update += Update;
	}
	
	static void Update ()
	{
		// Called once per frame, by the editor.
	}
	
	[PostProcessBuildAttribute]
	public static void OnPostprocessBuild (BuildTarget target, string pathToBuiltProject)
	{
		if (target != BuildTarget.iOS)
			return;
		
		//NOTE: these patches are not robust to Xcode generation by Append, only Rebuild
		PatchXcodeProject(pathToBuiltProject);
		
		PatchInfoPlist(pathToBuiltProject);
		
		// This needs to done after we have rewritten everything, because it may trigger an Xcode launch.
		SelectXcodeBuildConfiguration(pathToBuiltProject, "Debug");
	}

	public static string checkPBXProjectPath (string projectPath)
	{
		//In versions of Unity < 5.1.3p2,
		// the xcode project path returned by PBXProject.GetPBXProjectPath
		// is incorrect. We fix it here.

		string projectBundlePath = Path.GetDirectoryName(projectPath);

		if (projectBundlePath.EndsWith(".xcodeproj"))
			return projectPath;
		else
			return projectBundlePath + ".xcodeproj/project.pbxproj";
	}

    public static string GetTargetGUID(string projectPath, string targetName)
    {
        PBXProject project = new PBXProject();

        project.ReadFromFile(projectPath);

        return project.TargetGuidByName(targetName);
    }
	
	public static void PatchXcodeProject (string pathToBuiltProject)
	{
		PBXProject project = new PBXProject();
		
		string projectPath = PBXProject.GetPBXProjectPath(pathToBuiltProject);

		projectPath = checkPBXProjectPath(projectPath);

		project.ReadFromFile(projectPath);
		
		string guid = project.TargetGuidByName("Unity-iPhone");

		foreach( var frameworkName in frameworksToAdd ) {
			project.AddFrameworkToProject(guid, frameworkName, false);
		}

        bool useAsExternalProject = false;	
        if (useAsExternalProject)
        {
			// this will add BridgeEngine.xcodeproj to current workspace, so we can rebuild it as dependency
        	string bridgeEngineProjPath = Path.GetFullPath("../../Frameworks/BridgeEngine.xcodeproj");
        	project.AddExternalProjectDependency(bridgeEngineProjPath, "BridgeEngine.xcodeproj", PBXSourceTree.Absolute);
        	
        	project.AddBuildProperty(guid, "HEADER_SEARCH_PATHS", "\"" +
        		Path.GetFullPath("../../Frameworks/BridgeEngine/Headers") + "\"" +
        		" \"" + Path.GetFullPath("../../Frameworks/BridgeEngine/Headers/Structure/Private") + "\"");
        }
        else
        {
			var filename = "Frameworks/BridgeEngine/Plugins/iOS/BridgeEngine.framework";
			
			var fileGuid = project.FindFileGuidByProjectPath(filename);
            if (fileGuid == null)
                fileGuid = project.FindFileGuidByRealPath(filename);
            if (fileGuid == null)
                throw new System.Exception("Cannot find " + filename + " framework. EmbedFramework failed");
            
			// this will just embed existing framework. framework should be up-to-date 
			project.EmbedFramework(guid, fileGuid);

			// For Structure Partners
			project.AddBuildProperty(guid, "HEADER_SEARCH_PATHS", 
				"\"$(SRCROOT)/Frameworks/BridgeEngine/Plugins/iOS/BridgeEngine.framework/extra-Headers\"");

			project.AddBuildProperty(guid, "HEADER_SEARCH_PATHS", 
				"\"$(SRCROOT)/Frameworks/BridgeEngine/Plugins/iOS/BridgeEngine.framework/extra-Headers/Structure/Private\"");
        }

		project.AddFileToBuild(guid, project.AddFile("usr/lib/libz.dylib", "Frameworks/libz.dylib", PBXSourceTree.Sdk));

		string projectFolderForAsset = "Libraries/BridgeEngine/Plugins/iOS";
			
		Directory.CreateDirectory(Path.Combine(pathToBuiltProject, projectFolderForAsset));

		// Copy and install any assets we need for the plugin.
		foreach( var assetToCopy in assetsToCopy ) {
			string assetPath = "Assets/BridgeEngine/Plugins/iOS/" + assetToCopy;
			string projectPathForAsset = Path.Combine(projectFolderForAsset, assetToCopy);
			string srcAssetPath = Path.GetFullPath(assetPath);
			string destProjectPathForAsset = Path.Combine(pathToBuiltProject, projectPathForAsset);
			FileUtil.CopyFileOrDirectory( srcAssetPath, destProjectPathForAsset );

			string guidAsset = project.AddFile( projectPathForAsset, projectPathForAsset);
			project.AddFileToBuild(guid, guidAsset);
		}

		// The following settings lead to a quicker build
		string debugConfig = project.BuildConfigByName(guid, "Debug");
		string releaseConfig = project.BuildConfigByName(guid, "Release");
		// string releaseForProfilingConfig = project.BuildConfigByName(guid, "ReleaseForProfiling");
		// string releaseForRunningConfig = project.BuildConfigByName(guid, "ReleaseForRunning");

		var releaseConfigurations = new string[] {releaseConfig};//, releaseForProfilingConfig, releaseForRunningConfig};
		foreach( var config in releaseConfigurations ) {
			project.SetBuildPropertyForConfig(config, "DEBUG_INFORMATION_FORMAT", "dwarf");
			project.SetBuildPropertyForConfig(config, "ONLY_ACTIVE_ARCH", "YES");
			project.SetBuildPropertyForConfig(config, "ENABLE_BITCODE", "NO");		
			project.SetBuildPropertyForConfig(config, "GCC_PREPROCESSOR_DEFINITIONS", "$(inherited)");

#if UNITY_HAS_GOOGLEVR
			if( PlayerSettings.virtualRealitySupported ) {
				project.AddBuildPropertyForConfig(config, "OTHER_CFLAGS", "-DUNITY_HAS_GOOGLEVR=1");
			}
#endif
		}

		// XCode7 enables BitCode for all projects by default.  Neither the Structure SDK nor Unity support BitCode at this time
		project.SetBuildPropertyForConfig(debugConfig, "ENABLE_BITCODE", "NO");
		project.SetBuildPropertyForConfig(debugConfig, "GCC_PREPROCESSOR_DEFINITIONS", "$(inherited)");

		// we need to define DEBUG=1 to build properly
		project.AddBuildPropertyForConfig(debugConfig, "GCC_PREPROCESSOR_DEFINITIONS", "DEBUG=1");

#if UNITY_HAS_GOOGLEVR
		// We need UNITY_HAS_GOOGLEVR if native GoogleVR is enabled.
		if( PlayerSettings.virtualRealitySupported ) {
			project.AddBuildPropertyForConfig(debugConfig, "OTHER_CFLAGS", "-DUNITY_HAS_GOOGLEVR=1");
		}
#endif

		// StructurePartners uses gnu++14. This also makes GLK easier to use.
		project.SetBuildProperty(guid, "CLANG_CXX_LANGUAGE_STANDARD", "gnu++14");

		project.WriteToFile(projectPath);
	}
	
	public static void PatchInfoPlist(string pathToBuiltProject)
	{
		string plistPath = Path.Combine(pathToBuiltProject, "Info.plist");
		
		PlistDocument plist = new PlistDocument();
		plist.ReadFromFile(plistPath);
		
		
		// =================================
		// We must do this here instead of passing the plist to
		//  a useful helper function because Unity refuses to build functions
		//  where a variable of type PlistDocument is passed.
        {
    		string key = "UISupportedExternalAccessoryProtocols";
    		string[] values = new string[3]
    		{
    			"io.structure.control",
    			"io.structure.depth",
    			"io.structure.infrared"
    		};
    		
    		if (plist.root.values.ContainsKey(key))
    			return;
    		
    		PlistElementArray array = new PlistElementArray();
    		foreach (string value in values)
    			array.AddString(value);
    		
    		plist.root.values.Add (new PlistEntry(key, array));
        }
		// =================================
		
		
		plist.root.values.Add( new PlistEntry("UIFileSharingEnabled", new PlistElementBoolean(true) ) );
		plist.WriteToFile(plistPath);
	}
	
	public static void TriggerXcodeDefaultSharedSchemeGeneration (string pathToBuiltProject)
	{
		// Launch Xcode to trigger the scheme generation.
		ProcessStartInfo proc = new ProcessStartInfo();
		
		proc.FileName = "open";
		proc.WorkingDirectory = pathToBuiltProject;
		proc.Arguments = "Unity-iPhone.xcodeproj";
		proc.WindowStyle = ProcessWindowStyle.Hidden;
		proc.UseShellExecute = true;
		Process.Start(proc);
		
		Thread.Sleep(3000);
	}
	
	public static string GetDefaultSharedSchemePath (string pathToBuiltProject)
	{
		return Path.Combine(pathToBuiltProject, "Unity-iPhone.xcodeproj/xcshareddata/xcschemes/Unity-iPhone.xcscheme");
	}
	
	public static void SelectXcodeBuildConfiguration (string pathToBuiltProject, string configuration)
	{
		string schemePath = GetDefaultSharedSchemePath(pathToBuiltProject);
		
		if (!File.Exists(schemePath))
			TriggerXcodeDefaultSharedSchemeGeneration(pathToBuiltProject);
		
		if (!File.Exists(schemePath))
		{
			//Debug.Log("Xcode scheme project generation failed. You will need to manually select the 'Release' configuration. The deployed iOS application performance will be disastrous, otherwise.");
			return;
		}
		
		XmlDocument xml = new XmlDocument();
		xml.Load(schemePath);
		XmlNode node = xml.SelectSingleNode("Scheme/LaunchAction");
		node.Attributes["buildConfiguration"].Value = configuration;
		xml.Save(schemePath);
	}	
}

#endif
