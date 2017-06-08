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

#import "VRWorldComponent.h"
#import "PortalComponent.h"
#import "../Utils/SceneKitTools.h"
#import "../Utils/SceneKitExtensions.h"
#import "../Utils/Math.h"
#import "../Core/Core.h"
#import "../Core/AudioEngine.h"
#import <GLKit/GLKit.h>

#define VR_LIGHTS_MAX 3
#define VR_LIGHT_COOLDOWN_PERIOD 1
#define VR_LIGHTS_ENABLED_DELAY 1

#define VR_OPEN_BAY_DOORS_DELAY 3
#define VR_OPEN_BAY_DOORS_INTERVAL 4

#define VR_LIGHT_LEVEL_INSIDE 0.7f
#define VR_LIGHT_LEVEL_OUTSIDE .01f
#define VR_LIGHT_LEVEL_SPEED 2.f

@interface VRWorldComponent()
@property(nonatomic, strong) SCNNode *node;
@property (nonatomic, strong) SCNNode *bookstoreNode;
#ifdef ENABLE_ROBOTROOM
// ------ Robot Room Mode properties -----
@property (nonatomic, strong) SCNNode *robotRoomNode;

@property (nonatomic) BOOL turnOnLights;
@property (nonatomic) int lights; // Number of lights turned on.
@property (nonatomic) NSTimeInterval lightsCooldownPeriod;
@property (nonatomic) NSTimeInterval lightsEnabledDelay;

@property (nonatomic, strong) AudioNode *lightsOnAudio;

@property (nonatomic) BOOL openBayDoors;
@property (nonatomic) NSTimeInterval openBayDoorsDelay;
@property (nonatomic) NSTimeInterval openBayDoorsTimer;
@property (nonatomic, strong) AudioNode *openBayDoorsAudio;

@property (nonatomic) float targetLightLevel;
@property (nonatomic) float currentLightLevel;

@property (nonatomic, strong) NSArray * hinges;
@property (nonatomic, strong) NSArray * displayCubes;
@property (nonatomic) float displayTime;
#endif
@end


@implementation VRWorldComponent
- (void) setEnabled:(bool)enabled {
    [super setEnabled:enabled];

    self.node.hidden = !enabled;
}

