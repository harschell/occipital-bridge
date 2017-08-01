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

@end
