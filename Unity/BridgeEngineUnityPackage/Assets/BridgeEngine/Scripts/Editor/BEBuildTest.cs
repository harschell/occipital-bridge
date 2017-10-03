/*
 * This file is part of the Structure SDK.
 * Copyright © 2017 Occipital, Inc. All rights reserved.
 * http://structure.io
 * 
 * Performs build testing functionality when deploying a BridgeEngine.unitypackage
 */

using System;
using NUnit.Framework;

using UnityEditor;
using UnityEditor.SceneManagement;

using UnityEngine;

class BETests {

    /// Perform any build checks here.
    [Test]
    public void BuildCheck() {
        UnityEngine.SceneManagement.Scene scene = EditorSceneManager.OpenScene("Assets/BridgeEngine/Example/Scenes/MR Example.unity");
        Assert.That( scene.IsValid() );

        var buildScene = new EditorBuildSettingsScene(scene.path, true);
        EditorBuildSettings.scenes = new EditorBuildSettingsScene[] {buildScene};
        Assert.That(EditorBuildSettings.scenes.Length == 1);
    }
}
