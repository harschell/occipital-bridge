/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/EventComponentProtocol.h"
#import "../Core/ComponentProtocol.h"
#import "../Core/Component.h"
#import "RobotBehaviourComponent.h"

@interface ScanEventComponent : Component <ComponentProtocol, EventComponentProtocol>

@property (nonatomic, strong) RobotBehaviourComponent * robotBehaviourComponent;

@end
