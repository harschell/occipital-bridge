/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// How the node hierarchy works:
// self.node - base node, that can be placed and scaled to expand the open portal
// self.node.portalFrameNode - outer portal geometry
//       - portalFrameNode needs to be visible and lit.
// self.node.portalGeometryTransformNode - The special rendering stack base node. Offset and rotated into place.
// self.node.portalGeometryTransformNode.portalNode - Portal hole geometry which gets cloned
// self.node.portalGeometryTransformNode.occlude - clone of portalNode - Renders the depth occlusion
// self.node.portalGeometryTransformNode.stencil - clone of portalNode - Renders the stencil mask for keeping pixels in view
// self.node.portalCrossingTransformNode.portalCrossingPlaneNode - Flat intersection testing node, for determining camera movement passing between MR and VR.
//
// Rendering order


#import "WindowComponent.h"
#import "AudioEngine.h"
#import "SceneKitExtensions.h"
#import "OpenBE/Utils/Math.h"
#import "Utils.h"
#import "OutsideWorldComponent.h"

static float const PORTAL_FRUSTUM_CROSSING_WIDTH = 0.03;

static float const PORTAL_CIRCLE_RADIUS = .4;
static float const PORTAL_WIDTH = 1.0;
static float const PORTAL_HEIGHT = 1.8;

typedef NS_ENUM (NSUInteger, PortalState) {
    PORTAL_IDLE,
    PORTAL_OPEN,
    PORTAL_CLOSE
};

@interface WindowComponent ()

@property(nonatomic, readwrite) BOOL open;

@property(nonatomic, strong) SCNNode *portalGeometryNode;
@property(nonatomic, strong) SCNNode *portalCrossingPlaneNode;

// Transform nodes hold the geometry, with identity transform.
@property(nonatomic, strong) SCNNode *portalGeometryTransformNode;
@property(nonatomic, strong) SCNNode *portalCrossingTransformNode;

@property(nonatomic, strong) SCNNode *portalFrameNode;

// Contains the geometry that represents the plane of the window. This is the geometry that cuts into other meshes.
@property(nonatomic, strong) SCNNode *occlude;

// OpenGL Renderer shim nodes
@property(nonatomic, strong) SCNNode *preEnvironment;
@property(nonatomic, strong) SCNNode *postEnvironment;
@property(nonatomic, strong) SCNNode *prePortal;
@property(nonatomic, strong) SCNNode *postPortal;

@property(atomic) GLKVector3 oldCameraPos;
@property(atomic) float time;
@property(atomic) PortalState portalState;

@property(nonatomic, strong) AudioNode *audioWarpIn;
@property(nonatomic, strong) AudioNode *audioWarpOut;

@end

@implementation WindowComponent

- (void)setEnabled:(bool)enabled {
    [super setEnabled:enabled];

    // Hide/show the actual portal base and frame.
    self.portalGeometryTransformNode.hidden = !enabled;
    self.portalFrameNode.hidden = !enabled;

    // Hide/show all the render stage nodes.
    self.preEnvironment.hidden = !enabled;
    self.postEnvironment.hidden = !enabled;
    self.prePortal.hidden = !enabled;
    self.postPortal.hidden = !enabled;

    self.oldCameraPos = [Camera main].position;
    self.portalState = PORTAL_IDLE;
}

/**
 * NOTE: Won't open the portal if we're not isFullyClosed.
 * Open a circular portal on the wall.
 * Use the hit location (position) against a wall, rotate and offset the opening to lay against the wall.
 */
- (bool)openPortalOnWallPosition:(SCNVector3)position wallNormal:(GLKVector3)normal toVRWorld:(OutsideWorldComponent *)vrWorld {
    if (![self isFullyClosed]) return false; // Abort opening the portal.
    normal = GLKVector3Normalize(normal);
    
    [self regenerateGeometry];

    GLKVector3 hitPos = SCNVector3ToGLKVector3(position);

    // offset from the wall a bit
    GLKVector3 portalPos =
            GLKVector3Add(hitPos, GLKVector3MultiplyScalar(normal, PORTAL_FRUSTUM_CROSSING_WIDTH));

    // position portal node
    self.node.position = SCNVector3FromGLKVector3(portalPos);

    // portal starts facing upwards, rotate such that faces normal
    const GLKVector3 up = GLKVector3Make(0, 1, 0);
    auto rotationAxis = GLKVector3CrossProduct(up, normal);
    auto rotationAmount = (float) acos(GLKVector3DotProduct(normal, up));
    auto q = GLKQuaternionMakeWithAngleAndVector3Axis(rotationAmount, rotationAxis);
    q = [Utils SCNQuaternionMakeFromRotation:up to:normal];
    self.node.orientation = SCNVector4Make(q.x, q.y, q.z, q.w);


    //self.node.rotation = SCNVector4Make(rotationAxis.x, rotationAxis.y, rotationAxis.z, rotationAmount);
    // Align the VR world to match our portal.
    [vrWorld alignVRWorldToNode:self.node];
    [self setOpen:true];
    return true;
}

