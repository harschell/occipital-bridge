/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "BehaviourComponent.h"
#import "../../Core/EventComponentProtocol.h"
#import "../ButtonContainerComponent.h"

@interface BeamUIBehaviourComponent : BehaviourComponent <EventComponentProtocol>

@property (weak) ButtonContainerComponent * uiComponent;

@end
