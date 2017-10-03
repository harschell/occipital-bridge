using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

using BEDummyGoogleVR;
namespace BEDummyGoogleVR {}

[RequireComponent(typeof(Rigidbody))]
[RequireComponent(typeof(Collider))]
public class BEMovableHandler : MonoBehaviour {
	public GameObject hightlightObject;
    public GameObject grabLocation;

    // Grab Handling properties
    bool _grabbing = false;

    GameObject grabAnchor;
    Joint grabJointToAnchor;
    float grabDistance;
    
    Vector2 lastTouchLocation;

	// Use this for initialization
	void Start () {
        var beUnity = BridgeEngineUnity.main;
        beUnity.onControllerButtonEvent.AddListener(OnButtonEvent);
        beUnity.onControllerTouchEvent.AddListener(OnTouchEvent);
        // Debug.Assert(grabLocation, "Requires a grabLocation");

        if( hightlightObject == null ) {
            hightlightObject = new GameObject();
            hightlightObject.transform.SetParent(transform, false);
        }
        
        if( grabLocation == null ) {
            grabLocation = this.gameObject;
        }

        Collider grabCollider = grabLocation.GetComponent<Collider>();
        if( grabCollider == null ) {
            SphereCollider sphereCollider = grabLocation.AddComponent<SphereCollider>();
            sphereCollider.radius = 0.1f;
            grabCollider = sphereCollider;
        }

        // Create an eventTrigger component (or get it)
		EventTrigger eventTrigger = GetComponent<EventTrigger>() ?? gameObject.AddComponent<EventTrigger>();

        EventTrigger.Entry entryEnter = new EventTrigger.Entry();
        entryEnter.eventID = EventTriggerType.PointerEnter;
        entryEnter.callback.AddListener((data) => { OnHighlight(true); });
        eventTrigger.triggers.Add(entryEnter);

        EventTrigger.Entry entryExit = new EventTrigger.Entry();
        entryExit.eventID = EventTriggerType.PointerExit;
        entryExit.callback.AddListener((data) => { OnHighlight(false); });
        eventTrigger.triggers.Add(entryExit);

        OnHighlight(false);
	}
	
	public void OnHighlight(bool showHighlight ) {
		hightlightObject.SetActive(showHighlight);
	}

    
    // Track relative motion when grabbing.
    void Update() {
        if( grabbing ) {
            grabAnchor.transform.position = projectedGrabPositionFromPointer();
        }
    }

    /// Utility to find where gaze is intersecting the object.
    Vector3 projectedGrabPositionFromPointer() {
        var pointer = GvrPointerInputModule.Pointer;
        return pointer.PointerTransform.position + (pointer.PointerTransform.forward * grabDistance);
    }

    /**
     * Pickup/grab this object
     */
    public void OnButtonEvent(BEControllerButtons current, BEControllerButtons down, BEControllerButtons up) {
        if( (down & BEControllerButtons.ButtonPrimary) > 0 ) {
            if( hightlightObject.activeSelf ) {
                grabbing = true;
            }
        }
 
        if( grabbing && (current & BEControllerButtons.ButtonPrimary) == 0 ) {
            grabbing = false;
        }
    }

    bool grabbing {
        set {
            if( _grabbing == value ) return;

            _grabbing = value;
            if( _grabbing ) {
                var pointer = GvrPointerInputModule.Pointer;
                grabDistance = (grabLocation.transform.position - pointer.PointerTransform.position).magnitude;
                // Debug.Log("Grab Distance: " + grabDistance.ToString());
            
                // Connect the spring anchor to the projected grab location
                grabAnchor = GameObject.CreatePrimitive(PrimitiveType.Sphere);// new GameObject();
                grabAnchor.transform.localScale = Vector3.one * 0.1f;
                grabAnchor.name = "@BEMovableHandler grabAnchor";
                var anchorRB = grabAnchor.AddComponent<Rigidbody>();
                anchorRB.isKinematic = true;
                grabAnchor.transform.position = grabLocation.transform.position;

                FixedJoint joint = (FixedJoint)grabJointToAnchor;

                if( joint == null ) {
                    joint = gameObject.AddComponent<FixedJoint>();
                    grabJointToAnchor = joint;
                }
                // grabSpringToAnchor.autoConfigureConnectedAnchor = false;
                joint.connectedBody = anchorRB;
                joint.anchor = transform.InverseTransformVector(grabLocation.transform.position);
                joint.axis = new Vector3(0,1,0);
            } else {
                SpringJoint.Destroy(grabJointToAnchor);
                grabJointToAnchor = null;
                GameObject.Destroy(grabAnchor);
                grabAnchor = null;
            }
        }

        get { return _grabbing; }
    }


    /**
	 * Touch events for either:
	 *  - rotating movable objects around their Y axis
	 *  - imparting rotational motion on pickup-able objects (like a ball)
	 */
	public void OnTouchEvent( Vector2 touchLocation, BEControllerTouchStatus touchStatus ) {
		Vector2 touchMovement;
		if( touchStatus == BEControllerTouchStatus.TouchMove ) {
			touchMovement = touchLocation - lastTouchLocation;

            if( grabbing ) {
                grabDistance += touchMovement.y;
                grabDistance = Mathf.Max( 0.3f, grabDistance ); // Clamp to minimum distance
            } else {
                bool highlight = hightlightObject.activeSelf;
                if( highlight ) {
                    Vector3 euler = transform.localEulerAngles;
                    euler.y -= touchMovement.x * 180;
                    transform.localEulerAngles = euler;
                }
            }
		}

		lastTouchLocation = touchLocation;
	}
}
