/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 * 
 * Provides the editor inspector panel for the BridgeEngineUnity class.
 * 
 * Handles Import and Removal of the BridgeEngineScene folder from a project.
 */

using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Assertions;
using UnityEditor;

[CustomEditor(typeof(BridgeEngineUnity))]
public class BridgeEngineUnityEditor : Editor
{
    /// Add an inspector header that manages the BridgeEngineScene folder import.
    public override void OnInspectorGUI()
    {
        if (Directory.Exists("Assets/BridgeEngineScene") == false)
        {
            if (BEScene.ImportFolderExists() == false)
            {
                EditorGUILayout.HelpBox("You can import your own BridgeEngineScene folder. Use a sample app, scan a space, and use iTunes to copy the BridgeEngineScene folder onto your desktop. Then import it to Unity for quicker testing.", MessageType.Info, true);

                if (GUILayout.Button("Import BridgeEngineScene folder..."))
                {
                    ImportBridgeEngineSceneFolder();
                }
            }
            else
            {
                EditorGUILayout.HelpBox("Editor/Resources/ImportedBridgeEngineScene is present", MessageType.None, true);
                if (BEScene.IsInScene() == false && GUILayout.Button("Rebuild " + BEScene.gameObjectName))
                {
                    BEScene.CreateNewBridgeEngineScene();
                }

                if (GUILayout.Button("Remove Imported BridgeEngineScene"))
                {
                    RemoveBridgeEngineSceneFolder();
                }
            }
        }
        else
        {
            EditorGUILayout.HelpBox("BridgeEngineScene needs to be imported into the correct place.", MessageType.Info, true);

            if (GUILayout.Button("Import BridgeEngineScene folder..."))
            {
                MoveBridgeEngineSceneFolder();
            }
        }
		EditorGUILayout.Space();
        base.OnInspectorGUI();
    }

	#region Functions
    // Watch for user drag-drop of BridgeEngineScene into Unity's Assets folder,
    // and move it into the correct imported location.
    static void MoveBridgeEngineSceneFolder()
    {
        string beSceneRootPath = "Assets/BridgeEngineScene";
        if (Directory.Exists("Assets/BridgeEngineScene") == false) return;

        Debug.Log("Importing BridgeEngineScene into location " + BEScene.ImportFolderPath());
        // Make sure the target base path is present.
        if (!Directory.Exists(BEScene.EditorResourcesFolderPath()))
        {
            Directory.CreateDirectory(BEScene.EditorResourcesFolderPath());
        }

        // If Imported folder already exists, replace it.
        string beSceneFolderPath = BEScene.ImportFolderPath();
        if (Directory.Exists(beSceneFolderPath))
        {
            Directory.Delete(beSceneFolderPath, true);
        }

        // Now move BridgeEngineScene folder into place.
        Directory.Move(beSceneRootPath, beSceneFolderPath);
        AssetDatabase.Refresh();
    }


    void ImportBridgeEngineSceneFolder()
    {
        string path = EditorUtility.OpenFolderPanel("Select BridgeEngineScene Folder", "~/Desktop/", "");
        if (string.IsNullOrEmpty(path) == false || Directory.Exists(path))
        {
            string dirName = Path.GetFileName(path);
            if (dirName == "BridgeEngineScene")
            {
                string destPath = BEScene.ImportFolderPath();
                if (Directory.Exists(destPath))
                {
                    string message = destPath + " folder exists. Would you like to replace it? ";
                    bool replace = EditorUtility.DisplayDialog("Replace Folder?", message, "Replace", "Cancel");

                    if (replace)
                    {
                        Debug.Log("Deleting old `BridgeEngineScene`...");
                        if (Directory.Exists(destPath))
                            Directory.Delete(destPath, true);
                    }
                    else
                    {
                        Debug.Log("`BridgeEngineScene` import cancelled");
                        return;
                    }
                }

                Debug.Log("Importing new `BridgeEngineScene`...");

                DirectoryCopy(path, destPath, true);
                AssetDatabase.Refresh();
            }
            else
            {
                Debug.LogWarning("Safety check: folder name is not `BridgeEngineScene` so not importing.");
            }
        }
    }

