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
#import "Utils.h"
#import "OutsideWorldComponent.h"
#import "CustomRenderMode.h"

static float const PORTAL_FRUSTUM_CROSSING_WIDTH = 0.008;

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
@property(nonatomic, strong) SCNNode *saveState;
@property(nonatomic, strong) SCNNode *prePortal;
@property(nonatomic, strong) SCNNode *postPortal;

@property(atomic) GLKVector3 oldCameraPos;
@property(atomic) float time;
@property(atomic) PortalState portalState;

@end

@implementation WindowComponent {
    GLboolean prevSTENCIL_TEST;
    GLenum prevGL_STENCIL_FAIL;
    GLenum prevGL_STENCIL_PASS_DEPTH_PASS;
    GLenum prevGL_STENCIL_PASS_DEPTH_FAIL;
    GLenum prevGL_STENCIL_FUNC;
    GLuint prevGL_STENCIL_VALUE_MASK;
    GLint prevGL_STENCIL_REF;
    GLuint prevGL_STENCIL_WRITEMASK;
}

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

    // portal starts facing towards z, rotate such that faces normal
    GLKQuaternion rotateNormal = [Utils SCNQuaternionLookRotation:normal up:GLKVector3Make(0, -1, 0)];
    rotateNormal = GLKQuaternionNormalize(rotateNormal);
    GLKQuaternion q = rotateNormal;
    self.node.orientation = SCNVector4Make(q.x, q.y, q.z, q.w);

    // bake the new position into the vertex attributes
    [self bakeWorldSpacePositionsIntoGeometry:[self
            .portalFrameNode childNodeWithName:@"polySurface1" recursively:true]];
    [self bakeWorldSpacePositionsIntoGeometry:[self
            .portalFrameNode childNodeWithName:@"window_piece" recursively:true]];

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
        // Re-target if portal was closing.
        self.time = (_portalState==PORTAL_CLOSE) ? (self.closeDuration - _time) : 0.f;

        [self setEnabled:true];

        AudioNode* node = [[AudioEngine main] playAudio:@"window_open.mp3" atVolume:1];
        node.position = self.node.position;
        self.portalState = PORTAL_OPEN;

    } else {

        self.time =
                (_portalState==PORTAL_OPEN) ? (self.openDuration - _time) : 0.f; // Re-target if portal was opening.
        AudioNode* node = [[AudioEngine main] playAudio:@"window_close.mp3" atVolume:1];
        node.position = self.node.position;
        self.portalState = PORTAL_CLOSE;
    }
}

- (float)openDuration {
    return 3;
}

- (float)closeDuration {
    return 1;
}

- (bool)isFullyClosed {
    return !_open && (_portalState==PORTAL_IDLE);
}

#pragma mark - Inner Methods

