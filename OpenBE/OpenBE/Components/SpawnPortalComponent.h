/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/Component.h"
#import "../Core/EventComponentProtocol.h"
#import "PortalComponent.h"

@class RobotActionComponent;

@interface SpawnPortalComponent : Component <EventComponentProtocol, ComponentProtocol>

@property (nonatomic, weak) PortalComponent *portalComponent;
@property (nonatomic, weak) VRWorldComponent *vrWorldComponent;
@property (nonatomic, weak) RobotActionComponent *robotActionSequencer;

@end
