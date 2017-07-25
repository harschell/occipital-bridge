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

@property(nonatomic, strong) SCNNode *node;
@property(nonatomic, strong) SCNNode *geometryNode;
@property(nonatomic) double accumulatedTime;

@end

@implementation OutsideWorldComponent
- (void)setEnabled:(bool)enabled {
    [super setEnabled:enabled];

    //todo
    self.node.hidden = false;//!enabled;
}

- (void)start {
    [super start];

    self.node = [[SCNNode alloc] init];
    self.node.name = @"VR World";

    // Give a 1cm offset, so we don't get co-planar z-fighting between VR world and real world floor.
    self.node.position = SCNVector3Make(0, .01, 0);

    // ------ Robot Room ----
//    self.geometryNode = [[SCNScene sceneNamed:@"Assets.scnassets/sky.dae"]
//            .rootNode childNodeWithName:@"Sky" recursively:true];
    self.geometryNode = [[SCNScene sceneNamed:@"Assets.scnassets/mountains_scene_full.dae"]
            .rootNode childNodeWithName:@"Scene" recursively:true];
    self.geometryNode.name = @"GeometryNode";

    self.geometryNode.rotation = SCNVector4Make(1, 0, 0, (float) M_PI);
    //self.geometryNode.scale = SCNVector3Make(.02, .02, .02);

    SCNNode *materialnode = [[SCNScene sceneNamed:@"Assets.scnassets/sky.dae"]
            .rootNode childNodeWithName:@"Sky" recursively:true];

    //self.geometryNode.geometry.firstMaterial = materialnode.geometry.firstMaterial;

    [self.node addChildNode:self.geometryNode];
    NSAssert(self.node!=nil, @"Could not load the scene");

    /*SCNNode *cnode = [self.geometryNode childNodeWithName:@"mountains" recursively:true];
    NSAssert(cnode != nil, @"Could not find child node");
    cnode.hidden = true;
    [self.geometryNode setCategoryBitMaskRecursively:LIGHTING_BITMASK];

    SCNNode *lightNode = [self.geometryNode childNodeWithName:@"directional_x0020_light" recursively:true].childNodes[0];
    lightNode.light.categoryBitMask = LIGHTING_BITMASK;
    NSAssert(lightNode != nil, @"Could not find child node");

    cnode = [self.geometryNode childNodeWithName:@"ambient" recursively:true];
    NSAssert(cnode != nil, @"Could not find child node");
    cnode.hidden = true;*/

    [self.node setRenderingOrderRecursively:VR_WORLD_RENDERING_ORDER];
    [self.node setCastsShadowRecursively:NO];

    [[Scene main].rootNode addChildNode:self.node];


    // this is for greying out the VR world as tracking feedback
//    [self.node enumerateChildNodesUsingBlock:^(SCNNode *_Nonnull child, BOOL *_Nonnull stop) {
//        for (SCNMaterial *material in child.geometry.materials) {
//            material.shaderModifiers = @{SCNShaderModifierEntryPointFragment:
//                    @"uniform float grayAmount;\n"
//                            "#pragma body\n"
//                            "vec3 grayColor = vec3(dot(_output.color.rgb, vec3(0.2989, 0.5870, 0.1140)));\n"
//                            "_output.color.rgb = (1.0 - grayAmount) * _output.color.rgb + grayAmount * grayColor;\n "};
//        };
//    }];

    // Start off the rooms hidden.
    self.geometryNode.hidden = false;
    self.node.hidden = false;
}

- (void)alignVRWorldToNode:(SCNNode *)targetNode {
    SCNVector3 targetPos = targetNode.position;
    targetPos.y = 0.0; // Remove the y-offset from the target node, and align to its x/z position only.
    self.node.position = targetPos;

    SCNVector3 angles = targetNode.eulerAngles;
    angles.z = 0;
    angles.x = 0;
    angles.y -= M_PI_2;
    self.node.eulerAngles = angles;

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
