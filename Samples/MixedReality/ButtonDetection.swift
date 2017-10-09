//
// Created by John Austin on 10/4/17.
// Copyright (c) 2017 Occipital. All rights reserved.
//

import Foundation

class ButtonDetection : Component, EventComponentProtocol {

    func touchBeganButton(_ button: UInt8, forward touchForward: _GLKVector3, hit: SCNHitTestResult!) -> Bool {
        print("touchbegan");
        return true;
    }

    func touchMovedButton(_ button: UInt8, forward touchForward: _GLKVector3, hit: SCNHitTestResult!) -> Bool {
        print("touchmoved");
        return true;
    }

    func touchEndedButton(_ button: UInt8, forward touchForward: _GLKVector3, hit: SCNHitTestResult!) -> Bool {
        print("touchended");
        return true;
    }

    func touchCancelledButton(_ button: UInt8, forward touchForward: _GLKVector3, hit: SCNHitTestResult!) -> Bool {
        print("touchcancelled");
        return true;
    }
}