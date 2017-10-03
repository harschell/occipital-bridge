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

@property (nonatomic, strong) SCNNode* ControllerNode;                     // the immediate node where the dae for the controller is stored
@property (nonatomic, strong) SCNNode* TriggerNode;
@property (nonatomic, strong) SCNNode* TouchNode;
@property (nonatomic, strong) SCNNode* HomeNode;
@property (nonatomic, strong) SCNNode* AppNode;

@end

@implementation BridgeControllerComponent{}

-(id) init
{
    self = [super init];
    if(self)
    {
        self.node = [SCNNode node];
        
        //get mesh for the controller
        SCNScene *bControllerScene =  [SCNScene sceneInFrameworkOrAppNamed:@"BridgeController-LightMap.scn"];
        self.ControllerNode = [[bControllerScene rootNode] childNodeWithName:@"Controller" recursively:YES];
        [self.ControllerNode setCategoryBitMaskRecursively:RAYCAST_IGNORE_BIT | BEShadowCategoryBitMaskCastShadowOntoSceneKit | BEShadowCategoryBitMaskCastShadowOntoEnvironment];
        [self.ControllerNode setEmissionRecursively:[UIColor colorWithWhite:0.1 alpha:1]];

        self.TriggerNode = [self.ControllerNode childNodeWithName:@"Trigger" recursively:YES];
        self.TouchNode = [self.ControllerNode childNodeWithName:@"Touch" recursively:YES];
        self.AppNode = [self.ControllerNode childNodeWithName:@"AppButton" recursively:YES];
        self.HomeNode = [self.ControllerNode childNodeWithName:@"HomeButton" recursively:YES];
        
        [self.node addChildNode:_ControllerNode];
        
        [[Scene main].rootNode addChildNode:self.node];
    }
    
    return self;
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

- (void) updateWithDeltaTime:(NSTimeInterval)seconds{
    [super updateWithDeltaTime:seconds];
    
    if (!self.isEnabled) {
        return;
    }

    BEController *controller = BEController.sharedController;
    BEControllerButtons buttons = controller.buttons;
    
    {
        BOOL triggerDown = (buttons & BEControllerButtonPrimary) != 0;
        _TriggerNode.geometry.firstMaterial.diffuse.contents = triggerDown ? UIColor.greenColor : UIColor.blackColor;
        _TriggerNode.geometry.firstMaterial.emission.contents = triggerDown ? UIColor.greenColor : UIColor.blackColor;
    }
    
    {
        BOOL appDown = (buttons & BEControllerButtonSecondary) != 0;
        _AppNode.geometry.firstMaterial.diffuse.contents = appDown ? UIColor.greenColor : UIColor.blackColor;
        _AppNode.geometry.firstMaterial.emission.contents = appDown ? UIColor.greenColor : UIColor.blackColor;
    }
    
    {
        BOOL homeDown = (buttons & BEControllerButtonHomePower) != 0;
        _HomeNode.geometry.firstMaterial.diffuse.contents = homeDown ? UIColor.greenColor : UIColor.blackColor;
        _HomeNode.geometry.firstMaterial.emission.contents = homeDown ? UIColor.greenColor : UIColor.blackColor;
    }
    
    // Update touch pad.
    if( controller.touchStatus == BECTouchIdle ) {
        _TouchNode.hidden = YES;
    } else {
        _TouchNode.hidden = NO;
        
        GLKVector2 position = controller.touchPosition;
        _TouchNode.position = SCNVector3Make( position.x, position.y, 0);
        
        BOOL touchPadDown = (buttons & BEControllerButtonTouchpad) != 0; 
        _TouchNode.geometry.firstMaterial.diffuse.contents = touchPadDown ? UIColor.greenColor : UIColor.yellowColor;
        _TouchNode.geometry.firstMaterial.emission.contents = touchPadDown ? UIColor.greenColor : UIColor.yellowColor;
    }

    self.node.transform = SCNMatrix4FromGLKMatrix4(controller.transform);
}
@end
