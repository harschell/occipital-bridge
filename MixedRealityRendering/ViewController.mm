/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#import "ViewController.h"
#import "AppSettings.h"
#import <BridgeEngine/BridgeEngine.h>

#import <cassert>
#import <ReplayKit/ReplayKit.h>

//------------------------------------------------------------------------------

#define ASSETS_DIR "Assets.scnassets" // The SceneKit assets root folder.

// Since -Y is up in Bridge Engine convention, the pivot rotates from the typical convention.

static const SCNMatrix4 defaultPivot = SCNMatrix4MakeRotation(M_PI, 1.0, 0.0, 0.0);

//------------------------------------------------------------------------------

#pragma mark - ViewController ()

@interface ViewController () < BEMixedRealityModeDelegate, RPPreviewViewControllerDelegate >

@property (strong) SCNNode *  treeNode;
@property (strong) SCNNode * chairNode;
@property (strong) SCNNode *  giftNode;
@property (strong) NSDictionary *  shaderModifiersExample;

@property (strong) SCNNode *  highlightNode;


@end

//------------------------------------------------------------------------------

#pragma mark - ViewController

@implementation ViewController
{
    BEMixedRealityMode* _mixedReality;
    NSArray*            _markupNameList;
    BOOL                _experienceIsRunning;
    RPScreenRecorder *  _screenRecorder;
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
            kBECaptureReplayEnabled:  @([AppSettings booleanValueFromAppSetting:@"replayCapture"   defaultValueIfSettingIsNotInBundle:NO]),
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
    
    {
        // Three-finger tap recognizer (for Start/Stop ReplayKit recording)
        
        UITapGestureRecognizer *threeFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleThreeFingerTap:)];
        
        threeFingerTapRecognizer.numberOfTouchesRequired = 3;
        
        [self.view addGestureRecognizer:threeFingerTapRecognizer];
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
    
    

    // The shader modifiers can be supplied to the material in an
    // NSDictionary with keys for the entry points.
    
    _shaderModifiersExample =
    @{
      SCNShaderModifierEntryPointGeometry : @R"(
      uniform float intensity;

      // this gets copied into the vertex shader
      // custom functions
      float noise(vec3 p) { return 0.5 * fract(sin(dot(p.xyz ,vec3(12.9898, 78.233, 47.24))) * 43758.5453); }
      
#pragma body // seperator needded if you have custom functions
      _geometry.position.x += intensity * 0.2 * noise(_geometry.position.xyz + u_time) * cos(2.0 * u_time + 25. * _geometry.position.y);
      _geometry.position.x += intensity * 0.4 * sin(0.5 * u_time + _geometry.position.y);
      _geometry.position.z += intensity * 0.1 * sin(5.0 * u_time + 25. * _geometry.position.y);
      )",
      SCNShaderModifierEntryPointFragment : @R"(
      uniform float intensity;

      // this gets copied into the fragment shader
      // custom functions
      float noise(vec3 p) { return 0.2 * fract(sin(dot(p.xyz ,vec3(12.9898,78.233,47.24))) * 43758.5453); }
#pragma body // seperator needded if you have custom functions
      vec3 worldSpace = (u_inverseModelViewTransform * vec4(v_position, 1.0)).xyz;
      float random = noise(vec3(u_time));
      float flicker = max(1., random * 1.5);
      float lines = abs(sin(worldSpace.y*30. + u_time));
      vec4 oldColor = _output.color;
      _output.color *= flicker * lines;
      _output.color.rgb = pow(_output.color.rgb, vec3(0.6, 0.4, 0.1));
      _output.color += noise(worldSpace*50.) * 0.3;
      _output.color = intensity * _output.color + (1.0 - intensity) * oldColor;
      )"
      };
    
    // Add assets to the world node.

    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.treeNode];
    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.chairNode];
    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.giftNode];
    
    // Hide all the objects initially (until markup positions them).

    [self.treeNode  setHidden:YES];
    [self.chairNode setHidden:YES];
    [self.giftNode  setHidden:YES];
    
    // set the category bit mask so that they cast shadows
    [[self.treeNode  childNodeWithName:@"Mesh" recursively:YES] setCategoryBitMask:3];
    [self.chairNode setCategoryBitMask:3];
    [self.giftNode setCategoryBitMask:3];

    
    // Set any initial objects based on markup.

    for (id markupName in _markupNameList)
        [self updateObjectPositionWithMarkupName:markupName];

    // Add a custom node that we can use to highlight an object

    self.highlightNode = [SCNNode nodeWithGeometry:[SCNCylinder cylinderWithRadius:0.5 height:0.05]];
    self.highlightNode.geometry.firstMaterial.diffuse.contents = [UIColor colorWithRed:255/255.0 green:105/255.0 blue:180/255.0 alpha:1];
    self.highlightNode.hidden = YES;

    // Add the highlight node to the world.

    [_mixedReality.worldNodeWhenRelocalized addChildNode:self.highlightNode];
    
    
    //Set up custom post-processing shader
    NSString *customFragShader =  @R"(
    precision highp float;
    
    uniform float u_distortion;
    uniform float u_time;
    
    
    uniform sampler2D u_bridgeRender;
    varying vec2 v_texCoord;
    
    // Start Ashima 2D Simplex Noise
    
    vec3 mod289(vec3 x) {
        return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    
    vec2 mod289(vec2 x) {
        return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    
    vec3 permute(vec3 x) {
        return mod289(((x*34.0)+1.0)*x);
    }
    
    float snoise(vec2 v)
    {
        const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                            0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                            -0.577350269189626,  // -1.0 + 2.0 * C.x
                            0.024390243902439); // 1.0 / 41.0
        vec2 i  = floor(v + dot(v, C.yy) );
        vec2 x0 = v -   i + dot(i, C.xx);
        
        vec2 i1;
        i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
        vec4 x12 = x0.xyxy + C.xxzz;
        x12.xy -= i1;
        
        i = mod289(i); // Avoid truncation effects in permutation
        vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
                         + i.x + vec3(0.0, i1.x, 1.0 ));
        
        vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
        m = m*m ;
        m = m*m ;
        
        vec3 x = 2.0 * fract(p * C.www) - 1.0;
        vec3 h = abs(x) - 0.5;
        vec3 ox = floor(x + 0.5);
        vec3 a0 = x - ox;
        
        m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
        
        vec3 g;
        g.x  = a0.x  * x0.x  + h.x  * x0.y;
        g.yz = a0.yz * x12.xz + h.yz * x12.yw;
        return 130.0 * dot(m, g);
    }
    
    // End Ashima 2D Simplex Noise
    
    void main()
    {
        vec2 p       =  v_texCoord;
        
        float n = snoise( vec2(u_time/10. + p.y, 0.0) *3.) - 0.5;
        float n2 = snoise( vec2(u_time/10. + p.y, 0.0) *20.) - 0.5;
        float offset = u_distortion * 0.05 * (n * 0.5 + n2* 0.2);

        vec2 coord = vec2(fract(p.x + offset),p.y);
        
        gl_FragColor = texture2D(u_bridgeRender, vec2(fract(p.x + offset),p.y));
        gl_FragColor.r = texture2D(u_bridgeRender, vec2(fract(p.x + offset * 0.5),p.y)).r;
        gl_FragColor.b = texture2D(u_bridgeRender, vec2(fract(p.x + offset * 1.5),p.y)).b;

        gl_FragColor += u_distortion * sin(p.y*800.)/4.;
        
    }
    )";
    
    NSDictionary *uniformDictionary = @{
                                        @"u_time"         : [NSNumber numberWithDouble:1.0],
                                        @"u_distortion"   : [NSNumber numberWithDouble:0.1]
                                        };
    
    [_mixedReality setCustomPostProcessingShader:customFragShader];
    [_mixedReality setCustomPostProcessingShaderFloatUniforms:uniformDictionary];

    
    // You could add fog to the Scenekit objects with code like this.
    // Note that this does not affect the camera image.