- (void) start{
    [super start];
    
    self.node = [[SCNNode alloc] init];
    self.node.name = @"VR World";
    _node.position = SCNVector3Make(0, .01, 0); // Give a 1cm offset, so we don't get co-planar z-fighting between VR world and real world floor.
#ifdef ENABLE_ROBOTROOM
    // ------ Robot Room ----
    self.robotRoomNode = [SCNNode firstNodeFromSceneNamed:@"RobotRoom.dae"];
    self.robotRoomNode.name = @"Robot Room";
    //    _robotRoomNode.rotation = SCNVector4Make(1, 0, 0, M_PI);
    [_node addChildNode:_robotRoomNode];
    
    NSAssert(_node != nil, @"Could not load the room scene");
    
    // Look for the hinge objects.
    NSArray *hingeNames = @[@"Hinge_1",@"Hinge_2",@"Hinge_3",@"Hinge_4",@"Hinge_5",@"Hinge_6",@"Hinge_7",@"Hinge_8",
                            @"Hinge_9",@"Hinge_10",@"Hinge_11",@"Hinge_12",@"Hinge_13",@"Hinge_14",@"Hinge_15",@"Hinge_16"];
    NSMutableArray *foundhinges = [NSMutableArray array];
    for(NSString *name in hingeNames){
        SCNNode *h = [_node childNodeWithName:name recursively:YES];
        if(h)
        {
            [foundhinges addObject:h];
        }
    }
    self.hinges = [NSArray arrayWithArray:foundhinges];
    
    NSMutableArray *foundCubes = [NSMutableArray array];
    [_robotRoomNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        if ([child.name containsString:@"DisplayCube"])
        {
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
    
    SCNNode *SphereNode = [_robotRoomNode childNodeWithName:@"Sphere" recursively:YES];
    
    //need to populate arrays.
    [SphereNode.geometry.firstMaterial.reflective setContents:@[[SceneKit pathForImageResourceNamed:@"Space_right.jpg"],
                                                                [SceneKit pathForImageResourceNamed:@"Space_left.jpg"],
                                                                [SceneKit pathForImageResourceNamed:@"Space_up.jpg"],
                                                                [SceneKit pathForImageResourceNamed:@"Space_down.jpg"],
                                                                [SceneKit pathForImageResourceNamed:@"Space_back.jpg"],
                                                                [SceneKit pathForImageResourceNamed:@"Space_front.jpg"]]];
    
    self.lightsOnAudio = [[AudioEngine main] loadAudioNamed:@"VRWorld_LightsOn.caf"];
    _targetLightLevel = VR_LIGHT_LEVEL_OUTSIDE;
    [self setLightLevel:VR_LIGHT_LEVEL_OUTSIDE];
    
    self.openBayDoorsAudio = [[AudioEngine main] loadAudioNamed:@"VRWorld_BayDoorsOpening.caf"];
// ------ /Robot Room ----
#endif
    
    // ------ Bookstore ----
    self.bookstoreNode = [SCNNode firstNodeFromSceneNamed:@"bookstore.dae"];
    self.bookstoreNode.name = @"Bookstore";
    [_node addChildNode:_bookstoreNode];
    [_node setRenderingOrderRecursively:VR_WORLD_RENDERING_ORDER];
    [_node setCastsShadowRecursively:NO];
    
    [[Scene main].rootNode addChildNode:_node];
    
    // this is for greying out the VR world as tracking feedback
    [self.node enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        for( SCNMaterial * material in child.geometry.materials ) {
            material.shaderModifiers = @{ SCNShaderModifierEntryPointFragment :
               @"uniform float grayAmount;\n"
               "#pragma body\n"
               "vec3 grayColor = vec3(dot(_output.color.rgb, vec3(0.2989, 0.5870, 0.1140)));\n"
               "_output.color.rgb = (1.0 - grayAmount) * _output.color.rgb + grayAmount * grayColor;\n "};
        };
    }];
    
    // Start off the rooms hidden.
#ifdef ENABLE_ROBOTROOM
    _robotRoomNode.hidden = YES;
#endif
    _bookstoreNode.hidden = YES;
}

/**
 * Set which World we're showing.
 */
- (void) setMode:(VRWorldMode)mode {
    _mode = mode;
#ifdef ENABLE_ROBOTROOM
    _robotRoomNode.hidden = mode!=VRWorldRobotRoom;
#endif
    _bookstoreNode.hidden = mode!=VRWorldBookstore;
}


// Attach a KVO on the portalComponent enabled state.
- (void) setPortalComponent:(PortalComponent *)portalComponent {
    [_portalComponent removeObserver:self forKeyPath:@"enabled"];
    _portalComponent = portalComponent;
    
    [_portalComponent addObserver:self
                       forKeyPath:@"enabled"
                          options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew)
                          context:nil];
}

// Follow changes to the portal's enabled state.
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if( object == _portalComponent && [keyPath isEqualToString:@"enabled"] ) {
        self.node.hidden = !_portalComponent.isEnabled;
    }
}

