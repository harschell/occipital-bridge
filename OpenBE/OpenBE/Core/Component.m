/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "Component.h"

@interface Component()
@property (atomic) bool _isComponentEnabled;
@end

@implementation Component

- (id) init {
    self = [super init];
    self._isComponentEnabled = true;
    return self;
}

- (void) start {
    
}

- (void) setEnabled:(bool)enabled {
    self._isComponentEnabled = enabled;
}

- (bool) isEnabled {
    return self._isComponentEnabled;
}


@end