/**
 * NOTE: Won't open the portal if we're not isFullyClosed.
 * Open the portal on the floor.
 * Sets the position (anchored to the floor) and rotate the opening on the y-axis.
 */
- (bool)openPortalOnFloorPosition:(SCNVector3)position facingTarget:(SCNVector3)target toVRWorld:(OutsideWorldComponent *)vrWorld {
    if (![self isFullyClosed]) return false; // Abort opening the portal.

    [self regenerateGeometry];

    position.y = 0; // Anchor to ground.
    self.node.position = position;

    // rotate portal towards target (on ground)
    target.y = 0;
    GLKVector3 forward = GLKVector3Subtract(SCNVector3ToGLKVector3(position), SCNVector3ToGLKVector3(target));
    float yRot = atan2f(forward.x, forward.z);
    self.node.rotation = SCNVector4Make(0, 1, 0, yRot);

    // Align the VR world to match our portal.
    [vrWorld alignVRWorldToNode:self.node];
    [self setOpen:true];
    return true;
}

/**
 * Begin closing the portal.
 */
- (void)closePortal {
    self.open = false;
}
/**
 * internal: open property
 */
- (void)setOpen:(BOOL)open {
    if (_open==open) return;

    _open = open;

    if (_open) {
        self.time = (_portalState==PORTAL_CLOSE) ? (_audioWarpOut.duration - _time) :
                0.f; // Re-target if portal was closing.
        [self setEnabled:true];
        float open = smoothstepf(0, 1, self.time / _audioWarpIn.duration);
        self.node.scale = SCNVector3Make(open, open, open);

        _audioWarpIn.position = self.node.position;
        [_audioWarpIn play];
        self.portalState = PORTAL_OPEN;

    } else {

        self.time =
                (_portalState==PORTAL_OPEN) ? (_audioWarpIn.duration - _time) : 0.f; // Re-target if portal was opening.
        _audioWarpOut.position = self.node.position;
        [_audioWarpOut play];
        self.portalState = PORTAL_CLOSE;
    }
}

- (float)openDuration {
    return _audioWarpIn.duration;
}

- (float)closeDuration {
    return _audioWarpOut.duration;
}

- (BOOL)isFullyClosed {
    return !_open && (_portalState==PORTAL_IDLE);
}

#pragma mark - Inner Methods

- (void)updateWithDeltaTime:(NSTimeInterval)seconds {
    [super updateWithDeltaTime:seconds];

    if (![self isEnabled]) return;

    self.time += seconds;

    if (self.portalState==PORTAL_OPEN) {
        float open = smoothstepf(0, 1, self.time / _audioWarpIn.duration);
        if (self.time > _audioWarpIn.duration) {
            open = 1;
        }

        self.node.scale = SCNVector3Make(open, open, open);

        if (self.time > _audioWarpIn.duration) {
            self.portalState = PORTAL_IDLE;
        }
    }

    if (self.portalState==PORTAL_CLOSE) {
        float open = smoothstepf(1, 0, self.time / _audioWarpOut.duration);
        if (self.time > _audioWarpOut.duration) {
            open = 0;
        }

        self.node.scale = SCNVector3Make(open, open, open);

        if (self.time > _audioWarpOut.duration) {
            self.portalState = PORTAL_IDLE;
            [self setEnabled:false];
            return;
        }
    }

    GLKVector3 newCameraPos = [Camera main].position;

    // check if you have entered the portal
    SCNVector3 from = [[Scene main].rootNode convertPosition:SCNVector3FromGLKVector3(self.oldCameraPos) toNode:self
            .portalCrossingTransformNode];
    GLKVector3 forward = GLKVector3Subtract(newCameraPos, self.oldCameraPos);
    forward = GLKVector3Normalize(forward);
    forward = GLKVector3Add(self.oldCameraPos, forward);

    SCNVector3 to = [[Scene main].rootNode convertPosition:SCNVector3FromGLKVector3(newCameraPos) toNode:self
            .portalCrossingTransformNode];

    NSArray<SCNHitTestResult *> *hitTestResults =
            [self.portalCrossingTransformNode hitTestWithSegmentFromPoint:from toPoint:to options:nil];

    self.oldCameraPos = newCameraPos;

    [SCNTransaction begin];
    [SCNTransaction disableActions];
    [SCNTransaction setAnimationDuration:0];

    // Check which side of portalPlaneNode you're on,
    //  position portal geometry away from the camera so it hops over when crossing the Z boundary.
    // NOTE: we need a tight zNear on the camera to make this work well.
    float backsideFlip = to.z < 0 ? 1 : -1;
    float zoffset = backsideFlip * PORTAL_FRUSTUM_CROSSING_WIDTH;
    _portalGeometryTransformNode.position = SCNVector3Make(0, 0, zoffset);

    [SCNTransaction commit];
}

