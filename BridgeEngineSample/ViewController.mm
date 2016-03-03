/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#import "ViewController.h"

#import <BridgeEngine/BridgeEngine.h>

//------------------------------------------------------------------------------

//the directory of our SceneKit assets
#define ASSETS_DIR "Assets.scnassets"

//------------------------------------------------------------------------------

@interface ViewController () < BEMixedRealityModeDelegate >

@property (strong) SCNNode *  treeNode;
@property (strong) SCNNode * chairNode;
@property (strong) SCNNode *  giftNode;

@end

//------------------------------------------------------------------------------

@implementation ViewController
{
    BEMixedRealityMode* _mixedReality;
    NSArray* _markupNameList;
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


    // tryToLoadScene should be called in viewDidAppear, not viewDidLoad
    [_mixedReality tryToLoadScene];
}

- (void)sceneDidLoad:(BOOL)success
{
    //sceneDidLoad is called with the result of the Bridge Engine attempting to load the scene geometry.
    
    if (success)
    {
        //Load saved markup from device here.
        //Currently, this must be called before start is called because we will then instantinate the markup nodes.
        NSArray *markupNamesLoaded = [_mixedReality tryLoadingMarkup];
        //It is up to you whether you want to call startMarkupEditing
        //For this sample, we'll edit markup if any markup is missing from the given name list.
        bool foundAllMarkup = YES;
        for (id markupName in _markupNameList)
        {
            if (![markupNamesLoaded containsObject:markupName])
            {
                foundAllMarkup = NO;
                break;
            }
        }
        if (!foundAllMarkup)
            [_mixedReality startMarkupEditing]; //spawns the markup editing view and mode
        
        
        //this call starts the engine running
        [_mixedReality start];
    }
    else
    {
        NSLog(@"Your scene does not exist in the expected location on your device!");
        NSLog(@"You probably need to scan and export your local scene!");
    }
}

- (void)setupSceneKitWorlds
{
    //When this function is called, it is guaranteed that the SceneKit world is set up, and any markup nodes are loaded.
    //As this function is called from the SceneKit thread, only do SceneKit stuff here -
    // Do not do anything related to UIKit
    
    // Load assets here
    self.treeNode  = [[self class] loadNodeNamed:@"Tree"  fromSceneNamed:@ASSETS_DIR"/tree.dae"];
    self.chairNode = [[self class] loadNodeNamed:@"Chair" fromSceneNamed:@ASSETS_DIR"/chair.dae"];
    self.giftNode  = [[self class] loadNodeNamed:@"Gift"  fromSceneNamed:@ASSETS_DIR"/gift.dae"];
    
    //add assets to SceneKit node hierarchy
    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.treeNode];
    [self.treeNode setScale:SCNVector3Make(0.2f,0.2f,0.2f)];
    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.chairNode];
    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.giftNode];
    
    //set any initial objects based on markup
    for (id markupName in _markupNameList)
        [self markupUpdated:markupName];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)markupUpdated:(NSString*)markupUpdatedName
{
    //Here is a demonstration of a function called from a few different locations with a given markup name.
    //Given the markup name, we may write our own logic to update our environment based on it.
    //In this sample, we're only setting the location of static objects.
    //However, you could do something much more sophisticated, like have multiple markup points be waypoints for a virtual character.
    
    
    //The possible relationships between objects and markup is shown in a couple ways here
    
    if ([markupUpdatedName isEqual: @"tree"])
    {
        self.treeNode.position = [_mixedReality markupNodeForName:markupUpdatedName].position;
        self.treeNode.eulerAngles = [_mixedReality markupNodeForName:markupUpdatedName].eulerAngles;
    }
    else if ([markupUpdatedName isEqual: @"chair"])
    {
        self.chairNode.transform = [_mixedReality markupNodeForName:markupUpdatedName].transform;
    }
    else if ([markupUpdatedName isEqual: @"gift"])
    {
        self.giftNode.position = [_mixedReality markupNodeForName:markupUpdatedName].position;
        //gift's euler angles will be determined by updateAtTime
    }
}

- (void)markupEditingEnded
{
    // called from the BEMixedRealityModeDelegate
    
    // if markup editing is over, then any experience in the scene may be started.
    
    //should set markup once editing is ended
    for (id markupName in _markupNameList)
        [self markupUpdated:markupName];
}

- (void)markupDidChange:(NSString*)markupChangedName
{
    // called from the BEMixedRealityModeDelegate
    // we funnel this event into our sample markup logic
    [self markupUpdated:markupChangedName];
}

- (void) trackingStateChanged:(BETrackingState)trackingState
{
    if (trackingState == BETrackingStateNominal)
        NSLog(@"trackingStateChanged: BETrackingNominal");
    if (trackingState == BETrackingStateNot)
        NSLog(@"trackingStateChanged: BETrackingNot");
}

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    //An example of what to do when the user taps
    // Even though the gift's location is set by markup at the start of the experience,
    // We're showing off tapping moving it around.
    
    CGPoint tapPoint = [sender locationInView:self.view];
    
    SCNVector3 meshNormal {NAN, NAN, NAN};
    SCNVector3 mesh3DPoint = [_mixedReality mesh3DFrom2DPoint:tapPoint outputNormal:&meshNormal];
    
    NSLog(@"Bridge Sample handleTap %@", NSStringFromCGPoint(tapPoint));
    NSLog(@"\t mesh3DPoint %f,%f,%f", mesh3DPoint.x, mesh3DPoint.y, mesh3DPoint.z);
    
    self.giftNode.position = mesh3DPoint;
}

- (void)handleTwoFingerTap:(UITapGestureRecognizer *)sender
{
    //Increment through render styles. Sweet fade.
    
    BERenderStyle renderStyle = [_mixedReality getRenderStyle];
    BERenderStyle nextRenderStyle = (BERenderStyle) ((renderStyle + 1) % NumBERenderStyles);
    [_mixedReality changeRenderStyle:nextRenderStyle withDuration:1.0];
    
}

- (void)updateAtTime:(NSTimeInterval)time
{
    //Called each frame before render. It is safe to move SceneKit objects here.
    
    static NSTimeInterval lastUpdateTime = NAN;
    
    if (!isnan(lastUpdateTime))
    {
        float deltaTime = (time - lastUpdateTime);
        
        const float SPINNY_GIFT_RATE = 0.5; // rad/sec
        
        SCNVector3 currentEuler = self.giftNode.eulerAngles;
        currentEuler.y += SPINNY_GIFT_RATE * deltaTime;
        
        self.giftNode.eulerAngles = currentEuler;
        
    }
    
    
//    SCNNode *localBridge = _mixedReality.localBridge;
//    NSLog(@"localBridge position: [%f,%f,%f]", localBridge.position.x, localBridge.position.y, localBridge.position.z);
    //TODO: you could do some interaction with the location of the device running the bridge engine.
    
    lastUpdateTime = time;
}

@end

//------------------------------------------------------------------------------
