/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "SpawnComponent.h"
#import "../Core/AudioEngine.h"
#import "../Core/Core.h"
@import GLKit;

#import "PhysicsContactAudioComponent.h"
#import "../Utils/SceneKitExtensions.h"


//#define SPAWN_OBJECT_MODEL_NAME @"Ottoman.scn"
//#define SPAWN_OBJECT_NODE_NAME @"root"

#define SPAWN_OBJECT_MODEL_NAME @"Fridge.dae"
#define SPAWN_OBJECT_NODE_NAME @"node"

//#define SPAWN_OBJECT_MODEL_NAME @"island.dae"
//#define SPAWN_OBJECT_NODE_NAME @"node"

#define SPAWN_COMPONENT_BOX_POOL_SIZE 64

@interface SpawnComponent()
@property (nonatomic, strong) NSMutableArray * boxPool;
@property (nonatomic) int boxPoolIndex;

@property (nonatomic, strong) AudioNode *spawnSound; // Plays when placing each piece of furniture.
@property (nonatomic, strong) AudioNode *resetSound; // Plays when resetting to no furniture.

// Video - single object
//@property (nonatomic, strong) SCNNode *object;
@property (nonatomic, strong) NSMutableArray * furniture;

@end

@implementation SpawnComponent

- (id) init {
    self = [super init];
    
    self.spawnDistanceAlongHitNormal = 1.5; // 0.075f * .9f;
    self.usePhysics = true;
    
    return self;
}

- (void) start{
    [super start];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.spawnSound = [[AudioEngine main] loadAudioNamed:@"BallToss.caf"];
        self.resetSound = [[AudioEngine main] loadAudioNamed:@"BallReturn.caf"];
    });
    
    self.furniture = [[NSMutableArray alloc] init];
    
    // Load furniture Geometry here
    
    SCNNode *chair = [[SCNScene sceneInFrameworkOrAppNamed:@"Objects/ClassicChair.dae"].rootNode
                            childNodeWithName:@"Mesh" recursively:YES];

    [self.furniture addObject:chair];
    SCNNode  *table = [[SCNScene sceneInFrameworkOrAppNamed:@"Objects/CarvedSideTable.dae"].rootNode
                            childNodeWithName:@"Table" recursively:YES];
    
    [self.furniture addObject:table];

    
    // loop through set rendering / physics parameters
    for (int i = 0; i < [self.furniture count]; i++) {
        SCNNode *thing = [self.furniture objectAtIndex:i];
        
        [thing setCategoryBitMaskRecursively: BEShadowCategoryBitMaskCastShadowOntoSceneKit | BEShadowCategoryBitMaskCastShadowOntoEnvironment|RAYCAST_IGNORE_BIT];
        thing.hidden = YES;
        
        SCNPhysicsShape *objectShape = [SCNPhysicsShape shapeWithNode:thing
                                                              options:@{  SCNPhysicsShapeTypeKey:SCNPhysicsShapeTypeConvexHull,
                                                                          SCNPhysicsShapeKeepAsCompoundKey:@YES
                                                                    }];
        
        
        thing.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:objectShape];
        SCNPhysicsBody *objBody = thing.physicsBody;
        objBody.mass = 10;
        objBody.restitution = 0.2;
        objBody.friction = 4.0;
        objBody.rollingFriction = 0.99;
        objBody.damping = 0.1;
        objBody.angularDamping = 0.1;
        objBody.allowsResting = YES;

        // some initial velocity when falling
        objBody.velocity = SCNVector3Make(0, 1.0, 0);
        
        objBody.categoryBitMask = SCNPhysicsCollisionCategoryDefault | BECollisionCategoryVirtualObjects;
        // Want spawned objects to only collide with the floor and each other?  Uncomment this line:
        // WARNING: due to unhandled collision events with the world mesh, this can run slowly when objects intersect the world.
        
        objBody.collisionBitMask = BECollisionCategoryFloor | SCNPhysicsCollisionCategoryDefault| BECollisionCategoryVirtualObjects;
        objBody.contactTestBitMask = BECollisionCategoryFloor | SCNPhysicsCollisionCategoryDefault | BECollisionCategoryVirtualObjects; 
        
        // Associate furniture hitting things with ball Bounce.
        [_physicsContactAudio addNodeName:thing.name audioName:@"BallBounce.caf"];
        
        [[Scene main].rootNode addChildNode:thing];
    }
    

    // I init a boxPool with all boxes here, instead of spawning
    // a new box every time, because (according to @alex):
    //
    // many strange behaviors happen if you have a physics world,
    // then instantiate new physics objects in it. scenekit bug, no other reason.
    // it's never been fixed.
    //
    // :(
    
    self.boxPool = [[NSMutableArray alloc] init];


    for( int i=0; i<SPAWN_COMPONENT_BOX_POOL_SIZE; i++) {
        SCNNode * box = [self addBlockToNode:[Scene main].rootNode];
        box.hidden = YES;
        
        [self.boxPool addObject:box];
    }
    
    self.boxPoolIndex = 0;
}

- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    // [self spawnCube:touchForward hit:hit];
    [self placeObject:hit];
    return YES;
}

- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (bool) touchCancelledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (BOOL) placeObject:(SCNHitTestResult *) hit  {
    
    if( self.boxPoolIndex < [self.furniture count]){
        NSLog(@"placing the thing");
        [_spawnSound play];
        
        SCNNode *node = [self.furniture objectAtIndex:self.boxPoolIndex];
        node.hidden = NO;
        
        SCNVector3 hitPosition = hit.worldCoordinates;

        hitPosition.y -= self.spawnDistanceAlongHitNormal;
        node.position = hitPosition;

        // Orient towards camera.
        GLKVector3 forward = GLKVector3Subtract( SCNVector3ToGLKVector3(hitPosition), [Camera main].position );
        float yRot = atan2f(forward.x, forward.z);

        SCNVector3 euler = node.eulerAngles;
        euler.x = M_PI + 0.0000001;
        euler.y = yRot;
        euler.z = 0;
        node.eulerAngles = euler;
        
        node.physicsBody.velocity = SCNVector3Zero;
        node.physicsBody.angularVelocity = SCNVector4Zero;
        [node.physicsBody resetTransform];
        [node.physicsBody clearAllForces];
        
        [self.robotBehaviourComponent startLookAtNode:node];
        self.boxPoolIndex ++;
    } else {
        [_resetSound play];
        self.boxPoolIndex = 0;
        for (int i =0; i < [self.furniture count]; i++ ) {
            SCNNode *thing = [self.furniture objectAtIndex:i];
            thing.hidden = YES;
            [thing.physicsBody resetTransform];
            [thing.physicsBody clearAllForces];
        }
    }
    return self.boxPoolIndex > 0;
}

- (void) placeNode:(SCNNode*)node forward:(GLKVector3)forward hit:(SCNHitTestResult *) hit {
    GLKVector3 offset;
    
    if( hit ) {
        forward = GLKVector3Subtract(SCNVector3ToGLKVector3([hit worldCoordinates]), [Camera main].position);
        offset = GLKVector3MultiplyScalar( SCNVector3ToGLKVector3(hit.worldNormal), self.spawnDistanceAlongHitNormal );
    } else {
        forward = GLKVector3MultiplyScalar( forward, .3f ); // if no surface is hit, spawn at .3 meter
        offset = GLKVector3Make(0, self.spawnDistanceAlongHitNormal, 0);
    }
    
    GLKVector3 position = GLKVector3Add( [Camera main].position, forward );

    position = GLKVector3Add( position, offset );
    node.position = SCNVector3FromGLKVector3(position);

    // Orient to surface normal.
//    if( hit.node ) {
//        node.orientation = hit.node.orientation;
//    }

    // Orient to match the camera.
    SCNVector3 euler = [Camera main].node.eulerAngles;
    euler.x = M_PI; // Turn models right-side-up.
    euler.z = 0;
//    euler.y += M_PI; // Turn around to face camera.  (already facing camera with X-axis flip)
    node.eulerAngles = euler;
    
    [node.physicsBody resetTransform];
    [node.physicsBody clearAllForces];
    
    [self.robotBehaviourComponent startLookAtNode:node];
}


- (void) spawnCube:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    SCNNode *block = [self spawnBoxFromPool];
    [self placeNode:block forward:touchForward hit:hit];
}

- (SCNNode *)spawnBoxFromPool
{
    SCNNode * node = (SCNNode *)[self.boxPool objectAtIndex:self.boxPoolIndex];
    
    node.hidden = NO;
    
    node.physicsBody.velocity = SCNVector3Zero;
    node.physicsBody.angularVelocity = SCNVector4Zero;
    
    [node.physicsBody clearAllForces];
    [node.physicsBody resetTransform];
    
    self.boxPoolIndex = (self.boxPoolIndex + 1) % SPAWN_COMPONENT_BOX_POOL_SIZE;
    
    return node;
}

- (SCNNode *)addBlockToNode:(SCNNode *)rootNode
{
    //create a new node
    SCNNode *block = [SCNNode node];
    
    block.name = @"Block";
    block.geometry = [SCNBox boxWithWidth:.075 height:.075 length:.075 chamferRadius:0];
    
    float hue = (float)drand48();
    block.geometry.firstMaterial.diffuse.contents = [UIColor colorWithHue:hue saturation:.8f brightness:.5f alpha:1.f];
    
    //make it physically based
    if( self.usePhysics ) {
        block.physicsBody =  [SCNPhysicsBody dynamicBody];
        block.physicsBody.mass = .5;
        block.physicsBody.restitution = 0.5;
        block.physicsBody.friction = 0.99;
        block.physicsBody.rollingFriction = 0.01;
        block.physicsBody.damping = 0.01;
        block.physicsBody.angularDamping = 0.01;
        block.physicsBody.allowsResting = YES;
    }
    
    block.hidden = YES;
    
    //add to the scene
    [rootNode addChildNode:block];
    
    return block;
}

@end
