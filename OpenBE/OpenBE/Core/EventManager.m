/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GLKit/GLKit.h>
#import <GameController/GameController.h>
#import <BridgeEngine/BEDebugging.h>

#import "EventManager.h"
#import "Core.h"
#import "CoreMotionComponentProtocol.h"

@interface TouchEventResponders : NSObject
@property (weak) UITouch* touch;
@property (strong) NSMutableArray * eventComponents;
@end

@implementation TouchEventResponders
@synthesize touch, eventComponents;
@end


@interface EventManager ()
@property (strong) NSMutableArray* touchEventResponders;
@property (strong) NSMutableArray* globalEventComponents;
@property (strong) UITouch* controllerButtonTouch;
@property (atomic) bool globalEventComponentsPaused;
@end


@implementation EventManager

- (instancetype) init {
    self = [super init];
    
    if(self) {
        self.controllerButtonTouch = [[UITouch alloc] init];
        self.touchEventResponders = [[NSMutableArray alloc] initWithCapacity:32];
        self.globalEventComponents = [[NSMutableArray alloc] initWithCapacity:32];
        
        self.useReticleAsTouchLocation = NO;
        self.globalEventComponentsPaused = NO;
        
        if ([[GCController controllers] count] == 0) {
            [GCController startWirelessControllerDiscoveryWithCompletionHandler:^{                
                NSLog(@"complete");
            }];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(controllerDiscovered:)
                                                         name:GCControllerDidConnectNotification
                                                       object:nil];
        }
    }
    return self;
}

- (void)controllerDiscovered:(NSNotification *)connectedNotification {
    NSLog(@"Game Controller discovered");
}

+ (EventManager *) main {
    static EventManager * mainEventManager;
    if( mainEventManager == nil) {
        mainEventManager = [[EventManager alloc] init];
    }
    
    return mainEventManager;
}

- (void) start {
    for( GKComponent * component in self.globalEventComponents ) {
        if( [component conformsToProtocol:@protocol(ComponentProtocol)]) {
            [(GKComponent <ComponentProtocol> *)component start];
        }
    }
}

- (void) pauseGlobalEventComponents {
    self.globalEventComponentsPaused = YES;

    for( GKComponent * component in self.globalEventComponents ) {
        if( [component conformsToProtocol:@protocol(EventComponentProtocol)]
         && [component respondsToSelector:@selector(setPause:)]) {
            [(GKComponent <EventComponentProtocol> *)component setPause:true];
        }
    }
}

- (void) resumeGlobalEventComponents {
    self.globalEventComponentsPaused = NO;

    for( GKComponent * component in self.globalEventComponents ) {
        if( [component conformsToProtocol:@protocol(EventComponentProtocol)]
         && [component respondsToSelector:@selector(setPause:)]) {
            [(GKComponent <EventComponentProtocol> *)component setPause:false];
        }
    }
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( !self.globalEventComponentsPaused ) {
        for( GKComponent * component in self.globalEventComponents ) {
            if( [component conformsToProtocol:@protocol(ComponentProtocol)]) {
                [(GKComponent <ComponentProtocol> *)component updateWithDeltaTime:seconds];
            }
        }
    }
}

- (void) addGlobalEventComponent:(GKComponent *)component {
    if( [component conformsToProtocol:@protocol(EventComponentProtocol)]) {
        [self.globalEventComponents addObject:component];
    } else {
        NSLog(@"Adding a globalEventComponent to EventManager which doesn't conforms to EventcomponentProtocol");
    }
}

- (TouchEventResponders *) getTouchEventRespondersForTouch:(UITouch *)touch {
    for( TouchEventResponders * touchEventResponder in self.touchEventResponders ) {
        if( touchEventResponder.touch == touch ) {
            return touchEventResponder;
        }
    }
    return nil;
}

- (void) cleanUpTouchEventResponders:(UIEvent *)event {
    NSMutableArray * cancelledTouchEventResponders = [[NSMutableArray alloc] init];
    
    for( TouchEventResponders * touchEventResponder in self.touchEventResponders ) {
        TouchEventResponders * cleanup = touchEventResponder;
        
        for( UITouch * touch in  [event allTouches] ) {
            if( touchEventResponder.touch == touch ) {
                cleanup = nil;
            };
        }
        
        if( cleanup ) {
            [cancelledTouchEventResponders addObject:cleanup];
        }
    }
    
    for( TouchEventResponders * cleanup in  cancelledTouchEventResponders ) {
        [self.touchEventResponders removeObject:cleanup];
    }
}

