/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "SelectableModelComponent.h"
#import "ButtonComponent.h"

#import "../Core/Core.h"
#import "../Utils/SceneKitExtensions.h"
#import "../Utils/SceneKitTools.h"

#define SELECTABLE_FADE_DURATION 0.25
#define SELECTABLE_Z_SAFETY_DISTANCE 0.3
#define SELECTABLE_TARGET_SIZE 0.3

// For now, everything is always selectable. This can be changed to "arm" targets only within, say, 2m
#define SELECTABLE_PROXIMITY MAXFLOAT

@interface SelectableModelComponent ()
@property(nonatomic) BOOL gazeActive;  // We're looking at the target.
@property(nonatomic, strong) ButtonComponent *target;
@property(nonatomic, readwrite) BOOL targetArmed;  // Target is active.
@property(nonatomic, strong) SCNNode *targetSphere;
@end

@implementation SelectableModelComponent

/**
 * Designated Initializer (Internal)
 * Initialize with a target SignController.
 */
- (instancetype) initWithMarkupName:(NSString*)markupName {
    self = [super init];
    if( self ) {
        self.markupName = markupName;
        self.fadeInScale = 1.0;

        self.node = [self createSceneNodeForGaze];

        // Create a hit target and parent it to this node.
        self.target = [[ButtonComponent alloc] initWithImage:[SceneKit pathForImageResourceNamed:@"target-white-128.png"] andBlock:nil];
        [_target.frontMaterial setTransparency:0.5*0.4];
        
        _target.node.geometry.firstMaterial.lightingModelName = SCNLightingModelConstant;
        
        [self.node addChildNode:_target.node];
        [self.node setReadsFromDepthBufferRecursively:YES];
        self.node.name = @"Target";

        self.callbackBlock = nil;
    }
    
    return self;
}

- (instancetype) initWithMarkupName:(NSString*)markupName withRadius:(float)radius {
    self = [self initWithMarkupName:markupName];
    
    if( self ) {
        self.targetSphere = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:radius]];
        _targetSphere.geometry.firstMaterial.lightingModelName = SCNLightingModelConstant;
        _targetSphere.geometry.firstMaterial.diffuse.contents = [UIColor clearColor];
        _targetSphere.geometry.firstMaterial.transparency = 0;
        _targetSphere.castsShadow = NO;
        [self.node insertChildNode:_targetSphere atIndex:0];
    }
    
    return self;
}

- (instancetype) initWithMarkupName:(NSString*)markupName withModelName:(NSString *)modelName {
    if( modelName ) {
        self = [self initWithMarkupName:markupName];
        if( self ) {
            SCNNode *model = [SCNNode firstNodeFromSceneNamed:modelName];
            if( model == nil ) {
                NSLog(@"SelectableModelComponent FAILED TO LOAD: %@", modelName);
                return nil;
            } else {
                [model setCategoryBitMaskRecursively: BEShadowCategoryBitMaskCastShadowOntoSceneKit | BEShadowCategoryBitMaskCastShadowOntoEnvironment];
                model.eulerAngles = SCNVector3Make(M_PI, 0, 0); // Counter the rotation from createSceneNodeForGaze
                [self.node insertChildNode:model atIndex:0];
            }
        }
    } else {
        self = [self initWithMarkupName:markupName withRadius: SELECTABLE_TARGET_SIZE/2];
    }

    return self;
}


- (void) setEnabled:(bool)enabled withFade:(BOOL)fade {
    if( fade ) {
        if( enabled && self.isEnabled == NO ) {
            self.node.scale = SCNVector3Make(0, 0, 0);
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:SELECTABLE_FADE_DURATION];
            self.node.scale = SCNVector3Make(_fadeInScale, _fadeInScale, _fadeInScale);
            [SCNTransaction commit];
            [super setEnabled:YES];
        } else if( enabled == NO ) {
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:SELECTABLE_FADE_DURATION];
            self.node.scale = SCNVector3Make(0, 0, 0);
            [SCNTransaction setCompletionBlock:^{
                [super setEnabled:NO];
            }];
            [SCNTransaction commit];
        }
    } else {
        [super setEnabled:enabled];
    }
}

- (void) setTargetArmed:(BOOL)armed {
    if( _targetArmed != armed ) {
        _targetArmed = armed;

        BOOL hidden = !_target.isEnabled;
        UIColor *targetColor = _targetArmed ?   [UIColor colorWithRed:0.5 green:1.0 blue:0.5 alpha:1.0] :
                                                [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] ;
        // tints the final output of shading
        [_target.frontMaterial.multiply setContents:targetColor];
        
        //_target.node.categoryBitMask |= RAYCAST_IGNORE_BIT;
        _target.node.hidden = hidden;
        
    }
}

