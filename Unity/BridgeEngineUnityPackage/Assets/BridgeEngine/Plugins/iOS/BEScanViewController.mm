/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "BEScanViewController.h"
#import "BridgeEngineUnity.h"
#import "BridgeEngineAppController.h"

#import <BridgeEngine/BridgeEngine.h>
#import <BridgeEngine/BEAppSettings.h>

@interface BEScanViewController () <BEMixedRealityModeDelegate>

@property(nonatomic, strong) BEMixedRealityMode* mixedReality;

@end

@implementation BEScanViewController {
}

- (void) loadView {
    BEView *beView = [[BEView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.view = beView;

    BECaptureReplayMode replayMode = BECaptureReplayModeDisabled;
    if ([BEAppSettings booleanValueFromAppSetting:SETTING_REPLAY_CAPTURE   defaultValueIfSettingIsNotInBundle:NO])
    {
        replayMode = BECaptureReplayModeRealTime;
    }

    bool useStereo = [BEAppSettings booleanValueFromAppSetting:SETTING_STEREO defaultValueIfSettingIsNotInBundle:YES];

    NSDictionary *options = @{
                              kBECaptureReplayMode:  @(replayMode),
                              kBEUsingWideVisionLens:   @([BEAppSettings booleanValueFromAppSetting:SETTING_USE_WVL defaultValueIfSettingIsNotInBundle:YES]),
                              kBEStereoRenderingEnabled: @(useStereo),
                              kBEEnableStereoScanningBeta: @(useStereo),
                              kBEUsingColorCameraOnly:  @NO,
                              };
    
    EAGLContext *unityContext = UnityGetDataContextEAGL();
    
    _mixedReality = [[BEMixedRealityMode alloc]
                     initWithView:beView
                     engineOptions:options
                     markupNames:nil
                     eaglSharegroup:[unityContext sharegroup]
                     ];
    
    _mixedReality.delegate = self;
    
    [_mixedReality start];
}

- (void) disconnectFromBE {
    _mixedReality.delegate = nil;
    self.mixedReality = nil;
}

- (void) dealloc {
    [self disconnectFromBE];
    self.view = nil;
}

#pragma mark - BEMixedRealityModeDelegate

/**
 * Use the mixedRealitySetUpSceneKitWorlds as a "done scanning" trigger for continuing onto the Unity environment.
 */
- (void) mixedRealitySetUpSceneKitWorlds:(BEMappedAreaStatus)mappedAreaStatus {
    if( mappedAreaStatus == BEMappedAreaStatusLoaded ) {
        if( self.delegate ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate scanViewDidFinish];
            });
        }
    }
}

- (void)mixedRealityMarkupDidChange:(NSString*)markupChangedName {}

- (void)mixedRealityMarkupEditingEnded {}

- (void)mixedRealityUpdateAtTime:(NSTimeInterval)time {}

@end
