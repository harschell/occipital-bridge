/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#if BE_API_EXPORTS
#   define BE_API __attribute__((visibility("default")))
#else
#   define BE_API
#endif
