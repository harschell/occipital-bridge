/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GamePlayKit/GamePlayKit.h>
#import <SceneKit/SceneKit.h>

#import "../Core/Core.h"
#import "NavigationComponent.h"

@class AudioNode;

typedef NS_ENUM (NSUInteger, RobotHeads) {
    kBoxy,
    kVega,
    kVemoji
};

typedef NS_ENUM (NSUInteger, RobotBodies) {
    kBoxyBody,
    kVegaBody
};

@interface RobotMeshControllerComponent : GeometryComponent <ComponentProtocol>

@property (nonatomic, strong) NavigationComponent * navigationComponent;
@property (nonatomic) float scale;

@property (nonatomic, strong) AudioNode *movementAudio;

@property (nonatomic, strong) SCNNode * robotNode; // Lowest-level of the robot model nodes.
@property (nonatomic, strong) SCNNode * rootCtrl; // Character.Root_Ctrl - Base root animation node
@property (nonatomic, strong) SCNNode * bodyCtrl; // Character.Root_Ctrl.Boxy_Body_Mesh node
@property (nonatomic, strong) SCNNode * headCtrl; // Character.Root_Ctrl.Head_Ctrl node
@property (nonatomic, strong) SCNNode * sensorCtrl; // Character.Root_Ctrl.Head_Ctrl.Sensor_Root node

@property (nonatomic) BOOL robotBoxUnfolded;

- (instancetype) initWithUnboxingExperience:(BOOL)unboxingExperience;

-(void) removeAllAnimations;

- (GLKVector3) getPosition;
- (GLKVector3) getForward;

- (void) setPosition:(GLKVector3) position;

- (void) start;
- (void) moveTo:(GLKVector3)moveToTarget moveIn:(float)seconds;

@property(nonatomic) BOOL looking; // Robot actively looking at a target point?
@property(nonatomic) BOOL lookAtCamera; // YES if we want to look at camera rather than the last target position.

- (void) lookAt:(GLKVector3)lookAtPosition rotateIn:(float)seconds;

/**
 * Set's the Vemoji_Head_Mesh.geometry.EmojiPrimary_Material.diffuse to the image.
 */
@property(nonatomic) NSString* headVemojiDiffuse;

/**
 * Set's the Vemoji_Head_Mesh.geometry.EmojiPrimary_Material.emission to the image.
 */
@property(nonatomic) NSString* headVemojiEmissive;

/**
 * Set's the Boxy_Body_Mesh.geometry.EmojiSecondary_Material.diffuse to the image.
 */
@property(nonatomic) NSString* bodyEmojiDiffuse;

@end