- (void) setCallbackBlock:(callback)callbackBlock {
    if( _callbackBlock != callbackBlock) {
        _callbackBlock = callbackBlock;
        
        if( _callbackBlock != nil ) {
            // Make the target sphere hittable.
            self.targetSphere.hidden = NO;
            [self.target setEnabled:YES];
        } else {
            // Make the target sphere go away.
            self.targetSphere.hidden = YES;
            [self.target setEnabled:NO];
        }
    }
}

- (void) updateTarget {
    if( [[SceneManager main] isStereo] ) {
        // Use the Gaze to arm the target.
        self.targetArmed = self.gazeActive && [self groundDistanceToCamera] < SELECTABLE_PROXIMITY;
    } else {
        // Mono, just use distance to target.
        self.targetArmed = [self groundDistanceToCamera] < SELECTABLE_PROXIMITY;
    }
    
    // Match camera orientation.
    GLKVector3 npos = SCNVector3ToGLKVector3([SceneKitTools getWorldPos:self.node]);
    GLKVector3 cpos = [Camera main].position;
    GLKVector3 yaxis = [[Camera main] up];
    GLKVector3 zaxis = GLKVector3Normalize(GLKVector3Subtract(npos,cpos));
    GLKVector3 xaxis = GLKVector3CrossProduct(zaxis,yaxis);

    // Put the matrix back together again.
    GLKMatrix4 lookAtCameraMatrix = GLKMatrix4MakeWithColumns(
    GLKVector4MakeWithVector3(xaxis, 0),
    GLKVector4MakeWithVector3(yaxis, 0),
    GLKVector4MakeWithVector3(zaxis, 0),
    GLKVector4Make(0,0,0,1));
    
    SCNMatrix4 scnLookAtMatrix = SCNMatrix4FromGLKMatrix4(lookAtCameraMatrix);
    SCNMatrix4 signMatrix = [self.node convertTransform:scnLookAtMatrix fromNode:nil];
    signMatrix = SCNMatrix4Scale(signMatrix, 0.3, 0.3, 0.3);
    self.target.node.transform = signMatrix;
    GLKVector3 offset = GLKVector3Add(npos, GLKVector3MultiplyScalar(zaxis,-SELECTABLE_Z_SAFETY_DISTANCE));
    self.target.node.position = [self.node convertPosition:SCNVector3FromGLKVector3(offset) fromNode:nil];
}

/**
 * Calculate the ground distance to camera on X/Z plane.
 */
- (float) groundDistanceToCamera {
    SCNVector3 nodePos = [self.node convertPosition:SCNVector3Zero toNode:[Scene main].rootNode];
    GLKVector3 pos = SCNVector3ToGLKVector3(nodePos);
    GLKVector3 cameraPos = [Camera main].position;
    pos.y = 0;
    cameraPos.y = 0;
    float distance = GLKVector3Distance(pos, cameraPos);
    return distance;
}

// FIXME: This did not work well... Transparency mucks up too much at render time.
//- (void) setTransparency:(float)transparency ofNode:(SCNNode*)aNode {
//    for( SCNMaterial *material in aNode.geometry.materials ) {
//        material.transparency = transparency;
//    }
//    
//    for( SCNNode *child in aNode.childNodes ) {
//        [self setTransparency:transparency ofNode:child];
//    }
//}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    [super updateWithDeltaTime:seconds];
    [self updateTarget];
}

#pragma mark - EventComponentProtocol


- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    if( self.callbackBlock && self.targetArmed ) {
        return YES;
    }
    return NO;
}

- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    if( self.callbackBlock ) {
        if( self.targetArmed ) {
            self.callbackBlock();
        } else if( self.callbackNotArmed ) {
            self.callbackNotArmed();
        }
        return YES;
    }
    
    return NO;
}

- (bool) touchCancelledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

#pragma mark - GazePointerProtocol

- (void) setGazeActive:(BOOL)gazeActive {
    if( _gazeActive != gazeActive ) {
        _gazeActive = gazeActive;
    }
}

- (void) gazeStart:(GazeComponent *)gazeComponent intersection:(SCNHitTestResult *)intersection {
//    NSLog(@"SelectableModelComponent - Gaze entered: %@", self.markupName);

    self.gazeActive = YES;
    [self updateTarget];
}

- (void) gazeStay:(GazeComponent *)gazeComponent intersection:(SCNHitTestResult *)intersection {
}

- (void) gazeExit:(GazeComponent *)gazeComponent {
//    NSLog(@"SelectableModelComponent - Gaze exited: %@", self.markupName);

    self.gazeActive = NO;
    [self updateTarget];
}

- (SCNNode*) findNodeChildNamed:(NSString*)name {
    return [self.node childNodeWithName:name recursively:YES];
}

@end
