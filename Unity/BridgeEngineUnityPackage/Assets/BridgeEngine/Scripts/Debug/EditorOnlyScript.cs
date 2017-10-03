/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 */
 
using UnityEngine;

/// Self-destruct the GameObject if run outside the editor/simulator at runtime.
[BEScriptOrder(-10000)]
public class EditorOnlyScript : MonoBehaviour {
	void Awake ()
	{
		if (Application.isEditor == false)
		{
			GameObject.Destroy(this.gameObject);
		}
	}
}