- (void) controllerButtonDown
{
    bool currentUseReticleAsTouchLocation = self.useReticleAsTouchLocation;
    self.useReticleAsTouchLocation = YES;
    
    // Mimic taps on the screen, but with specific _netTouches UITouch objects representing each button.
    UITouch *touch = _controllerButtonTouch;
    NSSet* set = [NSSet setWithObject:touch];
    [self handleTouchesBegan:set withEvent:nil];
    
    self.useReticleAsTouchLocation = currentUseReticleAsTouchLocation;
}

- (void) controllerButtonUp
{
    bool currentUseReticleAsTouchLocation = self.useReticleAsTouchLocation;
    self.useReticleAsTouchLocation = YES;
    
    UITouch *touch = _controllerButtonTouch;
    NSSet* set = [NSSet setWithObject:touch];
    [self touchesEnded:set withEvent:nil];
    
    self.useReticleAsTouchLocation = currentUseReticleAsTouchLocation;
}

#pragma mark - Handle Touch Input events
// Handle all events via the touch input handlers.
// All touch inputs get converted into 3D ray-casts into the scene.
// This requires good tracking in mixedRealityMode.lastTrackerPoseAccuracy == BETrackerPoseAccuracyHigh
// FUTURE CONSIDERATION:
//   We will need to handle multiple button inputs, like multi-touch events,
//   that can trigger actions in the event responder chain.
//   Button inputs don't necessarily need the current 3D ray-cast in the UI.
//   So, we should be allowing these event handlers process button events without any valid hit test.

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // handle all touches
    // Clean up any responders that are no longer in the event.allTouches set.
    [self cleanUpTouchEventResponders:event];
    
    [self handleTouchesBegan:touches withEvent:event];
}

