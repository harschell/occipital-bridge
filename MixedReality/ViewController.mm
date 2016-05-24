/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#import "ViewController.h"
#import "AppSettings.h"
#import <BridgeEngine/BridgeEngine.h>
#import <cassert>

//------------------------------------------------------------------------------

#define ASSETS_DIR "Assets.scnassets" // The SceneKit assets root folder.

// Since -Y is up in Bridge Engine convention, the pivot rotates from the typical convention.

static const SCNMatrix4 defaultPivot = SCNMatrix4MakeRotation(M_PI, 1.0, 0.0, 0.0);

//------------------------------------------------------------------------------

#pragma mark - ViewController ()

@interface ViewController () < BEMixedRealityModeDelegate >

@property (strong) SCNNode *  treeNode;
@property (strong) SCNNode * chairNode;
@property (strong) SCNNode *  giftNode;

@property (strong) SCNNode *  highlightNode;

@end

//------------------------------------------------------------------------------

#pragma mark - ViewController

@implementation ViewController
{
    BEMixedRealityMode* _mixedReality;
    NSArray*            _markupNameList;
    BOOL                _experienceIsRunning;
}

+ (SCNNode*) loadNodeNamed:(NSString*)nodeName fromSceneNamed:(NSString*)sceneName
{
    SCNScene* scene = [SCNScene sceneNamed:sceneName];
    if (!scene)
    {
        NSLog(@"Could not load scene named: %@", sceneName);
        assert(scene);
    }
        
    SCNNode* node  = [scene.rootNode childNodeWithName:nodeName recursively:YES];
    if (!node)
    {
        NSLog(@"Could not find node (%@) in scene named: %@\nHere's all the nodes I could find in the scene:\n", nodeName, sceneName);
        [self printSceneNodes:scene.rootNode];
        assert(node);
    }

    node.pivot = defaultPivot;

    return node;
}

+ (void) printSceneNodes:(SCNNode*)rootNode
{
    [self printSceneNodes:rootNode withLevel:0];
}

+ (void) printSceneNodes:(SCNNode*)rootNode withLevel:(int)level
{
    for (int i = 0; i < level * 4; i++)
    {
        printf(" ");
    }
    printf("%s\n", [[rootNode name] UTF8String]);
    for (SCNNode* child in [rootNode childNodes])
    {
        [self printSceneNodes:child withLevel:level + 1];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Markup is optional physical annotations of a scanned scene, that persist between app launches.
    // Here is a list of markup we'll use for our sample.
    // If the user decides, the locations of this markup will be saved on device.

    _markupNameList = @[ @"tree", @"chair", @"gift" ];

    _mixedReality = [[BEMixedRealityMode alloc]
        initWithView:(BEView*)self.view
        engineOptions:@{
            kBECaptureReplayEnabled:  @([AppSettings booleanValueFromAppSetting:@"replayCapture"   defaultValueIfSettingIsNotInBundle:YES]),
            kBEUsingWideVisionLens:   @([AppSettings booleanValueFromAppSetting:@"useWVL"          defaultValueIfSettingIsNotInBundle:YES]),
            kBEStereoRenderingEnabled:@([AppSettings booleanValueFromAppSetting:@"stereoRendering" defaultValueIfSettingIsNotInBundle:YES]),
            kBEUsingColorCameraOnly:  @([AppSettings booleanValueFromAppSetting:@"colorCameraOnly" defaultValueIfSettingIsNotInBundle:NO]),
        }
        markupNames:_markupNameList
    ];

    _mixedReality.delegate = self;
    
    [_mixedReality start];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Here we initialize two gesture recognizers as a way to expose features.

    {
        // Allocate and initialize the first tap gesture.

        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        
        // Specify that the gesture must be a single tap.

        tapRecognizer.numberOfTapsRequired = 1;

        // Add the tap gesture recognizer to the view.

        [self.view addGestureRecognizer:tapRecognizer];
    }
    
    {
        // Allocate and initialize the second gesture as a double-tap one.

        UITapGestureRecognizer *twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];

        twoFingerTapRecognizer.numberOfTouchesRequired = 2;
        
        [self.view addGestureRecognizer:twoFingerTapRecognizer];
    }
}

