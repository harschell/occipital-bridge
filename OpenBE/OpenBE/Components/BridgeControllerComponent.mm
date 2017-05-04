/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */
 
#import "BridgeControllerComponent.h"
#import "OpenBE/Core/Core.h"
#import "OpenBE/Utils/SceneKitExtensions.h"
#import "OpenBE/Utils/SceneKitTools.h"
#import "OpenBE/Core/AudioEngine.h"

typedef void (^callback)(void);

@interface BridgeControllerComponent()
@property (strong) callback callbackBlock;

@property (nonatomic, strong) SCNMaterial *TriggerMaterial;
@property (nonatomic, strong) SCNMaterial *MainBodyMaterial;
@property (nonatomic, strong) SCNMaterial *BackButtonMaterial;
@property (nonatomic, strong) SCNMaterial *StartButtonMaterial;
@property (nonatomic, strong) SCNMaterial *TrackPadTopMaterial;
@property (nonatomic, strong) SCNMaterial *TrackPadLeftMaterial;
@property (nonatomic, strong) SCNMaterial *TrackPadRightMaterial;
@property (nonatomic, strong) SCNMaterial *TrackPadCenterMaterial;
@property (nonatomic, strong) SCNMaterial *TrackPadBottomMaterial;

@property (nonatomic, strong) SCNNode* TriggerNode;
@property (nonatomic, strong) SCNNode* MainBodyNode;
@property (nonatomic, strong) SCNNode* BackButtonNode;
@property (nonatomic, strong) SCNNode* StartButtonNode;
@property (nonatomic, strong) SCNNode* TrackPadCenterNode;

@property (nonatomic, strong) SCNNode* ControllerNode;                     // the immediate node where the dae for the controller is stored
@end

@implementation BridgeControllerComponent{}

SCNQuaternion ControllerOrientation;
// storing local button presses
bool TriggerButtonDown;
bool BackButtonDown;
bool StartButtonDown;
bool TrackPadTopButtonDown;
bool TrackPadLeftButtonDown;
bool TrackPadRightButtonDown;
bool TrackPadCenterButtonDown;
bool TrackPadBottomButtonDown;
float TrackPadX;
float TrackPadY;

-(id) initWithBlock:(void (^)(void))callbackBlock
{
    self = [super init];
    if(self)
    {
        self.callbackBlock = callbackBlock;
        
        self.node = [SCNNode node];
        [[Scene main].rootNode addChildNode:self.node];
        
        //get mesh for the controller
        SCNScene *bControllerScene =  [SCNScene sceneInFrameworkOrAppNamed:@"BridgeController2.scn"];
        self.ControllerNode = [[bControllerScene rootNode] childNodeWithName:@"Controller" recursively:YES];
        [self.ControllerNode setCategoryBitMaskRecursively:RAYCAST_IGNORE_BIT | BEShadowCategoryBitMaskCastShadowOntoSceneKit | BEShadowCategoryBitMaskCastShadowOntoEnvironment];
        [self.ControllerNode setScale:SCNVector3Make(0.1f, 0.1f, 0.1f)];
        self.ControllerNode.eulerAngles = SCNVector3Make(M_PI, 0, 0); // Flip controller onto its belly.

        self.TriggerNode = [self.ControllerNode childNodeWithName:@"Trigger_Mesh" recursively:YES];
        self.MainBodyNode = [self.ControllerNode childNodeWithName:@"MainBody_Mesh" recursively:YES];
        self.BackButtonNode = [self.ControllerNode childNodeWithName:@"BackButton_Mesh" recursively:YES];
        self.StartButtonNode = [self.ControllerNode childNodeWithName:@"StartButton_Mesh" recursively:YES];
        self.TrackPadCenterNode = [self.ControllerNode childNodeWithName:@"TrackPad_Center_Mesh" recursively:YES];
        self.TriggerMaterial = [self.TriggerNode geometry].firstMaterial;
        self.MainBodyMaterial = [self.MainBodyNode geometry].firstMaterial;
        [self.MainBodyMaterial.emission setContents:[UIColor grayColor]];
        self.BackButtonMaterial = [self.BackButtonNode geometry].firstMaterial;
        self.StartButtonMaterial = [self.StartButtonNode geometry].firstMaterial;
        self.TrackPadCenterMaterial = [self.TrackPadCenterNode geometry].firstMaterial;
        
        [self.node addChildNode:_ControllerNode];
        
        [[Scene main].rootNode addChildNode:self.node];
    }
    return self;
}

- (void) setDepthTesting:(BOOL)doDepthTest
{
    [self.TriggerMaterial setWritesToDepthBuffer:doDepthTest];
    [self.MainBodyMaterial setWritesToDepthBuffer:doDepthTest];
    [self.BackButtonMaterial setWritesToDepthBuffer:doDepthTest];
    [self.StartButtonMaterial  setWritesToDepthBuffer:doDepthTest];
    [self.TrackPadTopMaterial  setWritesToDepthBuffer:doDepthTest];
    [self.TrackPadLeftMaterial  setWritesToDepthBuffer:doDepthTest];
    [self.TrackPadRightMaterial  setWritesToDepthBuffer:doDepthTest];
    [self.TrackPadCenterMaterial  setWritesToDepthBuffer:doDepthTest];
    [self.TrackPadBottomMaterial  setWritesToDepthBuffer:doDepthTest];
}


- (void) start{
    [super start];
}

- (void) setEnabled:(bool)enabled{
    [super setEnabled:enabled];
}

- (bool) isEnabled{
    return [super isEnabled];
}

- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit{
    return NO;
}

- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit{
    return NO;
}

- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit{
    return NO;
}

- (bool) touchCancelledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit{
    return NO;
}

- (bool) handleMotionTransform:(GLKMatrix4)transform{
    self.node.transform = SCNMatrix4FromGLKMatrix4(transform);
    return YES;
}

- (void) pressStartButton:(BOOL) press{
    StartButtonDown = press;
}

- (void) pressBackButton:(BOOL) press{
    BackButtonDown = press;
}

- (void) pressPadButton:(BOOL) press{
    TrackPadCenterButtonDown = press;
    
}
- (void) pressTriggerButton:(BOOL) press{
    TriggerButtonDown = press;
}

- (void) handleTouchpadPositionX:(float)x positionY:(float)y{
    if(x > -1)
        TrackPadX = x;
    else
        TrackPadX = 0;
    if(y < 1)
        TrackPadY = y;
    else
        TrackPadY = 0;
}

- (void) handleControllerTriggerDown:(BOOL) down{
    self.TriggerMaterial.emission.contents = down? [UIColor greenColor] : [UIColor grayColor];
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds{
    [super updateWithDeltaTime:seconds];

    // handle if buttons were pressed
    [self.TrackPadCenterNode setPosition:SCNVector3Make(TrackPadX * 0.133f, TrackPadY * 0.133f, 0)];
    self.StartButtonMaterial.emission.contents = StartButtonDown ? [UIColor greenColor] : [UIColor grayColor];
    
    self.BackButtonMaterial.emission.contents = BackButtonDown ? [UIColor redColor] : [UIColor grayColor];
    //self.TriggerMaterial.emission.contents = TriggerButtonDown? [UIColor greenColor] : [UIColor grayColor];
    self.TrackPadCenterMaterial.emission.contents = TrackPadCenterButtonDown ? [UIColor greenColor] : (fabsf(TrackPadX + TrackPadY) > .0f) ? [UIColor yellowColor] : [UIColor grayColor];
}
@end
