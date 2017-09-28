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
        // Spawn a bunch of lanterns just on the horizon.
        sub.delay(12, scheduler: MainScheduler.instance).throttle(3, scheduler: MainScheduler.instance).subscribe { _ in
            let windows = Scene.main().rootNode!.childNodes(passingTest: { node, _ in node.name == "PortalNode" });

            if (windows.count > 0) {

                // far .. close
                let distance = Double.random(limits: 0.0...1.0);
                let distanceAway: Double = distance.mapUnitToRange(limits: -22 ... -20)
                let scale: Double = Double.random(limits: 0.005...0.01);

                // Setup position for lantern
                let position = windows[0].convertPosition(SCNVector3(
                        Double.random(limits: -5.0...5.0),
                        Double.random(limits: -3...1.0),
                        distanceAway), to: self.container.presentation);

                self.addNewLantern(position: position, scale: scale);
            }
        };

        // Spawn an occasional lantern that comes right by the window.
        let _ = sub
                .delay(25, scheduler: MainScheduler.instance)
                .throttle(15, scheduler: MainScheduler.instance).subscribe { _ in
                    let windows = Scene.main().rootNode!.childNodes(passingTest: { n, _ in n.name == "PortalNode" });

                    if (windows.count > 0) {
                        let distance = Double.random(limits: 0.0...1.0);
                        // far .. close
                        let distanceAway: Double = distance.mapUnitToRange(limits: -9 ... -8)
                        let scale: Double = 0.02;

                        // Setup position for lantern
                        let position = windows[0].convertPosition(SCNVector3(
                                Double.random(limits: -0.25...0.25),
                                -4,
                                distanceAway), to: self.container.presentation);

                        self.addNewLantern(position: position, scale: scale, upwardVelocity: 0.5);
                    }
                };
    }

    func update(time: Double) {
        sub.on(Event.next(time as TimeInterval));
    }


    func addNewLantern(position: SCNVector3, scale: Double, upwardVelocity: Double = 0.15) {
        let mesh: SCNNode = SCNScene(named: "Assets.scnassets/maya_files/lantern.dae")!.rootNode.clone();
        mesh.scale = SCNVector3(scale, scale, scale);
        mesh.rotation = SCNVector4Make(1, 0, 0, .pi);
        mesh.position = position;

        let animationTime = 30.0;

        self.container.addChildNode(mesh);
        self.lanterns.append(mesh);

        let _ = MainScheduler.instance.scheduleRelative((), dueTime: animationTime, action: { _ in
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
}

