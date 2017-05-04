/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "PhysicsContactAudioComponent.h"
#import "../Utils/ComponentUtils.h"
#import "../Utils/Math.h"

#define PHYSICS_BOUNCE_IMPULSE_POWER 0.7f

@interface PhysicsContactAudio ()
@property(nonatomic) NSTimeInterval bounceCoolOffTimer;
@property(nonatomic) float bounceCoolOffMaxImpulse;
@property(nonatomic) float bounceHighestImpulse;
@property(nonatomic) SCNVector3 bouncePosition;
@end

@implementation PhysicsContactAudio

- (instancetype)initWithNodeName:(NSString*)nodeName audioName:(NSString*)audioName;
{
    self = [super init];
    if (self) {
        self.nodeName = nodeName;
        self.audioNode = [[AudioEngine main] loadAudioNamed:audioName];
        
        self.minImpulse = 25;
        self.maxImpulse = 400;
        self.bounceCoolOffTime = 0.33f;
    }
    return self;
}

/**
 * Reset the cooloff timer, so next bounce will always trigger.
 */
- (void) resetBounceCooloffTimer {
    _bounceCoolOffTimer = -1;
}

- (void) calculatePeakImpulseForContact:(SCNPhysicsContact *)contact forNode:(SCNNode*)node {
    // Calculate the momentary impact speed: (velocityNormal•contactNormal)*velocitySpeed = velocity•contactNormal = impactSpeed
    GLKVector3 velocity = SCNVector3ToGLKVector3(node.physicsBody.velocity);
    GLKVector3 contactNormal = SCNVector3ToGLKVector3(contact.contactNormal);
    float impactSpeed = GLKVector3DotProduct(velocity, contactNormal);

    // Replace the totally unreliable SceneKit physics system reports of impulse.
    // Assume a mass of 100, so we get a similar range to that collisionImpulse was returning.
    float collisionImpulse = impactSpeed * 100;// contact.collisionImpulse;
    if( isnan(collisionImpulse) || collisionImpulse < self.minImpulse ) {
        return;
    }

    if( _bounceHighestImpulse < collisionImpulse ) {
        _bounceHighestImpulse = collisionImpulse;
        _bouncePosition = contact.contactPoint;
    }
}

- (void) updatePhysics:(float) dt {
    _bounceCoolOffTimer -= dt;

    if(_bounceCoolOffTimer < 0 && _bounceCoolOffMaxImpulse > 0 )
    {
        _bounceCoolOffMaxImpulse = 0;
        _bounceHighestImpulse = 0;
//        NSLog(@"bounce reset");
    }
    
    if( _bounceCoolOffMaxImpulse < _bounceHighestImpulse ) {
        // Hit a new peak impulse, reset our cool-off timer.
        _bounceCoolOffTimer = _bounceCoolOffTime;
        
        // Record new maxImpulse for our cool-off timer.
        _bounceCoolOffMaxImpulse = _bounceHighestImpulse;
        _bounceHighestImpulse = 0;
        
        // Play with new peak impulse.
        float bounceImpulse = clampf(_minImpulse, _maxImpulse, _bounceCoolOffMaxImpulse);
        float bounceVolume = clampf(1, 0, powf(bounceImpulse - _minImpulse, PHYSICS_BOUNCE_IMPULSE_POWER) / powf(_maxImpulse-_minImpulse, PHYSICS_BOUNCE_IMPULSE_POWER) );
//         NSLog(@"bounce volume: %f, impulse: %f, actual impulse: %f", bounceVolume, bounceImpulse, _bounceCoolOffMaxImpulse );
        _audioNode.volume = bounceVolume;
        _audioNode.position = _bouncePosition;
        [self.audioNode play];
    }
}

@end

@interface PhysicsContactAudioComponent ()
@property(nonatomic, strong) NSMutableDictionary<NSString*,PhysicsContactAudio*> *physicsContactNodes;
@end

@implementation PhysicsContactAudioComponent

- (instancetype)init
{
    self = [super init];
    if (self) {
        _physicsContactNodes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/**
 * Attach to the physicsWorld as the contact delegate.
 */ 
- (void) setPhysicsWorld:(SCNPhysicsWorld *)physicsWorld {
    _physicsWorld.contactDelegate = nil;
    
    _physicsWorld = physicsWorld;
    _physicsWorld.contactDelegate = self;
}

/**
 * Associate a node's contact with a particular sound effect
 */ 
- (PhysicsContactAudio*) addNodeName:(NSString*)nodeName audioName:(NSString*)audioName {

    if( _physicsContactNodes[nodeName] != nil ) {
        NSLog(@"PhysicsSoundComonent: === Warning === Already associated audioName: %@ with nodeName: %@", audioName, nodeName );
    }

    PhysicsContactAudio *contactSound = [[PhysicsContactAudio alloc] initWithNodeName:nodeName audioName:audioName];
    _physicsContactNodes[nodeName] = contactSound;

    return contactSound;
}

/**
 * Get the physics audio from node name.
 */
- (PhysicsContactAudio*) physicsAudioForNodeName:(NSString*)nodeName {
    return _physicsContactNodes[nodeName];
}

/**
 * Remove the physics audio node name.
 */ 
- (void) removeNodeName:(NSString*)nodeName {
    [_physicsContactNodes removeObjectForKey:nodeName];
}

#pragma mark - Update Methods
 
- (void) updateWithDeltaTime:(NSTimeInterval)dt {
    if( ![self isEnabled] ) return;
    
    // Update all the physics nodes.
    for( PhysicsContactAudio *contactAudio in _physicsContactNodes.allValues ) {
        [contactAudio updatePhysics:dt];
    }
}

- (void) calculatePeakImpulseForContact:(SCNPhysicsContact *)contact {
    // Reject non-colliding contacts, where it's non-mutual.
    SCNPhysicsBody *bodyA = contact.nodeA.physicsBody;
    SCNPhysicsBody *bodyB = contact.nodeB.physicsBody;
    if( (bodyA.collisionBitMask & bodyB.categoryBitMask) == 0 )
    {
        be_NSDbg(@"Unecessary contact on %@, check your contactTestBitMask", contact.nodeA.name);
        return; //Reject non-mutual collision.
    } 

    PhysicsContactAudio *contactSound = _physicsContactNodes[contact.nodeA.name];
    if( contactSound != nil ) {
        [contactSound calculatePeakImpulseForContact:contact forNode:contact.nodeA];
    }
}

#pragma mark - PhysicsWorld contact delegate methods

- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact {
    [self calculatePeakImpulseForContact:contact];
}

- (void)physicsWorld:(SCNPhysicsWorld *)world didUpdateContact:(SCNPhysicsContact *)contact {
    [self calculatePeakImpulseForContact:contact];
}

- (void)physicsWorld:(SCNPhysicsWorld *)world didEndContact:(SCNPhysicsContact *)contact {}


@end
