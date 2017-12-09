//
//  LaunchScreenViewController.swift
//  MixedReality
//
//  Created by John Austin on 12/8/17.
//  Copyright © 2017 Occipital. All rights reserved.
//

import UIKit

class LaunchScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func StartButton(_ sender: UIButton) {
        print("got button");
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil);
        let controller = storyboard.instantiateInitialViewController()!;
        
        appDelegate.window.rootViewController = controller;
    }
    
    @IBAction func SettingsButton(_ sender: UIButton) {
        print("got settings button");
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;

        //appDelegate.window = UIWindow(frame: UIScreen.main.bounds);
        
        let beBundle = Bundle(for: BEDebugSettingsViewController.self);
        let storyboard = UIStoryboard(name: "BEDebugSettings", bundle: beBundle);
        appDelegate.navController = storyboard.instantiateInitialViewController()! as! UINavigationController;
        let settingsVC = appDelegate.navController.viewControllers.first;
        appDelegate.prepareDebugSettingsVC(settingsVC as! BEDebugSettingsViewController);
        appDelegate.window.rootViewController = appDelegate.navController;
        
        
        // Show the settings UI, with a prepared set of debug settings.
       // NSBundle *beBundle = [NSBundle bundleForClass:BEDebugSettingsViewController.class];
        //UIStoryboard *beDebugSettingsStoryboard = [UIStoryboard storyboardWithName:@"BEDebugSettings" bundle:beBundle];
        //self.navController = [beDebugSettingsStoryboard instantiateInitialViewController];
        //BEDebugSettingsViewController *debugSettingsVC = (BEDebugSettingsViewController *)_navController.viewControllers.firstObject;
//        [self prepareDebugSettingsVC:debugSettingsVC];
        
//        [_window setRootViewController:_navController];

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