- (void)setUpSceneKitWorlds:(BEStageLoadingStatus)stageLoadingStatus
{
    // When this function is called, it is guaranteed that the SceneKit world is set up, and any previously-positioned markup nodes are loaded.
    // As this function is called from a rendering thread, perform only SceneKit updates here.
    // Avoid UIKit manipulation here (use main thread for UIKit).
    
    if (stageLoadingStatus == BEStageLoadingStatusNotFound)
    {
        NSLog(@"Your scene does not exist in the expected location on your device!");
        NSLog(@"You probably need to scan and export your local scene!");
        return;
    }
    
    // It is up to you whether you want to call startMarkupEditing.
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

    if (foundAllMarkup)
        [self startExperience];
    else
        [_mixedReality startMarkupEditing];
    
    // Load SceneKit assets.

    self.treeNode  = [[self class] loadNodeNamed:@"Tree"  fromSceneNamed:@ASSETS_DIR"/tree.dae"];
    self.chairNode = [[self class] loadNodeNamed:@"Chair" fromSceneNamed:@ASSETS_DIR"/chair.dae"];
    self.giftNode  = [[self class] loadNodeNamed:@"Gift"  fromSceneNamed:@ASSETS_DIR"/gift.dae"];
    
    // Add assets to the world node.

    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.treeNode];
    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.chairNode];
    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.giftNode];
    
    // Hide all the objects initially (until markup positions them).

    [self.treeNode  setHidden:YES];
    [self.chairNode setHidden:YES];
    [self.giftNode  setHidden:YES];
    
    // Set any initial objects based on markup.

    for (id markupName in _markupNameList)
        [self updateObjectPositionWithMarkupName:markupName];

    // Add a custom node that we can use to highlight an object

    self.highlightNode = [SCNNode nodeWithGeometry:[SCNCylinder cylinderWithRadius:0.5 height:0.05]];
    self.highlightNode.geometry.firstMaterial.diffuse.contents = [UIColor colorWithRed:255/255.0 green:105/255.0 blue:180/255.0 alpha:1];
    self.highlightNode.hidden = YES;

    // Add the highlight node to the world.

    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.highlightNode];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)updateObjectPositionWithMarkupName:(NSString*)markupName
{
    // Here, we're using markup to set the location of static objects.
    // However, you could do something much more sophisticated, like have multiple markup points be waypoints for a virtual character.
    
    SCNNode * markupNode = [_mixedReality markupNodeForName:markupName];
    
    // Early-return if this markup node hasn't been positioned yet.

    if (!markupNode)
        return;
    
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
        // The gift's rotation will be determined in the updateAtTime method.

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
 
    _experienceIsRunning = YES;
}

- (void)markupEditingEnded
{
    // If markup editing is over, then any experience in the scene may be started.

    [self startExperience];
}

- (void)markupDidChange:(NSString*)markupChangedName
{
    // In this sample, markup and objects are 1:1, so we simply update the object position accordingly when a markup position changes.
    
    [self updateObjectPositionWithMarkupName:markupChangedName];
}

- (void) trackingStateChanged:(BETrackingState)trackingState
{
    switch (trackingState)
    {
        case BETrackingStateNominal:
            NSLog(@"trackingStateChanged: BETrackingStateNominal");
            break;
        
        case BETrackingStateNotTracking:
            NSLog(@"trackingStateChanged: BETrackingStateNotTracking");
            break;
            
        default:
            assert(false); // Invalid tracking state.
    }
}

