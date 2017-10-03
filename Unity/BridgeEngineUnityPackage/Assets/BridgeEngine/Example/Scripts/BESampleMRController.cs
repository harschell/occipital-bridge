/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 * Mixed Reality interaction demo:
 *  - Add an event trigger to the BEScene geometry, and listen for when we're interacting with it.
 *  - Show a placement ring when we're actively looking at the BEScene, otherwise hide it.
 *  - Using a listener for onControllerDidPressButton events for button presses
 *     Pull trigger to place objects into the scene.
 */

using UnityEngine;
using UnityEngine.EventSystems;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

using BEDummyGoogleVR;
namespace BEDummyGoogleVR {}

public class BESampleMRController : MonoBehaviour {
	BridgeEngineUnity beUnity;

	public GameObject placementRing;
	public List<GameObject> placeObjects;
	List<EventTrigger> worldEventTriggers = new List<EventTrigger>();
	const float FallHeight = 0.5f;

	/**
	 * Automatically attach to BEUnity on the default MainCamera, and add a listener for onControllerDidPressButton events.
	 */
	void Awake() {
		beUnity = BridgeEngineUnity.main;
		if (beUnity) {
			beUnity.onControllerButtonEvent.AddListener(OnButtonEvent);
		} else {
			Debug.LogWarning("Cannot connect to BridgeEngineUnity controller.");
		}
	}

	// Use this for initialization
	void Start () {
		// Deactivate all the objects to place by default.
		foreach( GameObject o in placeObjects ) {
			o.SetActive(false);
		}

		// Hide placement ring by default on start.
		placementRing.SetActive(false);

	    // Create an EventTriggers on every collidable mesh in BEScene
		BEScene beScene = BEScene.FindBEScene();
		Debug.Assert(beScene != null, "BESampleMRController requires a valid @BridgeEngineScene to work properly" );

        foreach (MeshCollider collider in beScene.GetComponentsInChildren<MeshCollider>())
        {
			var trigger = collider.gameObject.AddComponent<EventTrigger>();
			worldEventTriggers.Add(trigger);

			EventTrigger.Entry entryEnter = new EventTrigger.Entry();
			entryEnter.eventID = EventTriggerType.PointerEnter;
			entryEnter.callback.AddListener((data) => { OnPlaceHilight(true); });
			trigger.triggers.Add(entryEnter);

			EventTrigger.Entry entryExit = new EventTrigger.Entry();
			entryExit.eventID = EventTriggerType.PointerExit;
			entryExit.callback.AddListener((data) => { OnPlaceHilight(false); });
			trigger.triggers.Add(entryExit);
        }
	}

    /// Utility to get the GameObject bounds
    Bounds GameObjectMaxBounds(GameObject g) {
        var b = new Bounds(g.transform.position, Vector3.zero);
        foreach (Renderer r in g.GetComponentsInChildren<Renderer>())
        {
            b.Encapsulate(r.bounds);
        }
        return b;
    }

	void OnPlaceHilight( bool showPlacementRing ){
		placementRing.SetActive(showPlacementRing);

		// // Scale the placement ring to whatever size is the current objectToPlace.
		// if( showPlacementRing ) {
		// 	var objectToPlace = placeObjects.First();
		// 	if( objectToPlace ) {
		// 		float radius = GameObjectMaxBounds(objectToPlace).extents.magnitude;
		// 		float thickness = placementRing.transform.localScale.y;
		// 		placementRing.transform.localScale = new Vector3(radius, thickness, radius);
		// 	}
		// }
	}

	/// Prevent unnecessary memory allocation to improve performance.
	/// https://docs.unity3d.com/ScriptReference/Physics.SphereCastNonAlloc.html
	private const int maxRaycastHits = 64;
	private RaycastHit[] raycastResults = new RaycastHit[maxRaycastHits];

	/// Used to sort the raycast hits by distance.
	private class HitComparer: IComparer<RaycastHit> {
		public int Compare(RaycastHit lhs, RaycastHit rhs) {
		return lhs.distance.CompareTo(rhs.distance);
		}
	}
	private HitComparer hitComparer = new HitComparer();

    /**
	 * Utility to find where a pointer is intersecting the world.
	 * 
	 */ 
    bool sphereHitFromPointer( ref RaycastResult result, float sphereRadius ) {
        var pt = GvrPointerInputModule.Pointer.PointerTransform;
		var ray = new Ray( pt.position, pt.forward );
		var camera = Camera.main;
		float distanceLimit = camera.farClipPlane - camera.nearClipPlane;
		int numHits = Physics.SphereCastNonAlloc(pt.position, sphereRadius, pt.forward, raycastResults, maxDistance:distanceLimit, layerMask:Physics.DefaultRaycastLayers, queryTriggerInteraction:QueryTriggerInteraction.Ignore);

		// Bail if nothing.
		if( numHits == 0 ) { return false; }

		if (numHits == maxRaycastHits) {
			Debug.LogWarningFormat("Spherecast returned {0} hits, which is the current " +
				"maximum and means that some hits may have been lost.",
				numHits);
		}

	    Array.Sort(raycastResults, 0, numHits, hitComparer);

		RaycastHit closestRayHit = raycastResults.First();

		Vector3 projection = Vector3.Project(closestRayHit.point - ray.origin, ray.direction);
		Vector3 hitPosition = projection + ray.origin;

		result.gameObject = closestRayHit.collider.gameObject;
		result.distance = closestRayHit.distance;
		result.worldPosition = hitPosition;
		result.worldNormal = closestRayHit.normal;
		return true;
   }

   	/// Test projecting a objectToPlace into scene, and put it there
   	RaycastResult placementResult = new RaycastResult();

  	void Update() {
	   if( placementRing.activeSelf ) {
			if( sphereHitFromPointer( ref placementResult, 0.01f ) == true ) {
				placementRing.transform.position = placementResult.worldPosition;
			}
		}
   	}

	/**
	 * Primary Button interacts, placing and moving items on the ground, or picking up and throwing the ball.
	 */
	public void OnButtonEvent(BEControllerButtons current, BEControllerButtons down, BEControllerButtons up) {
		if( down == BEControllerButtons.ButtonPrimary && placementRing.activeSelf && placeObjects.Count() > 0 ) {
			GameObject objectToPlace = placeObjects.First();
			placeObjects.RemoveAt(0);
			Vector3 pos = placementRing.transform.position;
			if( pos.y < FallHeight ) {
				pos.y = FallHeight; // Fall from above the ground.
			}
			objectToPlace.transform.position = pos;
			objectToPlace.SetActive(true);

			// Reset the object's physics.
			var objectRigidBody = objectToPlace.GetComponent<Rigidbody>();
			if( objectRigidBody ) {
				objectRigidBody.velocity = Vector3.zero;
				objectRigidBody.angularVelocity = Vector3.zero;
			}

			// Clean-up if last object is placed in scene.
			if(placeObjects.Count() == 0) {
				OnPlaceHilight(false);
				foreach( var trigger in worldEventTriggers) {
					Destroy(trigger);
				}
			}
		}
	}
}