- (void)updateWithDeltaTime:(NSTimeInterval)seconds {
    [super updateWithDeltaTime:seconds];

    if (![self isEnabled]) return;

    self.time += seconds;

    if (self.portalState==PORTAL_OPEN) {
        if (self.time > self.openDuration) {
            self.portalState = PORTAL_IDLE;
        }
    }

    if (self.portalState==PORTAL_CLOSE) {
        if (self.time > self.closeDuration) {
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

    SCNVector3 to = [[Scene main].rootNode convertPosition:SCNVector3FromGLKVector3(newCameraPos) toNode:self
            .portalCrossingTransformNode];

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

    self.occlude.geometry.firstMaterial.cullMode = SCNCullFront;

    self.portalGeometryNode.geometry.firstMaterial.doubleSided = true;
    self.portalGeometryNode.categoryBitMask = RAYCAST_IGNORE_BIT;
    self.portalGeometryNode.hidden = true;
    [self.portalGeometryTransformNode addChildNode:self.portalGeometryNode];

    // Portal Plane Node is used for ray testing if camera passes through the portal.
    self.portalCrossingPlaneNode.categoryBitMask = RAYCAST_IGNORE_BIT;
    self.portalCrossingPlaneNode.geometry.firstMaterial.diffuse.contents = [UIColor clearColor];
    self.portalCrossingPlaneNode.hidden = false;
    [self.portalCrossingTransformNode addChildNode:self.portalCrossingPlaneNode];

    // Load the mesh for the window.
    GLKVector3 meshForward = GLKVector3Make(0, 0, 1); // Which direction is forward in the exported mesh.
    SCNNode *portalFrameMesh = [[SCNScene sceneNamed:@"Assets.scnassets/maya_files/window.dae"].rootNode clone];

    // Stop animation after 1 loop
    SCNNode *window_piece = [portalFrameMesh childNodeWithName:@"window_piece" recursively:true];

    CAAnimation *animation = [window_piece animationForKey:@"window_piece-Matrix-animation-transform"];
    [window_piece removeAnimationForKey:@"window_piece-Matrix-animation-transform"];

    [animation setRepeatCount:1];
    [animation setRemovedOnCompletion:false];
    [animation setFillMode:kCAFillModeForwards];
    [window_piece addAnimation:animation forKey:@"window_piece-Matrix-animation-transform"];

    portalFrameMesh.position = SCNVector3Make(0, 0, 0);

    // Make the cut plane render as part of the stencil pass.
    SCNNode *cutPlane = [portalFrameMesh childNodeWithName:@"cut_plane" recursively:true];
    [cutPlane setRenderingOrderRecursively:portalOccludeRenderOrder];

    [window_piece
            setRenderingOrderRecursively:postEnvironmentRenderOrder + 10000];

    self.portalFrameNode = portalFrameMesh;
    [self.portalGeometryTransformNode addChildNode:self.portalFrameNode];

    // Setup the special camera mapping and rendering for the frame
    SCNNode *frameNode = [portalFrameMesh childNodeWithName:@"polySurface1" recursively:true];

    // Create a new geometry for frameNode
    [self setupCameraMaterial:frameNode.geometry.firstMaterial];

    [self bakeWorldSpacePositionsIntoGeometry:[self
            .portalFrameNode childNodeWithName:@"polySurface1" recursively:true]];

    [frameNode setRenderingOrderRecursively:postEnvironmentRenderOrder + 10000];

    [self.node setCastsShadowRecursively:false];
}

- (void)start {
    [super start];

    NSLog(@"Window start");

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

    // A node that just saves some of the current GL state so we can reset it later
    self.saveState = [SCNNode node];
    [self.saveState setName:@"SaveState"];
    [self.saveState setRenderingOrder:saveStateRenderOrder];
    [self.saveState setRendererDelegate:self];
    [self.node addChildNode:self.saveState];

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

    if ([node.name isEqualToString:@"SaveState"]) {
        glGetBooleanv(GL_STENCIL_TEST, &prevSTENCIL_TEST);
        glGetIntegerv(GL_STENCIL_FAIL, (GLint*)&prevGL_STENCIL_FAIL);
        glGetIntegerv(GL_STENCIL_PASS_DEPTH_FAIL, (GLint*)&prevGL_STENCIL_PASS_DEPTH_FAIL);
        glGetIntegerv(GL_STENCIL_PASS_DEPTH_PASS, (GLint*)&prevGL_STENCIL_PASS_DEPTH_PASS);
        glGetIntegerv(GL_STENCIL_FUNC, (GLint*)&prevGL_STENCIL_FUNC);
        glGetIntegerv(GL_STENCIL_VALUE_MASK, (GLint*)&prevGL_STENCIL_VALUE_MASK);
        glGetIntegerv(GL_STENCIL_REF, &prevGL_STENCIL_REF);
        glGetIntegerv(GL_STENCIL_WRITEMASK, (GLint*)&prevGL_STENCIL_WRITEMASK);
    }

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


        // Restore previous GL state:
        if (prevSTENCIL_TEST) {
            glEnable(GL_STENCIL_TEST);
        } else {
            glDisable(GL_STENCIL_TEST);
        }

        glStencilOp(prevGL_STENCIL_FAIL, prevGL_STENCIL_PASS_DEPTH_FAIL, prevGL_STENCIL_PASS_DEPTH_PASS);
        glStencilFunc(prevGL_STENCIL_FUNC, prevGL_STENCIL_REF, prevGL_STENCIL_VALUE_MASK);
        glStencilMask(prevGL_STENCIL_WRITEMASK);
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

- (void)program:(SCNProgram *)program handleError:(NSError *)error {
    NSLog(@"ERROR: -------------------------------:");
    NSLog(@"%@", [error localizedDescription]);
}

- (void)setupCameraMaterial:(SCNMaterial *)material {
    // Setup the shader on the frame geometry object to blend it with the walls
    SCNProgram *program = [SCNProgram programWithShader:@"Shaders/SimpleCameraRender/simpleCameraRender"];
    [program setSemantic:SCNGeometrySourceSemanticColor forSymbol:@"a_color" options:nil];
    [program setSemantic:SCNViewTransform forSymbol:@"viewTransform" options:nil];
    [program setSemantic:SCNProjectionTransform forSymbol:@"projectionTransform" options:nil];
    [program setSemantic:SCNModelTransform forSymbol:@"modelTransform" options:nil];
    [program setDelegate:self];

    material.program = program;

    [material handleBindingOfSymbol:@"u_resolution" usingBlock:^(unsigned int programID,
                                                                 unsigned int location,
                                                                 SCNNode *renderedNode,
                                                                 SCNRenderer *renderer) {
        GLint vp[4];
        glGetIntegerv(GL_VIEWPORT, vp);
        glUniform2f(location, vp[2], vp[3]);
    }];

    [material handleBindingOfSymbol:@"cameraSampler" usingBlock:^(unsigned int programID,
                                                                  unsigned int location,
                                                                  SCNNode *renderedNode,
                                                                  SCNRenderer *renderer) {

        if (CUSTOM_RENDER_MODE_CAMERA_TEXTURE_NAME!=-1) {
            glActiveTexture(GL_TEXTURE7);
            glBindTexture(GL_TEXTURE_2D, CUSTOM_RENDER_MODE_CAMERA_TEXTURE_NAME);
            glUniform1i(location, GL_TEXTURE7 - GL_TEXTURE0);
        }
    }];

}

- (void)bakeWorldSpacePositionsIntoGeometry:(SCNNode *)node {
    NSArray<SCNGeometrySource *>
            *vertexSources = [node.geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticVertex];
    NSAssert([vertexSources count]==1, @"Not one vertex geometry source.");
    SCNGeometrySource *vertexSource = vertexSources[0]; // check the data offsets and things

    NSInteger stride = vertexSource.dataStride; // in bytes
    NSInteger offset = vertexSource.dataOffset; // in bytes

    NSInteger componentsPerVector = vertexSource.componentsPerVector;
    NSInteger bytesPerVector = componentsPerVector * vertexSource.bytesPerComponent;
    NSInteger vectorCount = vertexSource.vectorCount;

    SCNVector3 vertices_object[vectorCount]; // A new array for vertices

    // Read the vertex information out of the vertex data array.
    for (NSInteger i = 0; i < vectorCount; i++) {

        // Assuming that bytes per component is 4 (a float)
        // If it was 8 then it would be a double (aka CGFloat)
        float vectorData[componentsPerVector];

        // The range of bytes for this vector
        NSRange byteRange = NSMakeRange(i * stride + offset, // Start at current stride + offset
                                        bytesPerVector);   // and read the lenght of one vector

        // Read into the vector data buffer
        [vertexSource.data getBytes:&vectorData range:byteRange];

        // At this point you can read the data from the float array
        float x = vectorData[0];
        float y = vectorData[1];
        float z = vectorData[2];

        // save it as an SCNVector3 for later use ...
        vertices_object[i] = SCNVector3Make(x, y, z);
    }


    // Calculate the world positions of all of these vertices.
    SCNVector3 vertices_world[vectorCount];

    for (NSInteger i = 0; i < vectorCount; i++) {
        vertices_world[i] = [node convertPosition:vertices_object[i] toNode:nil];
    }

    NSData *colorData = [NSData dataWithBytes:vertices_world length:sizeof(vertices_world)];
    SCNGeometrySource *colorSource = [SCNGeometrySource geometrySourceWithData:colorData
                                                                      semantic:SCNGeometrySourceSemanticColor
                                                                   vectorCount:vectorCount
                                                               floatComponents:YES
                                                           componentsPerVector:3
                                                             bytesPerComponent:sizeof(float)
                                                                    dataOffset:0
                                                                    dataStride:sizeof(SCNVector3)];

//    [node.geometry geometrySources][0] = 5;
//
//    // Set the color values on all vertexes to be the positions of the current object.
//    for (NSInteger i = 0; i < vectorCount; i++) {
//
//        // Assuming that bytes per component is 4 (a float)
//        // If it was 8 then it would be a double (aka CGFloat)
//        float vectorData[componentsPerVector];
//
//        // The range of bytes for this vector
//        NSRange byteRange = NSMakeRange(i * stride + offset, // Start at current stride + offset
//                                        bytesPerVector);   // and read the lenght of one vector
//
//        // Read into the vector data buffer
//        [colorSource.data getBytes:&vectorData range:byteRange];
//
//        // At this point you can read the data from the float array
//        float x = vectorData[0];
//        float y = vectorData[1];
//        float z = vectorData[2];
//
//        // ... Maybe even save it as an SCNVector3 for later use ...
//        vertices_object[i] = SCNVector3Make(x, y, z);
//
//        // ... or just log it
//        NSLog(@"x:%f, y:%f, z:%f", x, y, z);
//    }

    NSArray *sourcesWithColor = [node.geometry.geometrySources arrayByAddingObject:colorSource];

    SCNGeometry
            *newGeometry = [SCNGeometry geometryWithSources:sourcesWithColor elements:node.geometry.geometryElements];
    newGeometry.materials = node.geometry.materials.copy;
    node.geometry = newGeometry;
}
@end
