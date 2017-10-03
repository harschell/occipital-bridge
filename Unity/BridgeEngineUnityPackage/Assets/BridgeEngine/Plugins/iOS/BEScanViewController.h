/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <UIKit/UIKit.h>

@protocol BEScanViewControllerDelegate <NSObject>
- (void) scanViewDidFinish;
@end

@interface BEScanViewController : UIViewController
@property(nonatomic, weak) id<BEScanViewControllerDelegate> delegate;

- (void) disconnectFromBE;
@end