- (void)handleTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // FIXME: This temporarily blocks all controller actions when not tracking.  Later this can be changed, it's not a fundamental thing we need to keep forever.
    if( _mixedRealityMode.lastTrackerPoseAccuracy == BETrackerPoseAccuracyNotAvailable ){
        be_dbg("Ignored touchesBegan event, pose not available");
        return;
    }
    
    for( UITouch * touch in  touches ) {
        
        SCNHitTestResult * hit = [self intersectSceneFromTouch:touch];
        
        GLKVector3 forward = [self getTouchForward:touch];
        
        NSMutableArray * eventComponents = self.globalEventComponents;
        
        if( hit ) { // node is hit, if node contains entity and entity contains components
            // conforming to EventComponentProtocol, only use these components as
            // possible responders. Otherwise: loop through global event components
            
            GKEntity * entity = [hit.node valueForKey:@"entity"];
            SCNNode * node = hit.node;
            
            while( !entity && node.parentNode ) {
                node = node.parentNode;
                entity = [node valueForKey:@"entity"];
            }
            
            if( entity ) {
                NSMutableArray * possibleEventComponents = [[NSMutableArray alloc] initWithCapacity:8];
                
                for( GKComponent * component in entity.components ) {
                    if( [component conformsToProtocol:@protocol(EventComponentProtocol)]) {
                        if( [component conformsToProtocol:@protocol(ComponentProtocol)] ) {
                            if(  [(GKComponent <ComponentProtocol> *)component isEnabled] ) {
                                [possibleEventComponents addObject:(GKComponent <EventComponentProtocol> *)component];
                            }
                        } else {
                            [possibleEventComponents addObject:(GKComponent <EventComponentProtocol> *)component];
                        }
                    }
                }
                
                if( [possibleEventComponents count] ) {
                    eventComponents = possibleEventComponents;
                }
            }
        }
        
        NSMutableArray * possibleEventComponents = [[NSMutableArray alloc] initWithCapacity:8];
        for( GKComponent * component in eventComponents ) {
            if( [component conformsToProtocol:@protocol(ComponentProtocol)] ) {
                if(  [(GKComponent <ComponentProtocol> *)component isEnabled] )
                    [possibleEventComponents addObject:(GKComponent <EventComponentProtocol> *)component];
            } else {
                [possibleEventComponents addObject:(GKComponent <EventComponentProtocol> *)component];
            }
        }
        eventComponents = possibleEventComponents;
        
        
        // create TouchEventResponders object
        
        TouchEventResponders * touchEventRepsonders = [[TouchEventResponders alloc] init];
        
        touchEventRepsonders.touch = touch;
        touchEventRepsonders.eventComponents = eventComponents;
        
        [self.touchEventResponders addObject:touchEventRepsonders];
        
        uint8_t button; // only one button for now
        
        // Special case for when controller button is being used vs touch events.
        // Button = 1, for when a controller button is held down. (takes precidence)
        // Button = 0, for touch input
        if( [touches containsObject:_controllerButtonTouch] ) {
            button = 1;
        } else {
            button = 0;
        }
        
        for( GKComponent * component in touchEventRepsonders.eventComponents ) {
            be_NSDbg(@"Touch Began on component: %@, button: %d", NSStringFromClass(component.class), button);
            [_mixedRealityMode runBlockInRenderThread:^(void) {
                [(GKComponent <EventComponentProtocol> * )component touchBeganButton:button forward:forward hit:hit];
            }];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // FIXME: This temporarily blocks all controller actions when not tracking.
    // This can be changed, it's not a fundamental thing we need to keep forever.
    if(_mixedRealityMode.lastTrackerPoseAccuracy == BETrackerPoseAccuracyNotAvailable ) {
        be_dbg("Ignored touchesEnded event, pose not available");
        [self cleanUpTouchEventResponders:event];
        return;
    }
    
    for( UITouch * touch in  touches ) {
        
        SCNHitTestResult * hit = [self intersectSceneFromTouch:touch];
        
        TouchEventResponders * touchEventResponder = [self getTouchEventRespondersForTouch:touch];
        
        if( touchEventResponder ) {
	        uint8_t button; // only one button for now
        
	        // Special case for when controller button is being used vs touch events.
	        // Button = 1, for when a controller button is held down. (takes precidence)
	        // Button = 0, for touch input
	        if( [touches containsObject:_controllerButtonTouch] ) {
	            button = 1;
	        } else {
	            button = 0;
	        }
            for( GKComponent * component in touchEventResponder.eventComponents ) {
                be_NSDbg(@"Touch End on component: %@", NSStringFromClass(component.class));
                [_mixedRealityMode runBlockInRenderThread:^(void) {
                    [(GKComponent <EventComponentProtocol> * )component  touchEndedButton:button forward:[self getTouchForward:touch] hit:hit];
                }];
            }
            // no first responder after touch ended
            [self.touchEventResponders removeObject:touchEventResponder];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    // FIXME: This temporarily blocks all controller actions when not tracking.
    // This can be changed, it's not a fundamental thing we need to keep forever.
    if(_mixedRealityMode.lastTrackerPoseAccuracy == BETrackerPoseAccuracyNotAvailable ) {
        be_dbg("Ignored touchesCancelled event, pose not available");
        [self cleanUpTouchEventResponders:event];
        return;
    }
    
    for( UITouch * touch in  touches ) {
        
        SCNHitTestResult * hit = [self intersectSceneFromTouch:touch];
        
        TouchEventResponders * touchEventResponder = [self getTouchEventRespondersForTouch:touch];
        
        if( touchEventResponder ) {
	        uint8_t button; // only one button for now
        
	        // Special case for when controller button is being used vs touch events.
	        // Button = 1, for when a controller button is held down. (takes precidence)
	        // Button = 0, for touch input
	        if( [touches containsObject:_controllerButtonTouch] ) {
	            button = 1;
	        } else {
	            button = 0;
	        }

            for( GKComponent * component in touchEventResponder.eventComponents ) {
                if( [component respondsToSelector:@selector(touchCancelledButton:forward:hit:)] == NO ) {
                    be_NSDbg(@"Unhandled @selector(touchCancelledButton:forward:hit:) with object class: %@", NSStringFromClass(component.class));
                } else {
                    be_NSDbg(@"Touch Cancelled on component: %@", NSStringFromClass(component.class));
                    [_mixedRealityMode runBlockInRenderThread:^(void) {
                        [(GKComponent <EventComponentProtocol> * )component touchCancelledButton:button forward:[self getTouchForward:touch] hit:hit];
                    }];
                }
            }
            
            // no first responder after touch ended
            [self.touchEventResponders removeObject:touchEventResponder];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // FIXME: This temporarily blocks all controller actions when not tracking.
    // This can be changed, it's not a fundamental thing we need to keep forever.
    if(_mixedRealityMode.lastTrackerPoseAccuracy == BETrackerPoseAccuracyNotAvailable ) {
        be_dbg("Ignored touchesMoved event, pose not available");
        [self cleanUpTouchEventResponders:event];
        return;
    }
    
    for( UITouch * touch in  touches ) {
        
        SCNHitTestResult * hit = [self intersectSceneFromTouch:touch];
        
        TouchEventResponders * touchEventResponder = [self getTouchEventRespondersForTouch:touch];
        
        if( touchEventResponder ) {
	        uint8_t button; // only one button for now
        
	        // Special case for when controller button is being used vs touch events.
	        // Button = 1, for when a controller button is held down. (takes precidence)
	        // Button = 0, for touch input
	        if( [touches containsObject:_controllerButtonTouch] ) {
	            button = 1;
	        } else {
	            button = 0;
	        }

            for( GKComponent * component in touchEventResponder.eventComponents ) {
//                be_NSDbg(@"Touch Moved with button %d on component: %@", button, NSStringFromClass(component.class));
                [_mixedRealityMode runBlockInRenderThread:^(void) {
                    [(GKComponent <EventComponentProtocol> * )component touchMovedButton:button forward:[self getTouchForward:touch] hit:hit];
                }];
            }
        }
    }
}

- (GLKVector3) getTouchForward:(UITouch *)touch {
    
    if( self.useReticleAsTouchLocation ) {
        return [Camera main].reticleForward;
    } else {
        CGPoint tapPoint = [touch locationInView:touch.view];
        SCNVector3 projectedOrigin = [_mixedRealityMode.sceneKitRenderer projectPoint:SCNVector3Make(0.f, 0.f, 1.f)];
        return GLKVector3Normalize( GLKVector3Subtract( SCNVector3ToGLKVector3([_mixedRealityMode.sceneKitRenderer unprojectPoint:SCNVector3Make(tapPoint.x, tapPoint.y, projectedOrigin.z)]), [Camera main].position) );
    }
}

- (SCNHitTestResult *) intersectSceneFromTouch:(UITouch *)touch {
    
    if(_mixedRealityMode.lastTrackerPoseAccuracy == BETrackerPoseAccuracyNotAvailable ) {
        be_dbg("Ignored intersection test, pose not available");
        return nil;
    }
    
    float maxDistance = 100.;
    
    NSArray<SCNHitTestResult *> *hitTestResults;
    
    if( self.useReticleAsTouchLocation ) {
        SCNVector3 from = SCNVector3FromGLKVector3( [Camera main].position );
        SCNVector3 to = SCNVector3FromGLKVector3( GLKVector3Add( [Camera main].position, GLKVector3MultiplyScalar([Camera main].reticleForward, maxDistance) ) );
        
        if( (from.x == 0.f && from.y == 0.f && from.z == 0.f) ||
            (to.x == 0.f && to.y == 0.f && to.z == 0.f) ||
            (from.x == to.x && from.y == to.y && from.z == to.z ) ||
            isnan(from.x) || isnan(from.y) || isnan(from.z) ||
            isnan(to.x) || isnan(to.y) || isnan(to.z) ) {
            // don't know why: but if we continue now a bad access exception will be thrown
            // by rayTestWithSegmentFromPoint.
            // TODO: find out why and fix this.
            return nil;
        }
        
        // SCNHitTestOptionCategoryBitMask only works on iOS 10 !!!
        //NSDictionary *options = @{SCNHitTestSortResultsKey:@YES, SCNHitTestBackFaceCullingKey:@NO, SCNHitTestOptionCategoryBitMask:@(~(NSUInteger)RAYCAST_IGNORE_BIT)};
        
        NSDictionary *options = @{SCNHitTestSortResultsKey:@YES, SCNHitTestBackFaceCullingKey:@NO};
        hitTestResults = [[Scene main].scene.rootNode hitTestWithSegmentFromPoint:from toPoint:to options:options];
//        NSLog(@"%ld reticle intersection hits", hitTestResults.count);
    } else {
        CGPoint tapPoint = [touch locationInView:touch.view];
        NSDictionary *options = @{SCNHitTestSortResultsKey:@YES, SCNHitTestBackFaceCullingKey:@NO};
        hitTestResults = [_mixedRealityMode hitTestSceneKitFrom2DScreenPoint:tapPoint options:options];
    }
    
    if( [hitTestResults count] ) {
        for( SCNHitTestResult * result in hitTestResults ) {
            if( !(result.node.categoryBitMask & RAYCAST_IGNORE_BIT) ) {
				return result;
			}
        }
    }
    
    return nil;
}

@end
