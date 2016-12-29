/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/EventComponentProtocol.h"
#import "../Core/ComponentProtocol.h"
#import "../Core/GeometryComponent.h"
#import <JavascriptCore/JavascriptCore.h>

@protocol ButtonComponentJSExports <JSExport>
@property(nonatomic, getter=isEnabled) bool enabled;
@end

@interface ButtonComponent : GeometryComponent <EventComponentProtocol, ComponentProtocol>

@property(nonatomic, strong) SCNMaterial *frontMaterial;

- (id) initWithImage:(NSString *)imageName andBlock:(void (^)(void))callbackBlock;
- (void) setDepthTesting:(BOOL)doDepthTest;

@end
