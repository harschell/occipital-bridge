/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "ViewController.h"

#import <BridgeEngine/BridgeEngine.h>

// The directory of our SceneKit assets
#define ASSETS_DIR "Assets.scnassets"

#pragma mark - ViewController ()

@interface ViewController () < BEMixedRealityModeDelegate >

@property (strong) SCNNode *  treeNode;
@property (strong) SCNNode * chairNode;
@property (strong) SCNNode *  giftNode;

@end

#pragma mark - ViewController

@implementation ViewController
{
    BEMixedRealityMode* _mixedReality;
    NSArray* _markupNameList;
    BOOL experienceIsRunning;
}

+ (SCNNode*) loadNodeNamed:(NSString*)nodeName fromSceneNamed:(NSString*)sceneName
{
    // Since -Y is up in Bridge Engine convention, this pivot rotates from the typical convention
    static const SCNMatrix4 defaultPivot = SCNMatrix4MakeRotation(M_PI, 1.0, 0.0, 0.0);
    
    SCNScene* scene = [SCNScene sceneNamed:sceneName];
    
    SCNNode* node  = [scene.rootNode childNodeWithName:nodeName recursively:YES];
    
    node.pivot = defaultPivot;
    
    return node;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Markup is optional physical annotations of a scanned scene, that persist between app launches
    // Here is a list of markup we'll use for our sample.
    // If the user decides, the locations of this markup will be saved on device.
    _markupNameList = @[ @"tree", @"chair", @"gift" ];
    
    _mixedReality = [[BEMixedRealityMode alloc]
                     initWithView:(BEView*)self.view
                     engineOptions:@{
                                     kBECaptureReplayEnabled:  @(getBooleanValueFromAppSettings(@"replayCapture"  , NO)),
                                     kBEUsingWideVisionLens: @(getBooleanValueFromAppSettings(@"useWVL"         , YES)),
                                     kBEStereoRenderingEnabled:@(getBooleanValueFromAppSettings(@"stereoRendering", YES)),
                                     }
                     markupNames:_markupNameList
                     ];
    
    _mixedReality.delegate = self;
    
    [_mixedReality start];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Here we initialize two gesture recognizers as a way to expose features
    
    // Create and initialize a tap gesture
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(handleTap:)];
    
    // Specify that the gesture must be a single tap
    tapRecognizer.numberOfTapsRequired = 1;
    
    // Add the tap gesture recognizer to the view
    [self.view addGestureRecognizer:tapRecognizer];
    
    
    // Create and initialize a double-tap gesture
    UITapGestureRecognizer *twoFingerTapRecognizer = [[UITapGestureRecognizer alloc]
                                                      initWithTarget:self action:@selector(handleTwoFingerTap:)];
    twoFingerTapRecognizer.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:twoFingerTapRecognizer];
    
}

- (void)setUpSceneKitWorlds:(BEStageLoadingStatus)stageLoadingStatus
{
    // When this function is called, it is guaranteed that the SceneKit world is set up, and any
    // previously-positioned markup nodes are loaded.
    
    // As this function is called from a rendering thread, perform only SceneKit updates here.
    // Avoid UIKit manipulation here (use main thread for UIKit).
    
    if (stageLoadingStatus == BEStageLoadingStatusNotFound)
    {
        NSLog(@"Your scene does not exist in the expected location on your device!");
        NSLog(@"You probably need to scan and export your local scene!");
        return;
    }
    
    // It is up to you whether you want to call startMarkupEditing
    // For this sample, we'll edit markup if any markup is missing from the given name list.
    bool foundAllMarkup = YES;
    for (id markupName in _markupNameList)
    {
        if (![_mixedReality markupNodeForName:markupName])
        {
            foundAllMarkup = NO;
            break;
        }
    }
    
    // If we have all the markup, let's directly begin the experience.
    // Otherwise, let's activate the markup editing UI.
    if (foundAllMarkup) [self startExperience];
    else                [_mixedReality startMarkupEditing];
    
    // Load assets here
    self.treeNode  = [[self class] loadNodeNamed:@"Tree"  fromSceneNamed:@ASSETS_DIR"/tree.dae"];
    self.chairNode = [[self class] loadNodeNamed:@"Chair" fromSceneNamed:@ASSETS_DIR"/chair.dae"];
    self.giftNode  = [[self class] loadNodeNamed:@"Gift"  fromSceneNamed:@ASSETS_DIR"/gift.dae"];
    
    // Add assets to the world node
    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.treeNode];
    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.chairNode];
    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.giftNode];
    
    // Hide all the objects initially (until markup positions them)
    [self.treeNode setHidden:YES];
    [self.chairNode setHidden:YES];
    [self.giftNode setHidden:YES];
    
    // Set any initial objects based on markup
    for (id markupName in _markupNameList)
        [self updateObjectPositionWithMarkupName:markupName];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)updateObjectPositionWithMarkupName:(NSString*)markupName
{
    // Here, we're using markup to set the location of static objects.
    
    // However, you could do something much more sophisticated, like have multiple markup points be
    // waypoints for a virtual character.
    
    SCNNode * markupNode = [_mixedReality markupNodeForName:markupName];
    
    // Early-return if this markup node hasn't been positioned yet.
    if (!markupNode) return;
    
    SCNNode * objectNode = nil;
    
    if ([markupName isEqualToString: @"tree"])
    {
        objectNode = self.treeNode;
        objectNode.scale = SCNVector3Make(0.2f, 0.2f, 0.2f);
        objectNode.position = markupNode.position;
        objectNode.eulerAngles = markupNode.eulerAngles;
    }
    else if ([markupName isEqualToString: @"chair"])
    {
        objectNode = self.chairNode;
        objectNode.transform = markupNode.transform;
    }
    else if ([markupName isEqualToString: @"gift"])
    {
        // The gift's rotation will be determined in updateAtTime
        objectNode = self.giftNode;
        objectNode.position = markupNode.position;
    }
    
    // Regardless of which object was moved, let's set it visible now.
    objectNode.hidden = NO;
}

