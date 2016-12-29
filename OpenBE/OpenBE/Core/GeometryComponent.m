/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "GeometryComponent.h"
#import "Core.h"

@implementation GeometryComponent


- (id) initWithNode:(SCNNode *) node
{
    self = [super init];
    [self registerNodeToEntity:node];
    
    return self;
}

- (void) start {
    [super start];
    [self registerNodeToEntity:self.node];
}

- (void) setEnabled:(bool)enabled {
    [super setEnabled:enabled];
    
    self.node.hidden = ![self isEnabled];
}

- (void) registerNodeToEntity:(SCNNode *) node {
    self.node = node;
    [node setValue:self.entity forKey:@"entity"];
    
    if( !self.node.parentNode ) {
        [[Scene main].rootNode addChildNode:self.node];
    }
}

- (SCNNode *) createSceneNode {
    self.node = [SCNNode node];
    [[Scene main].rootNode addChildNode:self.node];
    
    [self registerNodeToEntity:self.node];
    
    return self.node;
}

- (SCNNode *) createSceneNodeForGaze {
    self.node = [SCNNode node];
    [[Scene main].rootNodeForGaze addChildNode:self.node];
    
    [self registerNodeToEntity:self.node];
    
    return self.node;
}

@end
