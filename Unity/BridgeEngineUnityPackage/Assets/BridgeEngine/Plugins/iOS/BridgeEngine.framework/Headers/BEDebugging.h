/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>
#import <Foundation/Foundation.h>

//------------------------------------------------------------------------------

#pragma mark - Useful macros.

// Need to define them as extern to enable C linkage, otherwise we'll get missing symbol errors at link time
// if these symbols are referenced from C files (because of C++ mangling changing the function signature).
#if __cplusplus
# define BE_C_API extern "C"
#else
# define BE_C_API
#endif

#define BE_MULTI_STATEMENT_MACRO(X) do { X } while(0)

//------------------------------------------------------------------------------

#pragma mark - Logging

/// Change the verbosity level of BridgeEngine. Default is 0 (quiet).
BE_API void BESetVerbosityLevel (int level);

/// Equivalent of [STWirelessLog broadcastLogsToWirelessConsoleAtAddress] in the Structure SDK.
BE_API void BEStartLoggingToWirelessConsole (NSString* ipAdress, int port, NSError* __autoreleasing * error);

BE_API BE_C_API void be_print_log (const char* prefix, const char* functionName, const char* fmt, ...);
#if DEBUG
#define be_dbg(...)  BE_MULTI_STATEMENT_MACRO ( be_print_log ("BE_DBG", __PRETTY_FUNCTION__, __VA_ARGS__ ); )
#else
#define be_dbg(...) BE_MULTI_STATEMENT_MACRO()
#endif // ndef DEBUG

#ifdef __OBJC__
BE_API BE_C_API void be_print_log_NS (const char* prefix, const char* functionName, NSString *format, ...);
#if defined(DEBUG)
# define be_NSDbg(...)  BE_MULTI_STATEMENT_MACRO ( be_print_log_NS ("BE_DBG", __PRETTY_FUNCTION__, __VA_ARGS__); )
#else
# define be_NSDbg(...) BE_MULTI_STATEMENT_MACRO()
#endif // ndef DEBUG
#endif // OBJC

//------------------------------------------------------------------------------

#pragma mark - Assertions

BE_API BE_C_API void be_assert_failure(const char* where, const char* fileName, int line, const char* cond, const char* whatFormat, ...);

/**
 * Assertions. Only enabled when DEBUG is defined.
 */
#if DEBUG
// Sample usage: be_assert (i != 42, "i is %d, but it should be 42!", i);
# define be_assert(cond, ...)  BE_MULTI_STATEMENT_MACRO ( if (!(cond)) { be_assert_failure(__PRETTY_FUNCTION__, __FILE__, __LINE__, #cond, __VA_ARGS__); } else {} )
#else
# define be_assert(cond,...) BE_MULTI_STATEMENT_MACRO()
#endif
