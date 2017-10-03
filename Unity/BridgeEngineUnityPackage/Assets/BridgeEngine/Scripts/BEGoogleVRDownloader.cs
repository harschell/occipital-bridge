/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 * 
 * Automatically detect if GoogleVRForUnity is missing from the project.
 * Offer to download & install it.
 */

using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

// This dummy namespace is used for getting past compile-time dependencies
// by filling them in with temporary class stubs in GoogleVRDummy.cs
//
// Upon successful detection, then GoogleVRDummy.cs is deleted and scripts are reloaded.
//
// It's necessary to keep this namespace around for BEEye.cs and BridgeEngineUnity.cs
// They both have "using BEDummyGoogleVR;"
namespace BEDummyGoogleVR {}

#if UNITY_EDITOR

[UnityEditor.InitializeOnLoad]
public class BEGoogleVRDownloader
{
	private static readonly string INSTALL_IS_IN_PROGRESS_PATH = "BridgeEngineGVRInstallInProgress.check";
	private static readonly string IGNORE_GOOGLE_VR_CHECK_PATH = "BridgeEngineIgnoreGVR.check";
	private static readonly string REENABLE_COMPATIBILITY_CHECK_MESSAGE =
		"GoogleVR check can be re-enabled by deleting " + IGNORE_GOOGLE_VR_CHECK_PATH;

	static WWW downloader = null;

    static BEGoogleVRDownloader()
    {
		if (UnityEditorInternal.InternalEditorUtility.inBatchMode || UnityEditorInternal.InternalEditorUtility.isHumanControllingUs == false)
			return;

		if (IsIgnoreGoogleVRCheck() == false)
		{
			bool isGoogleVRDetected = DetectGoogleVR();
			if (isGoogleVRDetected)
			{
				DeleteGoogleVRDummy();
				DeleteGoogleVRUnityPackagePath();
				DeleteInstallInProgress();
			}
			else if (IsInstallInProgress() == false)
			{
				int option = UnityEditor.EditorUtility.DisplayDialogComplex("GoogleVR is missing",
					"To use Bridge Engine with Unity you need the GoogleVR library. Do you want to download it?",
					"Yes, Download",
					"No and never ask",
					"No");

				switch (option) {
				case 0:
					DownloadAndImportGoogleVRAsset();
					return;

				case 1: // Do not check, and do not check again.
					System.IO.File.Create(IGNORE_GOOGLE_VR_CHECK_PATH);
					Debug.Log("<b>Bridge Engine</b>: " + IGNORE_GOOGLE_VR_CHECK_PATH + " created. Delete it to re-enable check");
					UnityEditor.EditorUtility.DisplayDialog("Skipping GoogleVR check", REENABLE_COMPATIBILITY_CHECK_MESSAGE, "Ok");
					return;

				case 2: // Do not check
					// Fall through.
				default:
					return;
				}
			}	
		}
    }

	public static bool IsInstallInProgress()
	{
		return System.IO.File.Exists(INSTALL_IS_IN_PROGRESS_PATH);
	}
	
	static void DeleteInstallInProgress()
	{
		if (System.IO.File.Exists(INSTALL_IS_IN_PROGRESS_PATH))
			System.IO.File.Delete(INSTALL_IS_IN_PROGRESS_PATH);
	}

	static void CreateInstallInProgressCheckFile()
	{
		System.IO.File.Create(INSTALL_IS_IN_PROGRESS_PATH);
	}

	public static bool IsIgnoreGoogleVRCheck()
	{
		return System.IO.File.Exists(IGNORE_GOOGLE_VR_CHECK_PATH);
	}

	static void DeleteGoogleVRDummy()
	{
		string[] paths = UnityEditor.AssetDatabase.FindAssets("GoogleVRDummy");
		bool detectedDummy = paths.Length > 0;

		if (detectedDummy)
		{
			string path = UnityEditor.AssetDatabase.GUIDToAssetPath(paths[0]);

			UnityEditor.AssetDatabase.DeleteAsset(path); // disable script
			UnityEditor.AssetDatabase.DeleteAsset(path + ".meta"); // disable script
			UnityEditor.AssetDatabase.Refresh();
		}
	}

	static bool DetectGoogleVR()
	{
		return Directory.Exists("Assets/GoogleVR");
	}

	static string GoogleVRUnityPackagePath()
	{
		return "Library/googleVR.unitypackage";
	}

	static void DeleteGoogleVRUnityPackagePath()
	{
		if (System.IO.File.Exists(GoogleVRUnityPackagePath()))
			System.IO.File.Delete(GoogleVRUnityPackagePath());
	}

	static string GoogleVRUnityPackageURL()
	{
		return "https://github.com/googlevr/gvr-unity-sdk/releases/download/1.70.0/GoogleVRForUnity_1.70.0.unitypackage";
	}

	static void ShowProgressBar(float progress)
	{
		UnityEditor.EditorUtility.DisplayProgressBar("Downloading..", "Downloading GoogleVRForUnity.unitypackage", progress);
	}

	static void ImportPackage(string path)
	{
		CreateInstallInProgressCheckFile();
		UnityEditor.AssetDatabase.ImportPackage(path, false);
		DeleteGoogleVRUnityPackagePath();
	}

	static void DownloadAndImportGoogleVRAsset()
	{
		bool alreadyDownloaded = System.IO.File.Exists(GoogleVRUnityPackagePath());

		if (alreadyDownloaded)
		{
			ImportPackage(GoogleVRUnityPackagePath());
		}
		else
		{
			Debug.Log("<b>Bridge Engine</b>: Cannot find GoogleVR package, trying to download it");
			downloader = new WWW(GoogleVRUnityPackageURL());
			UnityEditor.EditorApplication.update += Update;
		}
	}

	static void OnDownloadFinished(WWW downloader)
	{
		var googleVRPackagePath = GoogleVRUnityPackagePath();
		System.IO.File.WriteAllBytes(googleVRPackagePath, downloader.bytes);
		
		ImportPackage(googleVRPackagePath);
	}

	static void OnDownloadFinishedWithError(WWW downloader)
	{
		Debug.LogError("<b>Bridge Engine</b>: GoogleVRForUnity.unitypackage download failed: " + downloader.error);
	}

	static void Update()
	{
		if (downloader != null)
		{
			if (downloader.isDone)
			{
				if (string.IsNullOrEmpty(downloader.error))
					OnDownloadFinished(downloader);
				else
					OnDownloadFinishedWithError(downloader);

				UnityEditor.EditorUtility.ClearProgressBar();
				downloader = null;
			}
			else
				ShowProgressBar(downloader.progress);
		}

		if (downloader == null)
			UnityEditor.EditorApplication.update -= Update;
	}
}
#endif