- (void)highlightGivenNode:(SCNNode*)nodeToHighlight
{
    if (!nodeToHighlight)
    {
        [self.highlightNode setHidden:YES];

        return;
    }
        
    // Scale the highlightNode based on the size of the nodeToHighlight.

    SCNVector3 boundingBoxMin, boundingBoxMax;
    [nodeToHighlight getBoundingBoxMin:&boundingBoxMin max:&boundingBoxMax];
    
    // [SCNNode getBoundingBoxMin] does not take into account the object scale, so we must do it ourselves.
    
    boundingBoxMin = SCNVector3Make(
        boundingBoxMin.x * nodeToHighlight.scale.x,
        boundingBoxMin.y * nodeToHighlight.scale.y,
        boundingBoxMin.z * nodeToHighlight.scale.z
    );
    
    boundingBoxMax = SCNVector3Make(
        boundingBoxMax.x * nodeToHighlight.scale.x,
        boundingBoxMax.y * nodeToHighlight.scale.y,
        boundingBoxMax.z * nodeToHighlight.scale.z
    );

    float horizontalBoundingLength = sqrtf(
          powf(boundingBoxMin.x - boundingBoxMax.x, 2)
        + powf(boundingBoxMin.z - boundingBoxMax.z, 2)
    );

    // Slightly shrink the bounding length.

    horizontalBoundingLength *= 0.95f;

    self.highlightNode.scale = SCNVector3Make(horizontalBoundingLength, 1, horizontalBoundingLength);

    // Place it on the floor under the highlighted Node

    self.highlightNode.position = SCNVector3Make(
        nodeToHighlight.position.x,
        nodeToHighlight.position.y,
        nodeToHighlight.position.z
    );

    [self.highlightNode setHidden:NO];
}

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    // An example of what you can do when the user taps.
    
    CGPoint tapPoint = [sender locationInView:self.view];
    
    NSLog(@"Bridge Engine Sample handleTap %@", NSStringFromCGPoint(tapPoint));
    
    // First, hit test against any SceneKit objects.
    NSArray<SCNHitTestResult *> *hitTestResults = [_mixedReality hitTestSceneKitFrom2DScreenPoint:tapPoint options:nil];

    SCNNode *tappedObjectNode = nil;

    for (id result in hitTestResults)
    {
        SCNNode *node = [result node];
        
        // We could have hit a child node of one of the nodes we are actually looking for.
        // We must traverse up the hierarchy until we find it or reach the root node.

        do
        {
            NSString *nodeNameLower = node.name.lowercaseString;
            
            if ([_markupNameList containsObject:nodeNameLower])
            {
                // We hit one of our markup objects.

                tappedObjectNode = node;

                break;
            }
            
            node = node.parentNode;
            
        }
        while (node != nil);
            
        if (tappedObjectNode)
            break;
    }

    if (tappedObjectNode)
    {
        NSLog(@"tappedObjectNode: %@", tappedObjectNode.name);

        [self highlightGivenNode:tappedObjectNode];

        return;
    }
    
    // Remove the highlight.

    [self highlightGivenNode:nil];
    
    // If we don't hit any SceneKit objects, let's set the location of the gift based on the mesh.
    // Even though the gift's location is set by markup at the start of the experience, we're showing off moving it around with a tap.

    SCNVector3 meshNormal {NAN, NAN, NAN};
    SCNVector3 mesh3DPoint = [_mixedReality mesh3DFrom2DPoint:tapPoint outputNormal:&meshNormal];
    
    NSLog(@"\t mesh3DPoint %f,%f,%f", mesh3DPoint.x, mesh3DPoint.y, mesh3DPoint.z);
    
    self.giftNode.position = mesh3DPoint;
}

- (void)handleTwoFingerTap:(UITapGestureRecognizer *)sender
{
    // Increment through render styles, with fading transitions.
    
    BERenderStyle renderStyle = [_mixedReality getRenderStyle];
    BERenderStyle nextRenderStyle = BERenderStyle((renderStyle + 1) % NumBERenderStyles);

    [_mixedReality setRenderStyle:nextRenderStyle withDuration:0.5];
}

- (void)updateAtTime:(NSTimeInterval)time
{
    // This method is called before rendering each frame.
    // It is safe to modify SceneKit objects from here.
    
    {
        // Let's spin the gift a little at every frame.
    
        static NSTimeInterval lastUpdateTime = NAN;
        
        if (!isnan(lastUpdateTime))
        {
            float deltaTime = (time - lastUpdateTime);
            
            // Only spin the gift once our experience begins (after markup complete)
            
            if(_experienceIsRunning)
            {
                const float SPINNY_GIFT_RATE = 0.5; // rad/sec
                
                SCNVector3 currentEuler = self.giftNode.eulerAngles;
                currentEuler.y += SPINNY_GIFT_RATE * deltaTime;
                
                self.giftNode.eulerAngles = currentEuler;
            }
        }

        lastUpdateTime = time;
    }

    {
        // Here, you can control an interaction using the location of the device.

        SCNNode *localDeviceNode = _mixedReality.localDeviceNode;
        
        // For now, let's just log its position every 5 seconds.
        
        static NSTimeInterval lastDeviceNodeLoggingTime = time;

        if (time - lastDeviceNodeLoggingTime > 5.0)
        {
            NSLog(@"localDeviceNode.position: [ %f, %f, %f ]",
                localDeviceNode.position.x,
                localDeviceNode.position.y,
                localDeviceNode.position.z
            );

            lastDeviceNodeLoggingTime = time;
        }
    }
}

@end