    void RemoveBridgeEngineSceneFolder()
    {
        string beSceneFolder = BEScene.ImportFolderPath();

        // Prefetch the next parent to check below.
        DirectoryInfo nextParent = Directory.GetParent(beSceneFolder);

        // Explicitely delete the BridgeEngineScene folder. 
        if (Directory.Exists(beSceneFolder))
        {
            Directory.Delete(beSceneFolder, true);
            File.Delete(beSceneFolder+".meta");
        }

        // Clear out any empty Folders in reverse descending order.
        // Stopping at the top level "Assets" folder.
        while( nextParent != null && nextParent.Name != "Assets" ) {
            DirectoryInfo currentDir = nextParent;
            nextParent = nextParent.Parent;

            try {
                currentDir.Delete(); // Delete any empty paths.

                // And clean up the meta file associated with it.
                string metaFile = currentDir.ToString()+".meta";
                if( File.Exists(metaFile) ) {
                    File.Delete(metaFile);
                }
            } catch(IOException)
            {
                // Stop early, we hit a non-empty folder or something else.
                nextParent = null;
            }
        }

        AssetDatabase.Refresh();
    }

    private static void DirectoryCopy(string sourceDirName, string destDirName, bool copySubDirs)
    {
        Debug.Log("Copying '" + sourceDirName + "' to '"+destDirName+"'");
        // Get the subdirectories for the specified directory.
        DirectoryInfo dir = new DirectoryInfo(sourceDirName);

        if (!dir.Exists)
        {
            throw new DirectoryNotFoundException(
                "Source directory does not exist or could not be found: "
                + sourceDirName);
        }

        DirectoryInfo[] dirs = dir.GetDirectories();
        // If the destination directory doesn't exist, create it.
        if (!Directory.Exists(destDirName))
        {
            Directory.CreateDirectory(destDirName);
        }

        // Get the files in the directory and copy them to the new location.
        FileInfo[] files = dir.GetFiles();
        foreach (FileInfo file in files)
        {
            string temppath = Path.Combine(destDirName, file.Name);
            file.CopyTo(temppath, false);
        }

        // If copying subdirectories, copy them and their contents to new location.
        if (copySubDirs)
        {
            foreach (DirectoryInfo subdir in dirs)
            {
                string temppath = Path.Combine(destDirName, subdir.Name);
                DirectoryCopy(subdir.FullName, temppath, copySubDirs);
            }
        }
    }
	#endregion
}

class BridgeEngineScenePostProcessor : AssetPostprocessor
{
    static void OnPostprocessAllAssets(string[] importedAssets, string[] deletedAssets, string[] movedAssets, string[] movedFromAssetPaths)
    {
        // Construct new BridgeEngineScene GameObject if we just imported it.
        foreach (var assetPath in importedAssets)
        {
            if (assetPath == BEScene.ImportFolderPath()
                && BridgeEngineUnity.IsInScene()
                && (BEScene.IsInScene() == false))
            {
                BEScene.CreateNewBridgeEngineScene();
                break;
            }
        }

        // Clean-up if we removed the BridgeEngineScene.
        foreach (var assetPath in deletedAssets)
        {
            if(assetPath == BEScene.ImportFolderPath()
                && BridgeEngineUnity.IsInScene()
                && BEScene.IsInScene())
            {
                Debug.Log("Removing " + BEScene.gameObjectName +" from Hierarchy");
                GameObject beScene = GameObject.Find(BEScene.gameObjectName);
                if (beScene)
                {
                    GameObject.DestroyImmediate(beScene);
                    break;
                }
            }
        }
    }
}
