/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "Scene.h"


@implementation Scene

+ (Scene *) main {
    static Scene *mainScene;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainScene = [[Scene alloc] init];
    });
    
    return mainScene;
}

- (SCNNode *) rootNodeForGaze {
    if( !_rootNodeForGaze && self.rootNode ) {
        _rootNodeForGaze = [SCNNode node];
        [self.rootNode addChildNode:_rootNodeForGaze];
    }
    return _rootNodeForGaze;
}

@end
