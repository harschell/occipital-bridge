/**********************************************************************
This file is part of the Structure SDK.
Copyright © 2015 Occipital, Inc. All rights reserved.
http://structure.io
**********************************************************************/

/// <summary>
/// Script Order Manager sets the execution order or a script with a simple attribute assignment:
///  [ScriptOrder(-10)]
///  public class BridgeEngineUnity : MonoBehaviour {}
/// 
/// As designed by: FlyingOstriche
/// https://forum.unity3d.com/threads/script-execution-order-manipulation.130805/#post-1876943
/// </summary>

using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

#if UNITY_EDITOR

[InitializeOnLoad]
public class BEScriptOrderManager {
	static BEScriptOrderManager() {
		foreach (MonoScript monoScript in MonoImporter.GetAllRuntimeMonoScripts()) {
			if (monoScript.GetClass() != null) {
				foreach (var a in Attribute.GetCustomAttributes(monoScript.GetClass(), typeof(BEScriptOrder))) {
					var currentOrder = MonoImporter.GetExecutionOrder(monoScript);
					var newOrder = ((BEScriptOrder)a).order;
					if (currentOrder != newOrder)
						MonoImporter.SetExecutionOrder(monoScript, newOrder);
				}
			}
		}
	}
}

#endif // UNITY_EDITOR