//    [[_mixedReality sceneKitScene] setFogEndDistance:2.0];
//    [[_mixedReality sceneKitScene] setFogDensityExponent:2.0];
//    [[_mixedReality sceneKitScene] setFogColor:[UIColor colorWithHue:0.1 saturation:1.0 brightness:1.0 alpha:1.0]];
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
        
        // remove the other shader modifiers
        [_treeNode  childNodeWithName:@"Mesh" recursively:YES].geometry.firstMaterial.shaderModifiers = @{};
        _giftNode.geometry.firstMaterial.shaderModifiers = @{};
        _chairNode.geometry.firstMaterial.shaderModifiers = @{};
        
        NSLog(@"tappedObjectNode: %@", tappedObjectNode.name);
        
        // the tree's mesh is a child of the root
        if ( tappedObjectNode == _treeNode)
            tappedObjectNode = [tappedObjectNode childNodeWithName:@"Mesh" recursively:YES];
            
        tappedObjectNode.geometry.firstMaterial.shaderModifiers = _shaderModifiersExample;
        
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration : 2.0];
        {
            [tappedObjectNode.geometry.firstMaterial setValue:@1.0 forKeyPath:@"intensity"];
        }
        [SCNTransaction commit];
        
    } else {
        
        [_mixedReality setCustomPostProcessingShaderFloatUniforms:@{@"u_distortion" :
                            [NSNumber numberWithDouble:tapPoint.x/self.view.frame.size.width]}];
        
    }
    
    return;

}

// Here we use a 3-finger tap to start/end a ReplayKit screen recording.
- (void)handleThreeFingerTap:(UITapGestureRecognizer *)sender
{
    if( _screenRecorder == nil) {
         _screenRecorder = [RPScreenRecorder sharedRecorder];
    }
    
    if(! _screenRecorder.isRecording &&  _screenRecorder.isAvailable)
    {
        [ _screenRecorder startRecordingWithMicrophoneEnabled:YES handler:^(NSError * _Nullable error) {
            NSLog(@"Error Starting = %@", error);
        }];
    }
    else
    {
        [ _screenRecorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            if(error != nil)
            {
                NSLog(@"Error Ending = %@", error);
            }
            else
            {
                previewViewController.previewControllerDelegate = self;
                previewViewController.popoverPresentationController.sourceView = self.view;
                [self presentViewController:previewViewController animated:YES completion:nil];
            }
        }];
    }
}

- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController
{
    // When the user is finished with the ReplayKit preview controller, we dismiss it.
    [previewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleTwoFingerTap:(UITapGestureRecognizer *)sender
{
    // Increment through render styles, with fading transitions.
    
    BERenderStyle renderStyle = [_mixedReality getRenderStyle];
    BERenderStyle nextRenderStyle = BERenderStyle((renderStyle + 1) % NumBERenderStyles);

    NSLog(@"RenderStyle set to %ld", (long)nextRenderStyle);
    [_mixedReality setRenderStyle:nextRenderStyle withDuration:0.5];
}

- (void)updateAtTime:(NSTimeInterval)time
{
    // This method is called before rendering each frame.
    // It is safe to modify SceneKit objects from here.

    // In this demo, let's just update custom shaders
    [_mixedReality setCustomPostProcessingShaderFloatUniforms:@{@"u_time" : [NSNumber numberWithDouble:time]}];
    
}

@end
