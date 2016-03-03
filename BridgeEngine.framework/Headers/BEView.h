/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import "BridgeEngineAPI.h"
#import <UIKit/UIView.h>

//------------------------------------------------------------------------------

// The BEView class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
BE_API
@interface BEView : UIView

@end
