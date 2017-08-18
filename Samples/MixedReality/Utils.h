//
//  Utils.h
//  MixedReality
//
//  Created by John Austin on 8/1/17.
//  Copyright © 2017 Occipital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameplayKit/GameplayKit.h>

@interface Utils : NSObject

+ (GLKQuaternion) SCNQuaternionMakeFromRotation:(GLKVector3)from to:(GLKVector3)dest;


// Creates a quaternion that rotates [0,0,1] to the give vector and up direction.
+ (GLKQuaternion)SCNQuaternionLookRotation:(GLKVector3)forward up:(GLKVector3)up;

@end
