/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "ButtonComponent.h"
#import "../Core/Core.h"
#import "../Utils/SceneKitExtensions.h"
#import "../Core/AudioEngine.h"

typedef void (^callback)(void);

@interface ButtonComponent()
@property (strong) callback callbackBlock;
@property(nonatomic, strong) AudioNode *buttonClickSound;
@end

@implementation ButtonComponent

- (id) initWithImage:(NSString *)imageName andBlock:(void (^)(void))callbackBlock {
    self = [super init];    
    
    [self createButton:imageName];
    
    self.callbackBlock = callbackBlock;
    
    self.buttonClickSound = [[AudioEngine main] loadAudioNamed:@"Robot_MenuClick.caf"];
    
    return self;
}

- (void) setDepthTesting:(BOOL)doDepthTest
{
    _frontMaterial.writesToDepthBuffer = doDepthTest;
    _frontMaterial.readsFromDepthBuffer = doDepthTest;
}


- (void) setImage:(NSString *)imageName
{
    _frontMaterial.lightingModelName = SCNLightingModelBlinn;
    
    // that texture map is upside down and backwards compared to the actual png image
    [_frontMaterial.diffuse  setContents:imageName];
    _frontMaterial.diffuse.contentsTransform = SCNMatrix4Scale(SCNMatrix4Identity, -1, -1, 1);
    _frontMaterial.diffuse.wrapS = SCNWrapModeRepeat;
    _frontMaterial.diffuse.wrapT = SCNWrapModeRepeat;
    _frontMaterial.diffuse.mipFilter = SCNFilterModeLinear;
    
    [_frontMaterial.emission setContents:imageName];
    _frontMaterial.emission.contentsTransform = SCNMatrix4Scale(SCNMatrix4Identity, -1, -1, 1);
    _frontMaterial.emission.wrapS = SCNWrapModeRepeat;
    _frontMaterial.emission.wrapT = SCNWrapModeRepeat;
    _frontMaterial.emission.mipFilter = SCNFilterModeLinear;
    _frontMaterial.emission.intensity = 2;
    
    _frontMaterial.litPerPixel = NO;
    _frontMaterial.readsFromDepthBuffer = NO;
    _frontMaterial.blendMode = SCNBlendModeAlpha;
    _frontMaterial.transparencyMode = SCNTransparencyModeAOne;
    
    // I would rather have one textured plane, rendering front and back side.
    // but setting this doesn't seem to work correctly in iOS 9. Only iOS 10.
    //_frontMaterial.doubleSided = YES;
}

- (void) createButton:(NSString *)imageName {
    self.node = [self createSceneNodeForGaze];
    
    self.node.geometry = [SCNBox boxWithWidth:1. height:1. length:.05 chamferRadius:0];
    _frontMaterial = [SCNMaterial material];

    [self setImage:imageName];
    
    SCNMaterial * otherMaterial = [SCNMaterial material];
    otherMaterial.diffuse.contents = [UIColor clearColor];
    
    self.node.geometry.materials = @[_frontMaterial, otherMaterial,_frontMaterial, otherMaterial, otherMaterial, otherMaterial];
    
    // wanted to make sure the buttons are rendered AFTER everything in the scene.
    // however the beam is not respecting depth buffer drawing state so we have to draw if before the beam.
    // This has little effect because both items are transparent.
    self.node.renderingOrder = TRANSPARENCY_RENDERING_ORDER + 80;

    [self.node setCastsShadowRecursively:NO];
}

- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    if( self.callbackBlock ) {
        return YES;
    }
    return NO;
}

- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    if( self.callbackBlock ) {
        self.callbackBlock();
        [self.buttonClickSound play];
        return YES;
    }
    
    return NO;
}

- (bool) touchCanceledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

@end
