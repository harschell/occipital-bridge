/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "PathFindMoveToBehaviourComponent.h"
#import "MoveToBehaviourComponent.h"
#import "../../Utils/Math.h"
#import "../../Core/PathFinding.h"

#import "../RobotVemojiComponent.h"
#import "../AnimationComponent.h"
#import "../../Core/AudioEngine.h"
#import "../../Utils/SceneKitExtensions.h"

@import GLKit;

#define GROUND_HEIGHT (-0.02f);//roughly above the ground's scanned mesh result
typedef void (^callback)(void);

@interface PathFindMoveToBehaviourComponent()
@property (strong) PathFinding * pathFinding;
@property (weak)   MoveToBehaviourComponent * moveTo;
@property (strong) NSMutableArray<NSValue*> * moveWayPoints; // NSValues of GLKVector3 structs.
@property (nonatomic) int moveWayPointIndex;
@property (nonatomic) bool moving;
@property (nonatomic, strong) PathFindingOperation *pathFindingOperation;
@property (nonatomic) BOOL pathFindingSucceded; // Return if we successfully found a path to target.

// Thinking parts
@property(nonatomic, weak) AnimationComponent *animComponent;
@property(nonatomic, weak) RobotVemojiComponent *vemojiComponent;
@property(nonatomic, strong) NSArray<NSString*> *vemojiThinkingSequence;
@property(nonatomic, strong) CAAnimation *thinkingAnimation;
@property(nonatomic, strong) AudioNode *thinkingAudio;

@property(nonatomic, strong) AudioNode *pathUmWhatCorrection;

@property(nonatomic, strong) SCNGeometry *pathGeo;
@property(nonatomic, strong) NSMutableArray *pathNodes;
@property(nonatomic, strong) SCNNode *pathParentNode;

@property(nonatomic, strong) SCNNode *occupancyParentNode;
@property(nonatomic, strong) SCNNode *connectedComponentsParentNode;

@property(nonatomic) float groundY;
@end


@implementation PathFindMoveToBehaviourComponent

- (void) dealloc {
    [self deallocPath];
}

- (void) start {
    [super start];

    self.pathFinding = [[PathFinding alloc] init];
    self.moveTo = (MoveToBehaviourComponent *)[self.entity componentForClass:[MoveToBehaviourComponent class]];

    self.moveSpeedModifier = 1.f;
    self.moveWayPoints = [[NSMutableArray alloc] init];
    self.moveWayPointIndex = 0;
    self.moving = NO;
    
    self.vemojiThinkingSequence = [RobotVemojiComponent nameArrayBase:@"Vemoji_Scanning" start:1 end:16 digits:2];
    self.animComponent=(AnimationComponent*)[self.entity componentForClass:AnimationComponent.class];
    self.vemojiComponent = (RobotVemojiComponent*)[self.entity componentForClass:RobotVemojiComponent.class];
    self.thinkingAudio = [[AudioEngine main] loadAudioNamed:@"Robot_ThinkingLoop.caf"];
    _thinkingAudio.looping = YES;
    
    self.pathUmWhatCorrection = [[AudioEngine main] loadAudioNamed:@"Robot_UmWhat.caf"];
    
    [self initPath];
}

- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3) targetPosition callback:(void (^)(void))callbackBlock {
    [super runBehaviourFor:999 targetPosition:targetPosition callback:callbackBlock];
    self.showPathPlan = YES;
    self.showSadOnPathingFailure = YES;
    
    [self startMovementTo:targetPosition];
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    if( ![self isRunning] ) return;
    
    if( _pathFindingOperation ) {
        [self checkPathFinding];
    }
    
    [super updateWithDeltaTime:seconds];
}

#pragma mark - Public Methods