#pragma mark - Component Methods

- (void)regenerateGeometry {
    [self.portalGeometryNode removeFromParentNode];
    self.portalGeometryNode = nil;

    [self.portalCrossingPlaneNode removeFromParentNode];
    self.portalCrossingPlaneNode = nil;

    [self.portalFrameNode removeFromParentNode];
    self.portalFrameNode = nil;

    // Setup the geometry for the portal rendering geometry
    self.portalGeometryNode =
            [SCNNode nodeWithGeometry:[SCNCylinder cylinderWithRadius:.1 height:0.001]];
    self.portalCrossingPlaneNode =
            [SCNNode nodeWithGeometry:[SCNCylinder cylinderWithRadius:PORTAL_CIRCLE_RADIUS height:0.0]];
    self.portalGeometryNode.rotation = SCNVector4Make(1, 0, 0, 0);
    self.portalCrossingPlaneNode.transform = self.portalGeometryNode.transform;

    // Re-make the occlude node.
    [_occlude removeFromParentNode];

    // Clone the portalNode into an occlusion and depth copy.
    // NOTE: Attach the PortalGeometryNode after it's been cloned, or flattenedClone will inherit the _node.scale
    _occlude = [self.portalGeometryNode flattenedClone];
    _occlude.transform = self.portalGeometryNode.transform;
    [_occlude setRenderingOrderRecursively:portalOccludeRenderOrder];
    [self.portalGeometryTransformNode addChildNode:_occlude];

//    self.occlude.geometry.firstMaterial.cullMode = SCNCullFront;

    self.portalGeometryNode.geometry.firstMaterial.doubleSided = true;
    self.portalGeometryNode.categoryBitMask = RAYCAST_IGNORE_BIT;
    self.portalGeometryNode.hidden = true;
    [self.portalGeometryTransformNode addChildNode:self.portalGeometryNode];

    // Portal Plane Node is used for ray testing if camera passes through the portal.
    self.portalCrossingPlaneNode.categoryBitMask = RAYCAST_IGNORE_BIT;
    self.portalCrossingPlaneNode.geometry.firstMaterial.diffuse.contents = [UIColor clearColor];
    self.portalCrossingPlaneNode.hidden = false;
    [self.portalCrossingTransformNode addChildNode:self.portalCrossingPlaneNode];

    // Rounded Frame
    // Testing a new portal mesh
    GLKVector3 meshForward = GLKVector3Make(0, 0, 1); // Which direction is forward in the exported mesh.
    SCNNode *portalFrameMesh = [[SCNScene sceneNamed:@"Assets.scnassets/maya_files/window.dae"].rootNode clone];
//    SCNNode *portalFrameMesh = [_portalGeometryNode clone];
    portalFrameMesh.position = SCNVector3Make(0,0,0);
    GLKQuaternion q = [Utils SCNQuaternionMakeFromRotation:meshForward to:GLKVector3Make(0, 1, 0)];
    portalFrameMesh.orientation = SCNVector4Make(q.x, q.y, q.z, q.w);

    SCNNode *cutPlane = [portalFrameMesh childNodeWithName:@"cut_plane" recursively:true];
//    [cutPlane removeFromParentNode];
//    cutPlane.orientation = SCNVector4Make(q.x, q.y, q.z, q.w);
//    [self.occlude addChildNode: cutPlane];
    [cutPlane setRenderingOrderRecursively:portalOccludeRenderOrder];

    self.portalFrameNode = portalFrameMesh;

//    self.portalFrameNode = [[SCNScene sceneNamed:@"Assets.scnassets/maya_files/window_frame.dae"]
//            .rootNode clone];
//    [self.portalFrameNode.geometry.firstMaterial
//            .diffuse setContents:[UIColor colorWithRed:0.678f green:0.678f blue:0.678f alpha:1]];
//    self.portalFrameNode.transform = self.portalGeometryNode.transform;
//    self.portalFrameNode.scale = SCNVector3Make(PORTAL_CIRCLE_RADIUS, PORTAL_CIRCLE_RADIUS, PORTAL_CIRCLE_RADIUS);

    [self.portalGeometryTransformNode addChildNode:self.portalFrameNode];

    [self.node setCastsShadowRecursively:false];
}

