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

#import "OutsideWorldComponent.h"
#import "SceneKitExtensions.h"
#import "AudioEngine.h"
#import "OpenBE/Utils/Math.h"

#define VR_LIGHTS_MAX 3
#define VR_LIGHT_COOLDOWN_PERIOD 1
#define VR_LIGHTS_ENABLED_DELAY 1

#define VR_OPEN_BAY_DOORS_DELAY 3
#define VR_OPEN_BAY_DOORS_INTERVAL 4

#define VR_LIGHT_LEVEL_INSIDE 0.7f
#define VR_LIGHT_LEVEL_OUTSIDE .01f
#define VR_LIGHT_LEVEL_SPEED 2.f

@interface OutsideWorldComponent ()
@property(nonatomic, strong) SCNNode *node;
@property(nonatomic, strong) SCNNode *robotRoomNode;

@property(nonatomic) BOOL turnOnLights;
@property(nonatomic) int lights; // Number of lights turned on.
@property(nonatomic) NSTimeInterval lightsCooldownPeriod;
@property(nonatomic) NSTimeInterval lightsEnabledDelay;

@property(nonatomic, strong) AudioNode *lightsOnAudio;

@property(nonatomic) BOOL openBayDoors;
@property(nonatomic) NSTimeInterval openBayDoorsDelay;
@property(nonatomic) NSTimeInterval openBayDoorsTimer;
@property(nonatomic, strong) AudioNode *openBayDoorsAudio;

@property(nonatomic) float targetLightLevel;
@property(nonatomic) float currentLightLevel;

@property(nonatomic, strong) NSArray *hinges;
@property(nonatomic, strong) NSArray *displayCubes;
@property(nonatomic) float displayTime;

@property(nonatomic) bool insideAR;
@end

@implementation OutsideWorldComponent
- (void)setEnabled:(bool)enabled {
    [super setEnabled:enabled];

    self.node.hidden = !enabled;
}

- (void)start {
    [super start];

    self.node = [[SCNNode alloc] init];
    self.node.name = @"VR World";

    // Give a 1cm offset, so we don't get co-planar z-fighting between VR world and real world floor.
    self.node.position = SCNVector3Make(0, .01, 0);

    // ------ Robot Room ----
    self.robotRoomNode = [SCNNode firstNodeFromSceneNamed:@"RobotRoom.dae"];
    self.robotRoomNode.name = @"Robot Room";
    //    _robotRoomNode.rotation = SCNVector4Make(1, 0, 0, M_PI);
    [self.node addChildNode:self.robotRoomNode];

    NSAssert(self.node!=nil, @"Could not load the room scene");

    // Look for the hinge objects.
    NSArray *hingeNames =
            @[@"Hinge_1", @"Hinge_2", @"Hinge_3", @"Hinge_4", @"Hinge_5", @"Hinge_6", @"Hinge_7", @"Hinge_8",
                    @"Hinge_9", @"Hinge_10", @"Hinge_11", @"Hinge_12", @"Hinge_13", @"Hinge_14", @"Hinge_15",
                    @"Hinge_16"];
    NSMutableArray *foundhinges = [NSMutableArray array];
    for (NSString *name in hingeNames) {
        SCNNode *h = [self.node childNodeWithName:name recursively:YES];
        if (h) {
            [foundhinges addObject:h];
        }
    }
    self.hinges = [NSArray arrayWithArray:foundhinges];

    NSMutableArray *foundCubes = [NSMutableArray array];
    [self.robotRoomNode enumerateChildNodesUsingBlock:^(SCNNode *_Nonnull child, BOOL *_Nonnull stop) {
        if ([child.name containsString:@"DisplayCube"]) {
            SCNMaterial *mat = [SCNMaterial material];
            [mat setLitPerPixel:NO];
            [mat setLightingModelName:SCNLightingModelConstant];
            [mat setBlendMode:SCNBlendModeAdd];
            [mat setTransparency:0.9];
            [mat.diffuse setContents:[UIColor orangeColor]];
            [child.geometry setFirstMaterial:mat];
            [foundCubes addObject:child];
        }
    }];
    self.displayCubes = [NSArray arrayWithArray:foundCubes];

    SCNNode *SphereNode = [self.robotRoomNode childNodeWithName:@"Sphere" recursively:YES];

    //need to populate arrays.
    [SphereNode.geometry.firstMaterial.reflective setContents:@[[SceneKit pathForImageResourceNamed:@"Space_right.jpg"],
            [SceneKit pathForImageResourceNamed:@"Space_left.jpg"],
            [SceneKit pathForImageResourceNamed:@"Space_up.jpg"],
            [SceneKit pathForImageResourceNamed:@"Space_down.jpg"],
            [SceneKit pathForImageResourceNamed:@"Space_back.jpg"],
            [SceneKit pathForImageResourceNamed:@"Space_front.jpg"]]];

    self.lightsOnAudio = [[AudioEngine main] loadAudioNamed:@"VRWorld_LightsOn.caf"];
    self.targetLightLevel = VR_LIGHT_LEVEL_OUTSIDE;
    [self setLightLevel:VR_LIGHT_LEVEL_OUTSIDE];

    self.openBayDoorsAudio = [[AudioEngine main] loadAudioNamed:@"VRWorld_BayDoorsOpening.caf"];

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
    self.node.hidden = NO;
}

