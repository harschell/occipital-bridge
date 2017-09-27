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

public class LanternManager: NSObject, CAAnimationDelegate {
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
            let windows = Scene.main().rootNode!.childNodes(passingTest: { node, _ in node.name == "PortalNode" });

            for window in windows {
                let mesh: SCNNode = SCNScene(named: "Assets.scnassets/maya_files/lantern.dae")!.rootNode.clone();

                let animationTime = 30.0;
                let upwardVelocity = 0.3;
                // unit / second
                let distance = Double.random(limits: 0.0 ... 1.0); // far .. close
                let distanceAway: Double = distance.mapUnitToRange(limits: -5 ... -1)
                let scale: Double = distance.mapUnitToRange(limits: 0.002...0.01);

                mesh.scale = SCNVector3(scale, scale, scale);

                // Setup position for lantern
                mesh.position = window.convertPosition(SCNVector3(-3, -5, distanceAway), to: self.container.presentation);

                self.container.addChildNode(mesh);
                self.lanterns.append(mesh);

                MainScheduler.instance.scheduleRelative((), dueTime: animationTime, action: { _ in
                    mesh.removeFromParentNode();
                    self.lanterns.remove(at: self.lanterns.index(of: mesh)!);
                    return BooleanDisposable();
                });

                // Setup floating animation
                let movement = CABasicAnimation(keyPath: "position");
                movement.toValue = NSValue(scnVector3: mesh.position - SCNVector3(0, upwardVelocity * animationTime, 0));
                movement.fromValue = NSValue(scnVector3: mesh.position);
                movement.repeatCount = 1;
                movement.duration = animationTime;
                movement.autoreverses = false;
                movement.isRemovedOnCompletion = false;
                movement.fillMode = kCAFillModeForwards;

                mesh.addAnimation(movement, forKey: nil)
            }
        };
    }

    func update(time: Double) {
        sub.on(Event.next(time as TimeInterval));
    }
}

