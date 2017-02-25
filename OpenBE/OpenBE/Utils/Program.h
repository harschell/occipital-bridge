/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <SceneKit/SceneKit.h>

@interface Program : NSObject

+ (SCNProgram *)createProgramWithShader:(NSString *)shaderName;

@end
