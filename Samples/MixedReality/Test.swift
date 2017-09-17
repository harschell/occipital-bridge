//
//  Test.swift
//  MixedReality
//
//  Created by John Austin on 9/17/17.
//  Copyright © 2017 Occipital. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit
import RxSwift

public class LanternManager: NSObject {
    private var lanterns: [SCNNode] = [];
    private var container: SceneKit.SCNNode;
    private var sub: RxSwift.PublishSubject<TimeInterval>;

    init(container: SceneKit.SCNNode) {
        self.container = container;
        sub = PublishSubject();
    }

    func setup() {
        sub.throttle(1, scheduler: MainScheduler.instance).subscribe { _ in

            // Add a lantern in front of every window
            let windows = Scene.main().rootNode!.childNodes(passingTest: {node, _ in node.name == "PortalNode" });

            for window in windows {
                let mesh: SCNNode = SCNScene(named: "Assets.scnassets/maya_files/lantern2.dae")!.rootNode.clone();

                mesh.scale = SCNVector3(0.01, 0.01, 0.01);
                mesh.position = window.convertPosition(SCNVector3(0,0,-0.5), to: self.container);

                // Setup floating animation
                let movement = CABasicAnimation(keyPath: "position");
                movement.toValue = NSValue(scnVector3: mesh.position + SCNVector3(0,-3,0));
                movement.fromValue = NSValue(scnVector3: mesh.position);
                movement.repeatCount = 1;
                movement.duration = 5;
                movement.autoreverses = false;

                mesh.addAnimation(movement, forKey: nil)

                self.container.addChildNode(mesh);
                self.lanterns.append(mesh);
            }
        };
    }

    func update(time: Double) {
        sub.on(Event.next(time as TimeInterval));
    }
}
