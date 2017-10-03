/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>
#import <UIKit/UIView.h>

//------------------------------------------------------------------------------

/** UIView subclass to wrap a CoreAnimation `CAEAGLLayer`.
 The view content is basically an EAGL surface you can render your OpenGL scene into.
 @note setting the view non-opaque will only work if the EAGL surface has an alpha channel.
*/
BE_API
@interface BEView : UIView
@end