- (void)alignVRWorldToNode:(SCNNode *)targetNode {
    self.robotRoomNode.position = SCNVector3Make(0, 0, 1.5);
    self.robotRoomNode.eulerAngles = SCNVector3Make(M_PI, 0, 0); // Rotate around Y-axis to look the other way.

    SCNVector3 targetPos = targetNode.position;
    targetPos.y = 0.0; // Remove the y-offset from the target node, and align to its x/z position only.
    self.node.position = targetPos;
    self.node.orientation = targetNode.orientation;
}

- (void)setPlayerInsideAR:(bool)playerInsideAR {
    self.insideAR = playerInsideAR;
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds {
    [super updateWithDeltaTime:seconds];

    if (self.insideAR==NO) {
        if (!self.turnOnLights)
            self.lightsEnabledDelay = VR_LIGHTS_ENABLED_DELAY;
        self.turnOnLights = YES;
    }

    if (self.turnOnLights) {
        self.lightsEnabledDelay -= seconds;
        if (self.lightsEnabledDelay <= 0) {
            self.lightsCooldownPeriod -= seconds;
            if (self.lights < VR_LIGHTS_MAX && self.lightsCooldownPeriod <= 0) {
                self.lights++;
                be_dbg("Lights On: %d", self.lights);
                self.lightsCooldownPeriod = VR_LIGHT_COOLDOWN_PERIOD;
                self.targetLightLevel =
                        lerpf(VR_LIGHT_LEVEL_OUTSIDE,
                              VR_LIGHT_LEVEL_INSIDE,
                              (float) self.lights / (float) VR_LIGHTS_MAX);
                [self.lightsOnAudio play];
            }
        }
    }

    if (self.insideAR==NO
            && self.lights==VR_LIGHTS_MAX
            && self.openBayDoors==NO) {
        self.openBayDoors = YES;
        self.openBayDoorsDelay = VR_OPEN_BAY_DOORS_DELAY;
        self.openBayDoorsTimer = 0;
    }

    if (self.openBayDoors) {
        self.openBayDoorsDelay -= seconds;
        if (self.openBayDoorsDelay < 0) {
            if (self.openBayDoorsTimer==0) {
                [self.openBayDoorsAudio play];
            }

            self.openBayDoorsTimer += seconds;
            [self setBayDoors:smoothstepf(0, 1, self.openBayDoorsTimer / VR_OPEN_BAY_DOORS_INTERVAL)];
        }
    }

    [self updateLights:seconds];
    [self flickerDisplayCubes:seconds];

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

- (void)updateLights:(NSTimeInterval)seconds {
    float lightLevel = self.currentLightLevel;

    if (self.currentLightLevel < self.targetLightLevel) {
        lightLevel += VR_LIGHT_LEVEL_SPEED * seconds;
        if (lightLevel > self.targetLightLevel) {
            lightLevel = self.targetLightLevel;
        }
    } else if (self.currentLightLevel > self.targetLightLevel) {
        lightLevel -= VR_LIGHT_LEVEL_SPEED * seconds;
        if (lightLevel < self.targetLightLevel) {
            lightLevel = self.targetLightLevel;
        }
    }

    lightLevel = clampf(lightLevel, VR_LIGHT_LEVEL_OUTSIDE, VR_LIGHT_LEVEL_INSIDE);

    if (lightLevel!=self.currentLightLevel) {
        [self setLightLevel:lightLevel];
    }
}

- (void)setLightLevel:(float)lightLevel {
    self.currentLightLevel = lightLevel;
    be_dbg("Light level: %.2f", lightLevel);

    [self.node enumerateChildNodesUsingBlock:^(SCNNode *_Nonnull child, BOOL *_Nonnull stop) {
        for (SCNMaterial *material in child.geometry.materials) {
            if ([material.name containsString:@"Default"] || [material.name isEqualToString:@"PrimaryTrim"]) {
                material.lightingModelName = SCNLightingModelConstant;
                material.diffuse.intensity = lightLevel;
            }
        }
    }];
}

- (void)setBayDoors:(float)open {
    for (SCNNode *node in self.hinges) {
        [node setEulerAngles:SCNVector3Make((M_PI / 2) * open, 0, 0)];
    }
}

- (void)flickerDisplayCubes:(float)time {
    self.displayTime += time;
    int i = 0;
    for (SCNNode *cube in self.displayCubes) {
        // turn on some cubes...
        [cube setHidden:(((i + (int) self.displayTime) % 7) > 0)];
        i++;
    }
}
@end
