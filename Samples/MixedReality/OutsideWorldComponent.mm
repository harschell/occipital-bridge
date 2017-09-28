/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

//  Turning on the lights and opening the bay doors is done in stages:
//
//  1) Turn on the lights when we enter VR mode.
//  2) Wait a brief lightEnabledDelay
//  3) Count up to our number of lights to turn on:
//     turn on a light
//     waiting brief lightCooldownPeriod
//     turn on the next light
//
//  4) Open the bay doors only if we're still in the VR mode. 
//  5) Wait a brief openBayDoorsDelay
//  6) Open the bay door hinges.

#import "Foundation/Foundation.h"
#import "OutsideWorldComponent.h"
#import "SceneKitExtensions.h"

#define VR_LIGHTS_MAX 3
#define VR_LIGHT_COOLDOWN_PERIOD 1
#define VR_LIGHTS_ENABLED_DELAY 1

#define VR_OPEN_BAY_DOORS_DELAY 3
#define VR_OPEN_BAY_DOORS_INTERVAL 4

#define VR_LIGHT_LEVEL_INSIDE 0.7f
#define VR_LIGHT_LEVEL_OUTSIDE .01f
#define VR_LIGHT_LEVEL_SPEED 2.f

unsigned int const LIGHTING_BITMASK = 0x01000000;

@interface OutsideWorldComponent ()

@property(nonatomic, strong) SCNNode *alignmentNode; // handles alignment to the windows
@property(nonatomic, strong) SCNNode *animationNode; // handles animating the world left / right
@property(nonatomic, strong) SCNNode *geometryNode; // holds the actual mountains geometry
@property(nonatomic) double accumulatedTime;
@property(nonatomic) bool aligned; // if the outside world is aligned to a window.

@end

@implementation OutsideWorldComponent
- (id) init {
    self.alignmentNode = [[SCNNode alloc] init];
    self.alignmentNode.name = @"VR World";

    self.animationNode = [[SCNNode alloc] init];
    self.animationNode.name = @"Animation Translation";

    return self;
}

- (void)setEnabled:(bool)enabled {
    [super setEnabled:enabled];

    //todo
    self.alignmentNode.hidden = false;//!enabled;
}

- (void)start {
    [super start];

    // Give a 1cm offset, so we don't get co-planar z-fighting between VR world and real world floor.
    self.alignmentNode.position = SCNVector3Make(0, .01, 0);

    // Create note for the translational animation
    [self.alignmentNode addChildNode:self.animationNode];

    // Create the actual geometry of the world
    auto mountainsScene = [SCNScene sceneNamed:@"Assets.scnassets/maya_files/mountains5.scn"];
    self.geometryNode = [mountainsScene.rootNode clone];
    [[Scene main] scene].fogColor = mountainsScene.fogColor;
    [[Scene main] scene].fogEndDistance = mountainsScene.fogEndDistance;
    [[Scene main] scene].fogStartDistance = mountainsScene.fogStartDistance;
    [[Scene main] scene].fogDensityExponent = mountainsScene.fogDensityExponent;
    self.geometryNode.name = @"GeometryNode";
    self.geometryNode.rotation = SCNVector4Make(1, 0, 0, (float) M_PI);
    NSAssert(self.geometryNode!=nil, @"Could not load the scene");

    [self.animationNode addChildNode:self.geometryNode];

    [self.alignmentNode setRenderingOrderRecursively:VR_WORLD_RENDERING_ORDER];
    [self.alignmentNode setCastsShadowRecursively:NO];

    [[Scene main].rootNode addChildNode:self.alignmentNode];

    // Start off the rooms hidden.
    self.geometryNode.hidden = false;
    self.alignmentNode.hidden = false;
}

- (void)alignVRWorldToNode:(SCNNode *)targetNode {
    if (self.aligned) {return;}

    SCNVector3 targetPos = targetNode.position;
    targetPos.y = 0.0; // Remove the y-offset from the target node, and align to its x/z position only.
    self.alignmentNode.position = targetPos;

    SCNVector3 angles = targetNode.eulerAngles;
    angles.z = 0;
    angles.x = 0;
    angles.y -= M_PI_2;
    self.alignmentNode.eulerAngles = angles;

    // Start movement animation
    CABasicAnimation *movementAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    movementAnimation.toValue = [NSValue valueWithSCNVector3:SCNVector3Make(-7, 0, 0)];
    movementAnimation.fromValue = [NSValue valueWithSCNVector3:SCNVector3Make(21, 0, 0)];
    movementAnimation.repeatCount = FLT_MAX;
    movementAnimation.duration = 60;
    movementAnimation.autoreverses = true;
    [self.animationNode addAnimation:movementAnimation forKey:nil];

    self.aligned = true;
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds {
    [super updateWithDeltaTime:seconds];

    self.accumulatedTime += seconds;

    float scale = (((float) sin(CACurrentMediaTime()) + 1) / 2) * 0.05F;
//    self.node.scale = SCNVector3Make(scale, scale, scale);

//    [[Camera main] camera].zFar = 101;
//    [[[[Scene main].scene rootNode] childNodeWithName:@"RightEye" recursively:true] camera].zFar = 100;
//    [[[[Scene main].scene rootNode] childNodeWithName:@"LeftEye" recursively:true] camera].zFar = 100;


    // TODO: re-enable gray fade out
//    float grayness = 1.0 - 2.0 * _windowComponent.mixedReality.lastTrackerHints.modelVisibilityPercentage;
//    if (isnan(grayness))
//        grayness = 1.0;
//
//    grayness = fmaxf(fminf(grayness, 1.0), 0.0);
//
//    [self.node enumerateChildNodesUsingBlock:^(SCNNode *_Nonnull child, BOOL *_Nonnull stop) {
//        for (SCNMaterial *material in child.geometry.materials) {
//            [material setValue:@(grayness) forKeyPath:@"grayAmount"];
//        };
//    }];
}

@end
