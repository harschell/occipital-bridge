//
// Created by John Austin on 7/17/17.
// Copyright (c) 2017 Occipital. All rights reserved.
//

#include <Foundation/Foundation.h>
#import "Component.h"
#import "EventComponentProtocol.h"
#import "OutsideWorldComponent.h"

@interface OpenWindowComponent : Component <EventComponentProtocol, ComponentProtocol>

@property (nonatomic, weak) OutsideWorldComponent *outsideComponent;
@property (nonatomic, weak) BEMixedRealityMode *mixedReality;

@end