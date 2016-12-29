/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/GeometryComponent.h"

@interface ButtonContainerComponent : GeometryComponent <ComponentProtocol>
@property (strong) NSMutableArray * buttonComponents;

- (int) activeButtonsCount;

@end