- (void) setReachableReferencePoint:(GLKVector3)reachableReferencePoint {
    // Check if our reference point needs adjusting.
    if( [_pathFinding occupied:reachableReferencePoint] ) {
        be_NSDbg(@"The refrence point for path finding is sitting on an occupied point.");
        unsigned char largestCC = [_pathFinding largestConnectedComponent];
        
        GLKVector3 nearestPt;
        if( [_pathFinding closestAccessiblePointTo:_reachableReferencePoint inComponent:largestCC result:&nearestPt] ) {
            be_NSDbg(@"Adjusting to largest nearby component ID %d, at un-occupied point (%f, %f, %f)", (int)largestCC, nearestPt.x, nearestPt.y, nearestPt.z);
            _reachableReferencePoint = nearestPt;
        } else {
            be_NSDbg(@"No suitable point");
        }
    } else {
        _reachableReferencePoint = reachableReferencePoint;
    }
}

- (void) setShowOccupancy:(BOOL)showOccupancy {
    _showOccupancy = showOccupancy;
    
    if( _showOccupancy ) {
        if( _occupancyParentNode == nil ) {
            _occupancyParentNode = [[SCNNode alloc] init];
            
            float nodeSize = [_pathFinding pixelSizeInMeters];
            SCNGeometry *geo = [SCNBox boxWithWidth:nodeSize height:nodeSize length:nodeSize chamferRadius:0];
            geo.firstMaterial.diffuse.contents = [UIColor yellowColor]; // [[UIColor yellowColor] colorWithAlphaComponent:0.5];

            NSMutableArray<NSValue*> *points = [_pathFinding occupiedPoints];
            for( NSValue *pt in points ){
                GLKVector3 p;
                [pt getValue:&p];
                p.y -= nodeSize*0.5; // Offset above ground
                
                // Create SCNNodes
                SCNNode *node = [SCNNode nodeWithGeometry:geo];
                node.categoryBitMask |= RAYCAST_IGNORE_BIT;
                node.categoryBitMask |= BEShadowCategoryBitMaskCastShadowOntoSceneKit | BEShadowCategoryBitMaskCastShadowOntoEnvironment; // add lighting
                node.castsShadow = NO;
                node.position = SCNVector3FromGLKVector3(p);
                [_occupancyParentNode addChildNode:node];
            }
            
            [[Scene main].rootNode addChildNode:_occupancyParentNode];
        }
    }
    
    _occupancyParentNode.hidden = _showOccupancy == NO;
}

- (void) setShowConnectedComponents:(BOOL)show {
    _showConnectedComponents = show;
    
    if( _showConnectedComponents ) {
        if( _connectedComponentsParentNode == nil ) {
            _connectedComponentsParentNode = [[SCNNode alloc] init];
            
            float nodeSize = [_pathFinding pixelSizeInMeters];
            
            NSArray<UIColor*> *colors = @[
                [UIColor brownColor],
                [UIColor redColor],
                [UIColor orangeColor],
                [UIColor magentaColor],
                [UIColor greenColor],
                [UIColor cyanColor],
                [UIColor blueColor],
                [UIColor purpleColor]
            ];
            
            NSMutableArray<SCNGeometry*> *geoColors = [[NSMutableArray alloc] initWithCapacity:8];
            for( int i=0; i<8; i++ ) {
                SCNGeometry *geo = [SCNBox boxWithWidth:nodeSize height:nodeSize*2 length:nodeSize chamferRadius:0];
                geo.firstMaterial.diffuse.contents = colors[i];
                [geoColors addObject:geo];
            }
            
            NSMutableArray<NSValue*> *points = [_pathFinding connectedComponentPoints];
            for( NSValue *pt in points ){
                GLKVector3 p;
                [pt getValue:&p];
                
                // Create SCNNodes with a component colour
                int componentSet = (int)p.y % 8;
                SCNGeometry *geo = geoColors[componentSet];
                SCNNode *node = [SCNNode nodeWithGeometry:geo];
                node.categoryBitMask |= RAYCAST_IGNORE_BIT;
                node.categoryBitMask |= BEShadowCategoryBitMaskCastShadowOntoSceneKit | BEShadowCategoryBitMaskCastShadowOntoEnvironment; // add lighting
                node.castsShadow = NO;
                node.position = SCNVector3Make(p.x, -nodeSize, p.z);
                [_connectedComponentsParentNode addChildNode:node];
            }
            
            [[Scene main].rootNode addChildNode:_connectedComponentsParentNode];
        }
    }

    _connectedComponentsParentNode.hidden = _showConnectedComponents == NO;
}


