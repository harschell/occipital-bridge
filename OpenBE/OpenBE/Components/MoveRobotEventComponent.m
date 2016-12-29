/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "MoveRobotEventComponent.h"
//#import "BehaviourComponents/ExpressionBehaviourComponent.h"

@implementation MoveRobotEventComponent

- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return YES;
}

- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    // Ignore move events if the robot is still a box.
    if( [self.robotBehaviourComponent isUnfolded] == NO ) {
        return NO;
    }
    
//    // Play an expression on each letter
//    ExpressionBehaviourComponent *expressionComp = (ExpressionBehaviourComponent *)[self.robotBehaviourComponent.entity componentForClass:ExpressionBehaviourComponent.class];
//    if( button ) {
//        switch( button ) {
//        case 'A': [expressionComp playExpression:EXPRESSION_KEY_HAPPY]; return NO;
//        case 'B': [expressionComp playExpression:EXPRESSION_KEY_DANCE]; return NO;
//        case 'C': [expressionComp playExpression:EXPRESSION_KEY_SAD]; return NO;
//        case 'D': [expressionComp playExpression:EXPRESSION_KEY_POWER_UP]; return NO;
//        case 'E': [expressionComp playExpression:EXPRESSION_KEY_POWER_DOWN]; return NO;
//        default: break;
//        }
//    }
    
    if( hit ) {
        [self.robotBehaviourComponent stopAllBehaviours];
        [self.robotBehaviourComponent startMoveTo:SCNVector3ToGLKVector3(hit.worldCoordinates)];
    } else {
        [self.robotBehaviourComponent beSad];
    }
    
    return YES;
}

- (bool) touchCanceledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

@end
