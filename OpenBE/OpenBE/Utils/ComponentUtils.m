/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "ComponentUtils.h"

@implementation ComponentUtils

+ (GKComponent *) getComponentFromEntity:(GKEntity *)entity ofClass:(Class)aClass {
    GKComponent * ret = NULL;
    int counter = 0;
    
    for( GKComponent* component in entity.components ) {
        if( [component isKindOfClass:aClass] ) {
            ret = component;
            // todo, return first hit
            // but while developing see if there are more components of this class.
            // If so: this is probably a bug
            counter ++;
        }
    }
    
    if( counter > 1 ) {
        NSLog(@"Error, more then one component of class %@", aClass);
    }
    return ret;
}

+ (NSMutableArray *) getComponentsFromEntity:(GKEntity *)entity ofClass:(Class)aClass {
    NSMutableArray * ret = [[NSMutableArray alloc] initWithCapacity:8];
    
    for( GKComponent* component in entity.components ) {
        if( [component isKindOfClass:aClass] ) {
            [ret addObject:component];
        }
    }
    
    return ret;
}



+ (GKComponent *) getComponentFromEntity:(GKEntity *)entity ofProtocol:(Protocol *)aProtocol {
    GKComponent * ret = NULL;
    int counter = 0;
    
    for( GKComponent* component in entity.components ) {
        if( [component conformsToProtocol:aProtocol] ) {
            ret = component;
            // todo, return first hit
            // but while developing see if there are more components of this protocol.
            // If so: this is probably a bug
            counter ++;
        }
    }
    if( counter > 1 ) {
        NSLog(@"Error, more then one component of protocol %@", aProtocol);
    }
    return ret;
}

+ (NSMutableArray *) getComponentsFromEntity:(GKEntity *)entity ofProtocol:(Protocol *)aProtocol {
    NSMutableArray * ret = [[NSMutableArray alloc] initWithCapacity:8];
    
    for( GKComponent* component in entity.components ) {
        if( [component conformsToProtocol:aProtocol] ) {
            [ret addObject:component];
        }
    }
    return ret;
}

@end
