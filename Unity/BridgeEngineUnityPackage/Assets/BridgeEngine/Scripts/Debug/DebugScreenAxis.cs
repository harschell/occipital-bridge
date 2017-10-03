/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 */

using UnityEngine;
using System.Collections;

public class DebugScreenAxis : MonoBehaviour
{
    public float distance = 10.0f;
    public Camera mainCamera;

    public void UpdatePosition()
    {
        if (mainCamera == null)
            return;

        this.transform.rotation = Quaternion.identity;
        this.transform.position = mainCamera.transform.position + mainCamera.transform.forward * distance;
    }

	void LateUpdate ()
    {
        UpdatePosition();
	}
}
