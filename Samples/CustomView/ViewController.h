/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *startStopScanningButton;
@property (weak, nonatomic) IBOutlet UIButton *enterTrackingModeButton;
@property (weak, nonatomic) IBOutlet UIButton *enterScanningModeButton;
@property (weak, nonatomic) IBOutlet UIButton *resetScanningButton;

- (IBAction)enterTrackingModeButtonPressed:(id)sender;

- (IBAction)enterScanningModeButtonPressed:(id)sender;
- (IBAction)resetScanningButtonPressed:(id)sender;
- (IBAction)startStopScanningButtonPressed:(id)sender;

@end