- (void)start {
    [super start];

    self.audioWarpIn = [[AudioEngine main] loadAudioNamed:@"Robot_WarpIn.caf"];
    self.audioWarpOut = [[AudioEngine main] loadAudioNamed:@"Robot_WarpOut.caf"];

    self.open = false;

    self.node = [SCNNode node];
    self.node.name = @"PortalNode";
    [[Scene main].rootNode addChildNode:self.node];

    self.portalGeometryTransformNode = [SCNNode node];
    self.portalGeometryTransformNode.name = @"portalGeometryTransform";
    [self.node addChildNode:self.portalGeometryTransformNode];

    self.portalCrossingTransformNode = [SCNNode node];
    self.portalCrossingTransformNode.name = @"portalCrossingTransform";
    [self.node addChildNode:self.portalCrossingTransformNode];

    // Enable rendering to the stencil buffer for portal rendering.
    self.prePortal = [SCNNode node];
    [self.prePortal setName:@"PrePortal"];
    [self.prePortal setRenderingOrder:prePortalRenderOrder];
    [self.prePortal setRendererDelegate:self];
    [self.node addChildNode:self.prePortal];

    // Render _occlude node
    // Write the stencil of the portal, masking the areas that the world can render into.

    // Set Stencil Test Func
    self.postPortal = [SCNNode node];
    [self.postPortal setName:@"PostPortal"];
    [self.postPortal setRenderingOrder:postPortalRenderOrder];
    [self.postPortal setRendererDelegate:self];
    [self.node addChildNode:self.postPortal];

    // Change the environment opengl rendering state to use skip rendering where portals have rendered to the stencil
    // buffer
    self.preEnvironment = [SCNNode node];
    [self.preEnvironment setName:@"PreEnvironment"];
    [self.preEnvironment setRenderingOrder:preEnvironmentRenderOrder];
    [self.preEnvironment setRendererDelegate:self];
    [self.node addChildNode:self.preEnvironment];

    // Reset the rendering state after rendering the environment.
    self.preEnvironment = [SCNNode node];
    [self.preEnvironment setName:@"PostEnvironment"];
    [self.preEnvironment setRenderingOrder:postEnvironmentRenderOrder];
    [self.preEnvironment setRendererDelegate:self];
    [self.node addChildNode:self.preEnvironment];


    self.time = 0;
    self.portalState = PORTAL_IDLE;
    self.oldCameraPos = [Camera main].position;
}

#pragma mark - SceneKit Node Renderer Methods

// invoked by SceneKit just before portal will be rendered
- (void)renderNode:(SCNNode *)node
          renderer:(SCNRenderer *)renderer
         arguments:(NSDictionary *)arguments {
    NSString *passName = arguments[@"kRenderPassName"];

    // don't render in the light pass, or any other pass
    // note in stereo this gets called twice with pass names sceneLeft and sceneRight
    if ([passName isEqualToString:@"SceneKit_renderSceneFromLight"])
        return;


    if ([node.name isEqualToString:@"PrePortal"]) {
        glEnable(GL_STENCIL_TEST);
        glStencilFunc(GL_ALWAYS, PORTAL_STENCIL_VALUE, 0xFF);
        glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);

        // only write to stencil, not depth or color
        glStencilMask(0xFF);
        glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
        glDepthMask(GL_FALSE);
    }

    // portal renders here -- stencil buffer contains all portal pixels

    if ([node.name isEqualToString:@"PostPortal"]) {
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        glDepthMask(GL_TRUE);
        glStencilMask(0x0);
//        glDisable(GL_STENCIL_TEST);
    }

    if ([node.name isEqualToString:@"PreEnvironment"]) {
        glEnable(GL_STENCIL_TEST);

        // only draw where the stencil != PORTAL_STENCIL_VALUE
        glStencilFunc(GL_NOTEQUAL, PORTAL_STENCIL_VALUE, 0xFF);
    }

    // the environment mesh renders here

    if ([node.name isEqualToString:@"PostEnvironment"]) {
        glDisable(GL_STENCIL_TEST);
    }
}

- (bool)touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *)hit { return true; };
- (bool)touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *)hit { return true; };
- (bool)touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *)hit { return true; };
- (bool)touchCancelledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *)hit { return true; };

@end