- (void)alignVRWorldToNode:(SCNNode*)targetNode {
#ifdef ENABLE_ROBOTROOM
    if( self.mode == VRWorldRobotRoom ) {
        _robotRoomNode.position = SCNVector3Make(0, 0, 1.5);
        _robotRoomNode.eulerAngles = SCNVector3Make(M_PI, 0, 0); // Rotate around Y-axis to look the other way.
    } else if( self.mode == VRWorldBookstore ) {
        _bookstoreNode.position = SCNVector3Make(0, -0.5, -2.4); // Adjust the vr world to be a little more centred.
        _bookstoreNode.eulerAngles = SCNVector3Make(0, M_PI, 0); // Turn the bookstore around.
    }
#else
    _bookstoreNode.position = SCNVector3Make(0, -0.5, -2.4); // Adjust the vr world to be a little more centred.
    _bookstoreNode.eulerAngles = SCNVector3Make(0, M_PI, 0); // Turn the bookstore around.
#endif
    
    SCNVector3 targetPos = targetNode.position; 
    targetPos.y = 0.0; // Remove the y-offset from the target node, and align to its x/z position only.
    _node.position = targetPos;
    _node.orientation = targetNode.orientation;
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    [super updateWithDeltaTime:seconds];
#ifdef ENABLE_ROBOTROOM
    if( _mode == VRWorldRobotRoom ) {
        if( self.portalComponent.isInsideAR == NO ){
            if ( !self.turnOnLights)
                self.lightsEnabledDelay = VR_LIGHTS_ENABLED_DELAY;
            self.turnOnLights = YES;
        }
        
        if( self.turnOnLights ) {
            self.lightsEnabledDelay -= seconds;
            if ( self.lightsEnabledDelay <= 0)
            {
                _lightsCooldownPeriod -= seconds;
                if( _lights < VR_LIGHTS_MAX && _lightsCooldownPeriod <= 0 ) {
                    self.lights++;
                    be_dbg("Lights On: %d", _lights);
                    self.lightsCooldownPeriod = VR_LIGHT_COOLDOWN_PERIOD;
                    self.targetLightLevel = lerpf( VR_LIGHT_LEVEL_OUTSIDE, VR_LIGHT_LEVEL_INSIDE,  (float)_lights / (float)VR_LIGHTS_MAX );
                    [self.lightsOnAudio play];
                }
            }
        }
        
        if( self.portalComponent.isInsideAR == NO
         && _lights == VR_LIGHTS_MAX
         && _openBayDoors == NO ) {
            self.openBayDoors = YES;
            self.openBayDoorsDelay = VR_OPEN_BAY_DOORS_DELAY;
            self.openBayDoorsTimer = 0;
        }
        
        if( _openBayDoors ) {
            self.openBayDoorsDelay-=seconds;
            if( _openBayDoorsDelay < 0 ) {
                if( _openBayDoorsTimer == 0 ) {
                    [_openBayDoorsAudio play];
                }
            
                _openBayDoorsTimer += seconds;
                [self setBayDoors:smoothstepf(0, 1, _openBayDoorsTimer / VR_OPEN_BAY_DOORS_INTERVAL)];
            }
        }

        [self updateLights:seconds];
        [self flickerDisplayCubes:seconds];
    }
#endif
    float grayness = 1.0 - 2.0 * _portalComponent.mixedReality.lastTrackerHints.modelVisibilityPercentage;
    if ( isnan(grayness))
        grayness = 1.0;
    
    grayness = fmaxf(fminf(grayness, 1.0), 0.0);
    
    [self.node enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        for( SCNMaterial * material in child.geometry.materials ) {
            [material setValue: @(grayness) forKeyPath:@"grayAmount"];
        };
    }];
}

#ifdef ENABLE_ROBOTROOM
- (void) updateLights:(NSTimeInterval)seconds {
    float lightLevel = self.currentLightLevel;
    
    if( self.currentLightLevel < self.targetLightLevel ) {
        lightLevel += VR_LIGHT_LEVEL_SPEED * seconds;
        if( lightLevel > _targetLightLevel ) {
            lightLevel = _targetLightLevel;
        }
    } else if( self.currentLightLevel > self.targetLightLevel ) {
        lightLevel -= VR_LIGHT_LEVEL_SPEED * seconds;
        if( lightLevel < _targetLightLevel ) {
            lightLevel = _targetLightLevel;
        }
    }
    
    lightLevel = clampf( lightLevel, VR_LIGHT_LEVEL_OUTSIDE, VR_LIGHT_LEVEL_INSIDE);

    if( lightLevel != self.currentLightLevel ) {
        [self setLightLevel:lightLevel];
    }
}

- (void) setLightLevel:(float)lightLevel {
    self.currentLightLevel = lightLevel;
    be_dbg("Light level: %.2f", lightLevel);
    
    [self.node enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        for( SCNMaterial * material in child.geometry.materials ) {
            if( [material.name containsString:@"Default"] || [material.name isEqualToString:@"PrimaryTrim"] ) {
                material.lightingModelName = SCNLightingModelConstant;
                material.diffuse.intensity = lightLevel;
            }
        }
    }];
}

- (void) setBayDoors:(float)open {
    for(SCNNode *node in self.hinges) {
        [node setEulerAngles:SCNVector3Make((M_PI/2)*open, 0, 0)];
    }
} 

- (void) flickerDisplayCubes:(float)time {
    self.displayTime += time;
    int i = 0;
    for(SCNNode *cube in self.displayCubes)
    {
        // turn on some cubes...
        [cube setHidden:(((i+(int)self.displayTime)%7)>0)];
        i++;
    }
}
#endif
@end
