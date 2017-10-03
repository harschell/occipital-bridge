/*
 * This file is part of the Structure SDK.
 * Copyright © 2017 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 * Generates a lens distortion mesh for projecting the source camera
 * onto the screen with optical distortion.
 */

using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LensDistortionMesh : MonoBehaviour
{
	public Camera sourceCamera;
	public BEEyeSide side;

	Vector2 __u_focalLength;
	Vector2 __u_distortionCoeff;
	float __u_centerOffset;

	public Mesh mesh;
	Material material;

	public void CreateMesh ()
	{
		__u_focalLength = new Vector2(sourceCamera.projectionMatrix.m00, sourceCamera.projectionMatrix.m11);
		__u_distortionCoeff = new Vector2(0.26f, 0.16f);
		__u_centerOffset = sourceCamera.projectionMatrix.m02;

		const int n = 50; // 50 steps, 25 on either side of the nose.
		const float step = 1.0f/(float)n;

		const int n_mid = n / 2;

		// Create a vertex and triangle/quad mesh
		// Pad out the right and bottom edges, for the mesh grid.
		const int verticesCount = (n+1) * (n+1);
		const int indiciesCount = n * n * 6;

		Vector3[] vertices = new Vector3[verticesCount];
		Vector2[] uv = new Vector2[verticesCount];
		int[] indicies = new int[indiciesCount];

		// Generate a coordinate grid in the range of -1 to 1.
		// Left eye: 	x is -1 to 0, u is 0 to 0.5
		// Right eye:	x is 0 to 1,  u is 0.5 to 1

		// Adjust the results so they fit into an eye target.
		float u_offset_for_eye = side==BEEyeSide.Left ? 0.0f : -0.5f;
		float u_scale_for_eye = 2.0f;

		float x_offset_for_eye = side==BEEyeSide.Left ? 0.5f : -0.5f;
		float x_scale_for_eye = 2.0f;

		// n_mid and n_mid+1 creates a gap that 
		for (int i = 0; i <= n; ++i)
		{
			for (int j = 0; j <= n; ++j)
			{
				float x = i * step;
				float y = j * step;

				if (i == n_mid || i == n_mid+1)	// corner case for middle gap
				 	x = 0.5f;
				
				var texCoord = DistortXYtoUV(ref x, ref y, i <= n_mid);
				texCoord.x = (texCoord.x + u_offset_for_eye) * u_scale_for_eye;
				var p = new Vector3(x * 2.0f - 1.0f, y * 2.0f - 1.0f, 1.0f);
				p.x = (p.x + x_offset_for_eye) * x_scale_for_eye;
				
				int indx = j * (n+1) + i;
				vertices[indx] = p;
				uv[indx] = texCoord;
			}
		}

		int cnt = 0;
		for (int i = 0; i < n; ++i)
		{
			if (i == n_mid) continue;	// gap between left and right parts

			for (int j = 0; j < n; ++j)
			{
				// Add quad:
				// a b
				// c d

				int a = j * (n+1) + i;
				int b = j * (n+1) + (i+1);
				int c = (j+1) * (n+1) + i;
				int d = (j+1) * (n+1) + (i+1);

				indicies[cnt++] = a;
				indicies[cnt++] = b;
				indicies[cnt++] = c;
				
				indicies[cnt++] = c;
				indicies[cnt++] = b;
				indicies[cnt++] = d;

				if (d >= verticesCount)
					Debug.LogErrorFormat("indx out of vertices count = {0} out of {1}", d, verticesCount);
			}
		}

		mesh = new Mesh();
		mesh.vertices = vertices;
		mesh.uv = uv;
		mesh.triangles = indicies;
		
		material = new Material(Shader.Find("Hidden/Occipital/LensDistortionMesh"));
		material.SetTexture("_MainTex", sourceCamera.targetTexture);
	}

	private Vector3 DistortXYtoUV(ref float uv_x, ref float uv_y, bool isLeft)
	{
		var sampleCoord = Vector2.zero;

		for (int guard = 0; guard < 1024; ++guard)	// guard to prevent infinite loop
		{
			sampleCoord = GetDistortTexCoord(uv_x, uv_y, isLeft);

			bool inRangeX = sampleCoord.x >= 0.0f && sampleCoord.x <= 1.0f;
			bool inRangeY = sampleCoord.y >= 0.0f && sampleCoord.y <= 1.0f;

			if (inRangeX && inRangeY)
				break;

			const float step = 0.0001f;	// TODO: make dynamic step size. maybe use Newton method / binary search

			// adjust input coords to be in [0..1] uv space
			if (sampleCoord.x < 0)
				uv_x += step;
			else if (sampleCoord.x > 1)
				uv_x -= step;

			if (sampleCoord.y < 0)
				uv_y += step;
			else if (sampleCoord.y > 1)
				uv_y -= step;
		}
		
		return new Vector3(0.5f * sampleCoord.x + (isLeft ? 0.0f : 0.5f) , sampleCoord.y, 1.0f);
	}

	private Vector2 GetDistortTexCoord(float uv_x, float uv_y, bool isLeft)
	{
		var isRight = (isLeft) ? 0.0f : 1.0f;
	
		var eye_uv = new Vector2((uv_x - (0.5f * isRight)) * 2.0f, uv_y);
		var projection = new Vector4(__u_focalLength.x, __u_focalLength.y, -1.0f - (isRight * 2.0f - 1.0f) * __u_centerOffset, -1.0f) * 0.5f;

		// deproject to NDC and z=1 plane in one step
		var deproj = (eye_uv + new Vector2(projection.z, projection.w));
		deproj = new Vector2(deproj.x / projection.x, deproj.y / projection.y);

		var r2 = deproj.x * deproj.x + deproj.y * deproj.y;
		
		var distortion = 1.0f + (__u_distortionCoeff.x + __u_distortionCoeff.y * r2) * r2;
		
		//TODO: auto zoom factor here
		var zoomFactor = 0.9f; //- __u_distortionCoeff.x / __u_focalLength.x - __u_distortionCoeff.y / pow(__u_focalLength.x, 3.0);
		
		// project from z=1 plane into the NDC and then 
		//const float zoom_r = 0.993f;
		// float __sample_coord_r_x = zoom_r * zoomFactor * projection.x * distortion * deproj.x - projection.z;
		// float __sample_coord_r_y = zoom_r * zoomFactor * projection.y * distortion * deproj.y - projection.w;
		
		const float zoom_g = 0.997f;
		var __sample_coord_g_x = zoom_g * zoomFactor * projection.x * distortion * deproj.x - projection.z;
		var __sample_coord_g_y = zoom_g * zoomFactor * projection.y * distortion * deproj.y - projection.w;
		
		//const float zoom_b = 1.007f;
		// float __sample_coord_b_x = zoom_b * zoomFactor * projection.x * distortion * deproj.x - projection.z;
		// float __sample_coord_b_y = zoom_b * zoomFactor * projection.y * distortion * deproj.y - projection.w;
		
		return new Vector2(__sample_coord_g_x, __sample_coord_g_y);
	}

	void OnPostRender()
	{
		material.SetPass(0);
		Graphics.DrawMeshNow(mesh, transform.position, transform.rotation);
    }
}