/**
 * Get the largest available component area, and search for a point that's open.
 * Biases a little front (1m) and center.
 */
- (GLKVector3) findLargestOpenAreaPoint {
    unsigned char largestComponent = [_pathFinding largestConnectedComponent];
    GLKVector3 point;
    if( [_pathFinding closestAccessiblePointTo:(GLKVector3){0,0,-.3} inComponent:largestComponent result:&point] ) {
        return point;
    } else {
        be_NSDbg(@"Failed to find a point in front/center that's open");
        return (GLKVector3){0,0,-1};
    }
}


- (BOOL) occupied:(GLKVector3)target {
    return [_pathFinding occupied:target];
}

- (float) durationToTarget:(GLKVector3) targetPosition {
    return [self.moveTo durationToTarget:targetPosition];
}


#pragma mark - path finding
- (void) setPathFindingOperation:(PathFindingOperation *)pathFindingOperation {
    _pathFindingOperation = pathFindingOperation;
    
    if( _pathFindingOperation ) {
        [_vemojiComponent setExpressionSequence:_vemojiThinkingSequence];
        [_thinkingAudio play];
    } else {
        [_vemojiComponent stopExpressionSequence];
        [_thinkingAudio stop];
    }
}

- (void) startMovementTo:(GLKVector3)target {
    if( [NSThread isMainThread] ) {
        be_NSDbg(@"PathFindMoveToBehaviourComponent: We're on MAIN THREAD!!");
    }

    [_pathFindingOperation cancel];
    self.pathFindingOperation = nil;
    self.moveWayPointIndex = 0;
    self.moving = YES;
    self.pathFindingSucceded = NO;
    [self clearPath];
    [self.moveWayPoints removeAllObjects];
    
    be_NSDbg(@"Start movement to %.2f %.2f %.2f, with speed: %.2f", target.x, target.y, target.z, _moveSpeedModifier);
    
    GLKVector3 from = [[self getRobot] getPosition];
    if( [_pathFinding occupied:from] ) {
        [_pathUmWhatCorrection play];

        // Check if our reference point needs adjusting.
        if( [_pathFinding occupied:_reachableReferencePoint] ) {
            be_NSDbg(@"The refrence point for path finding is sitting on an occupied point.");
            unsigned char largestCC = [_pathFinding largestConnectedComponent];
            
            GLKVector3 nearestPt;
            if( [_pathFinding closestAccessiblePointTo:_reachableReferencePoint inComponent:largestCC result:&nearestPt] ) {
                be_NSDbg(@"Adjusting to largest nearby component ID %d, at un-occupied point (%f, %f, %f)", (int)largestCC, nearestPt.x, nearestPt.y, nearestPt.z);
                self.reachableReferencePoint = nearestPt;
            }
        }

        GLKVector3 ptTmp;
        if( [_pathFinding closestAccessiblePointTo:from fromPoint:_reachableReferencePoint result:&ptTmp] == NO ) {
            be_NSDbg(@"Path Finding: Completly failed to find a valid from (%f,%f,%f) starting point, was reference point (%f,%f,%f) put in an occupied area?",
                from.x, from.y, from.z, _reachableReferencePoint.x, _reachableReferencePoint.y, _reachableReferencePoint.z );
            if( _showSadOnPathingFailure ) {
                [self.getRobot beSad];
            }
            
            self.moving = NO;
            [self stopRunning];
            return;  // TOTAL BAIL HERE!
        } else {
            be_NSDbg(@"PathFindMoveTo: Bad starting point %@ correcting to %@",
            [_pathFinding stringForPoint:from], [_pathFinding stringForPoint:ptTmp] );
        }
        
        from = ptTmp;
        float duration = [_moveTo durationToTarget:ptTmp];
        [_moveTo runBehaviourFor:duration*_moveSpeedModifier targetPosition:ptTmp callback:^(){
            self.pathFindingOperation = [self.pathFinding findNearestPath:ptTmp to:target completion:nil];
        }];
    } else {
        self.pathFindingOperation = [self.pathFinding findNearestPath:from to:target completion:nil];
    }
}