- (void)startExperience
{
    // For this experience, let's switch to a mode with AR objects composited with the passthrough camera.
    [_mixedReality setRenderStyle:BERenderStyleSceneKitAndColorCamera withDuration:0.5];
    experienceIsRunning = YES;
}

- (void)markupEditingEnded
{
    // If markup editing is over, then any experience in the scene may be started.
    [self startExperience];
}

- (void)markupDidChange:(NSString*)markupChangedName
{
    // In this sample, markup and objects are 1:1, so we simply update the object position
    // accordingly when a markup position changes.
    
    [self updateObjectPositionWithMarkupName:markupChangedName];
}

- (void) trackingStateChanged:(BETrackingState)trackingState
{
    if (trackingState == BETrackingStateNominal)
        NSLog(@"trackingStateChanged: BETrackingStateNominal");
    if (trackingState == BETrackingStateNotTracking)
        NSLog(@"trackingStateChanged: BETrackingStateNotTracking");
}

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    //An example of what to do when the user taps
    // Even though the gift's location is set by markup at the start of the experience,
    // We're showing off tapping moving it around.
    
    CGPoint tapPoint = [sender locationInView:self.view];
    
    SCNVector3 meshNormal {NAN, NAN, NAN};
    SCNVector3 mesh3DPoint = [_mixedReality mesh3DFrom2DPoint:tapPoint outputNormal:&meshNormal];
    
    NSLog(@"Bridge Engine Sample handleTap %@", NSStringFromCGPoint(tapPoint));
    NSLog(@"\t mesh3DPoint %f,%f,%f", mesh3DPoint.x, mesh3DPoint.y, mesh3DPoint.z);
    
    self.giftNode.position = mesh3DPoint;
}

- (void)handleTwoFingerTap:(UITapGestureRecognizer *)sender
{
    // Increment through render styles. Sweet fade.
    
    BERenderStyle renderStyle = [_mixedReality getRenderStyle];
    BERenderStyle nextRenderStyle = (BERenderStyle) ((renderStyle + 1) % NumBERenderStyles);
    [_mixedReality setRenderStyle:nextRenderStyle withDuration:0.5];
}

- (void)updateAtTime:(NSTimeInterval)time
{
    // Called each frame before render. It is safe to move SceneKit objects here.
    
    static NSTimeInterval lastUpdateTime = NAN;
    
    if (!isnan(lastUpdateTime))
    {
        float deltaTime = (time - lastUpdateTime);
        
        // Only spin the gift once our experience begins (after markup complete)
        
        if(experienceIsRunning)
        {
            const float SPINNY_GIFT_RATE = 0.5; // rad/sec
            
            SCNVector3 currentEuler = self.giftNode.eulerAngles;
            currentEuler.y += SPINNY_GIFT_RATE * deltaTime;
            
            self.giftNode.eulerAngles = currentEuler;
        }
    }
    
    // TODO: Here, you could control an interaction using the location of the device.
    
    //  SCNNode *localDeviceNode = _mixedReality.localDeviceNode;
    //  NSLog(@"localDeviceNode position: [%f,%f,%f]", localDeviceNode.position.x, localDeviceNode.position.y, localDeviceNode.position.z);
    
    lastUpdateTime = time;
}

@end
