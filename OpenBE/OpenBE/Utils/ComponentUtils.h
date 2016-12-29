/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GameplayKit/GameplayKit.h>

@interface ComponentUtils : NSObject

+ (GKComponent *) getComponentFromEntity:(GKEntity *)entity ofClass:(Class)aClass;
+ (NSMutableArray *) getComponentsFromEntity:(GKEntity *)entity ofClass:(Class)aClass;

+ (GKComponent *) getComponentFromEntity:(GKEntity *)entity ofProtocol:(Protocol *)aProtocol;
+ (NSMutableArray *) getComponentsFromEntity:(GKEntity *)entity ofProtocol:(Protocol *)aProtocol;

@end