- (void) checkPathFinding {
    if( _pathFindingOperation.finished == NO ) {
        if( self.timer < 2.f) {
            return; // Keep going until we hit our timeout.
        } else {
            [_pathFindingOperation cancel];
            be_NSDbg(@"Path find timeout!");
        }
    }
    
    // We're finished, so load all the waypoints.
    NSMutableArray *wayPoints = nil;
    if( _pathFindingOperation && _pathFindingOperation.finished ) {
         wayPoints = _pathFindingOperation.waypoints;
    }

    if( [wayPoints count] ) {
        [self.moveWayPoints removeAllObjects];
        
        // Copy each waypoint.
        for( int i=0; i<[wayPoints count] ; i++ ) {
            GLKVector3 target;
            
            NSValue *value = [wayPoints objectAtIndex:i];
            [value getValue:&target];
            
            // float robot to ground.
            target.y = GROUND_HEIGHT;
            
            [self.moveWayPoints addObject:[NSValue valueWithBytes:&target objCType:@encode(GLKVector3)]];
        }
        
        // Back-up from last point, to our stopping distance.
        // Replace the final waypoint with our validStopTarget, and clear the rest.
        float distanceBacktrack = 0;
        GLKVector3 stopTarget;
        NSUInteger stopIndex = _moveWayPoints.count - 1;
        [_moveWayPoints[stopIndex] getValue:&stopTarget];

        for( int i=(int)_moveWayPoints.count-1; i>0; i--) {
            GLKVector3 farthest, nextFarthest;
            [_moveWayPoints[i] getValue:&farthest];
            [_moveWayPoints[i-1] getValue:&nextFarthest];
            
            float nextFurthestDistance = GLKVector3Distance(nextFarthest, farthest);
            float nextFarthestBacktrack = distanceBacktrack + nextFurthestDistance;
            if( nextFarthestBacktrack <= _stoppingDistance )
            {
                be_NSDbg(@"Stepping back: %d", i);
                distanceBacktrack = nextFarthestBacktrack;
            } else {
                // Found the crossing threshold, so recalculate the stopTarget.

                // Find t along the last segment.
                float t = (nextFarthestBacktrack - _stoppingDistance) / nextFurthestDistance; 
                
                // Lerp to find the last segment.
                stopTarget = GLKVector3Lerp(nextFarthest, farthest, t);
                stopIndex = i;
                break;
            }
        }

        be_NSDbg(@"Re-calculating stopTarget, stopIndex = %d", (int)stopIndex);

        // Find the nearest reachable stopTarget.
        GLKVector3 validStopTarget;
        if( [_pathFinding closestAccessiblePointTo:stopTarget fromPoint:_reachableReferencePoint result:&validStopTarget] ) {
            be_NSDbg(@"Replacing stopTarget");

            // Got a valid stop target, replace it, and clear the rest.
            _moveWayPoints[stopIndex] = [NSValue valueWithBytes:&validStopTarget objCType:@encode(GLKVector3)];
            
            // Clear the rest.
            if( (stopIndex+1) < _moveWayPoints.count ) {
                NSRange range = NSMakeRange(stopIndex+1, _moveWayPoints.count-(stopIndex+1));
                be_NSDbg(@"Clearing the rest of the waypoints, start: %ld length: %ld", range.location, range.length);
                [_moveWayPoints removeObjectsInRange:range];
            }
        } else {
            NSLog(@"ERROR -=-= Could not find reachable stop target, this shouldn't happen =-=- ");
        }
        
        self.pathFindingSucceded = YES;
    } else {
        if( _showSadOnPathingFailure ) {
            [self.getRobot beSad];
        }
        self.pathFindingSucceded = NO;
    }
    
    if( _showPathPlan ) {
        [self updatePathVisual];
    };
    [self followWayPoints];
    self.pathFindingOperation = nil;
}

