/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@class PathFinding;

@interface PathFindingOperation : NSOperation
@property(nonatomic) GLKVector3 from;
@property(nonatomic) GLKVector3 to;
@property(nonatomic) BOOL closest;

@property(nonatomic, strong) NSMutableArray * waypoints;

@end

@interface PathFinding : NSObject

/**
 * Check if the target location is occupied.
 */
- (BOOL) occupied:(GLKVector3)target;

///**
// * Find the nearest reachable location from the target value, from a given origin.
// * @returns nearest reachable or origin itself.
// */
//- (GLKVector3) nearestReachableTo:(GLKVector3)target fromOrigin:(GLKVector3)origin;

- (PathFindingOperation*) findPath:(GLKVector3)from to:(GLKVector3)to completion:(void (^)(void))completionBlock;

- (PathFindingOperation*) findNearestPath:(GLKVector3)from to:(GLKVector3)to completion:(void (^)(void))completionBlock;

/**
 * Get the physical size of each occupied grid pixel.
 */
- (float) pixelSizeInMeters;

/**
 * Create a string value of the point in x,y grid space for logging purposes:
 * ex: (23, 34)
 */
- (NSString*) stringForPoint:(GLKVector3)pt;

/**
 * Generate an array of occupied points in world coordinate.
 * @returns Array of NSValue of GLKVector3 data - [NSValue valueWithBytes:&p objCType:@@encode(GLKVector3)]
 */
- (NSMutableArray<NSValue*> *) occupiedPoints;

/**
 * Generate an array of connected component points.
 * @returns Array of NSValue of GLKVector3 data
 *     Coordinates x&z in world coordinates, and y being the comonent value.
 */
- (NSMutableArray<NSValue*> *) connectedComponentPoints;

/**
 * Search through the connected components, finding the largest slab of it.
 * @return the component id.
 */
- (unsigned char) largestConnectedComponent;

/**
 * Searchs the connectedComponentMap for nearest reachable goal point in component.
 * @param goalPoint goal we're trying to get to
 * @param targetComponent component that is being searched
 * @param result If successfull result is stored here
 * @return Success if a valid nearest point is found.
 */ 
- (BOOL) closestAccessiblePointTo:(GLKVector3)goalPoint inComponent:(unsigned char)targetComponent result:(GLKVector3*)result;

/**
 * Searchs the connectedComponentMap for nearest reachable goal point to a source point.
 * @param goalPoint goal we're trying to get to
 * @param sourcePoint where we're starting from
 * @param result If successfull result is stored here
 * @return Success if a valid nearest point is found.
 */ 
- (BOOL) closestAccessiblePointTo:(GLKVector3)goalPoint fromPoint:(GLKVector3)sourcePoint result:(GLKVector3*)result;

@end