- (void) followWayPoints {
    if( [self isRunning] && self.moveWayPointIndex < [self.moveWayPoints count] && self.moving) {
        GLKVector3 target;
        
        NSValue *value = [self.moveWayPoints objectAtIndex:self.moveWayPointIndex];
        [value getValue:&target];
        self.moveWayPointIndex++;

        // Check the ground distance to target.
        float groundDistance = [self groundDistanceToTarget:target];
        if( groundDistance < self.stoppingDistance && self.moveWayPointIndex == self.moveWayPoints.count ) {
            [self finishMoving];
        } else
        {
            float duration = ([self.moveTo durationToTarget:target] * self.moveSpeedModifier);
            
            be_NSDbg(@"Move to %.2f %.2f %.2f in %.2f seconds", target.x, target.y, target.z, duration);
            
            [self.moveTo runBehaviourFor:duration targetPosition:target callback:^{
                [self followWayPoints];
            }];
        }
    } else {
        [self finishMoving];
    }
}

- (void) finishMoving {
    [self clearPath];
    self.moving = NO;
    [self stopRunning];
}

/**
 * Calculate the ground distance to camera on X/Z plane.
 */
- (float) groundDistanceToTarget:(GLKVector3)target {
    GLKVector3 pos = [[self getRobot] getPosition];
    pos.y = 0;
    target.y = 0;
    float distance = GLKVector3Distance(pos, target);
    return distance;
}

#pragma mark - Path Visualization

- (void) initPath {

    SCNScene *widgets = [SCNScene sceneInFrameworkOrAppNamed:@"Widgets.dae"];
    SCNNode *pathfinder = [[widgets rootNode] childNodeWithName:@"DiamondSquarePin" recursively:YES];
    
    _pathGeo = pathfinder.geometry;
    _pathGeo.firstMaterial.diffuse.contents = [UIColor yellowColor];
    _pathGeo.firstMaterial.ambient.contents = [UIColor grayColor];

    self.pathParentNode = [[SCNNode alloc] init];
    [[Scene main].rootNode addChildNode:_pathParentNode];
        
    self.pathNodes = [NSMutableArray arrayWithCapacity:16];
}

- (void) deallocPath {
    for( SCNNode *node in _pathNodes ) {
        [node removeFromParentNode];
    }
    [_pathParentNode removeFromParentNode];
}

- (void) clearPath {
    if( _pathNodes.count > 0 ) {
        NSArray *pathNodes = [_pathNodes copy];
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1];
        [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
        for( SCNNode *node in pathNodes ) {
            node.scale = SCNVector3Zero;
        }
        [SCNTransaction setCompletionBlock:^{
            for( SCNNode *node in pathNodes ) {
                [node removeFromParentNode];
            }
        }];
        [SCNTransaction commit];
        
        [_pathNodes removeAllObjects];
    }
}

- (void) updatePathVisual {
    if( _pathFindingOperation == nil ) return;
    
    NSMutableArray *waypoints = [_pathFindingOperation.waypoints mutableCopy];

    // Add the start and end points.
    GLKVector3 vec3 = _pathFindingOperation.from;
    NSValue *val3 = [NSValue valueWithBytes:&vec3 objCType:@encode(GLKVector3)];
    [waypoints insertObject:val3 atIndex:0];

    vec3 = _pathFindingOperation.to;
    val3 = [NSValue valueWithBytes:&vec3 objCType:@encode(GLKVector3)];
    [waypoints addObject:val3];
    
    
    for( NSValue *waypoint in waypoints ) {
        GLKVector3 target;
        [waypoint getValue:&target];
        
        SCNNode *wpNode = [SCNNode nodeWithGeometry:_pathGeo];
        wpNode.categoryBitMask |= RAYCAST_IGNORE_BIT | BEShadowCategoryBitMaskCastShadowOntoSceneKit | BEShadowCategoryBitMaskCastShadowOntoEnvironment;
        wpNode.eulerAngles = SCNVector3Make(M_PI, 0, 0);
        SCNVector3 nodePos = SCNVector3FromGLKVector3(target);
        wpNode.position = nodePos;
        float scale =
            (waypoint == waypoints.firstObject
            || waypoint == waypoints.lastObject) ? 3 : 1;
        wpNode.scale = SCNVector3Make(scale, scale, scale);
        [_pathParentNode addChildNode:wpNode];
        [_pathNodes addObject:wpNode];
    }
}

@end
