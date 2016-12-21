/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>
#import <Foundation/Foundation.h>

#import <BridgeEngine/BEDebugging.h>

// API only available from C++ and Objective C++
#ifdef __cplusplus

#include <limits>
#include <algorithm>
#include <string>

//------------------------------------------------------------------------------

#pragma mark - Utilities

namespace BE
{
    
    double nowInSeconds ();

} // BE
    
//------------------------------------------------------------------------------

#pragma mark - KDebug

#if BE_PROFILING

namespace BE
{
    
    enum class KDebugCode
    {
        None = 0,
        
        DisplayLink = 10,
        
        Reserved0 = 11,
        Reserved1 = 12,
        Reserved2 = 13,
        Reserved3 = 14,
        Reserved4 = 15,
        
        Reserved5 = 20,
        Reserved6 = 21,
        
        Reserved7 = 30,
        
        // Temporary values.
        TempTest1 = 80,
        TempTest2,
        TempTest3,
        TempTest4,
    };
    
    class KDebugSign
    {
    public:
        // Sign post over a region.
        static void start (KDebugCode code, uintptr_t arg1 = 0, int colorCode = 0);
        static void stop (KDebugCode code, uintptr_t arg1 = 0, int colorCode = 0);
        
        // Simple sign post.
        static void post (KDebugCode code, uintptr_t arg1 = 0, int colorCode = 0);
    };
    
    class KDebugScopedSign
    {
    public:
        KDebugScopedSign(KDebugCode code, uintptr_t arg1 = 0, int colorCode = 0, bool enabled = true)
        {
            _code = code;
            _arg1 = arg1;
            _colorCode = colorCode;
            _enabled = enabled;
            
            if (_enabled)
            {
                KDebugSign::start (code, arg1, colorCode);
            }
        }
        
        ~KDebugScopedSign()
        {
            if (_enabled)
            {
                KDebugSign::stop (_code, _arg1, _colorCode);
            }
        }
        
    private:
        KDebugCode _code = KDebugCode::None;
        uintptr_t _arg1 = 0;
        int _colorCode = 0;
        bool _enabled = true;
    };
    
} // BE

#endif // BE_PROFILING

/** Bridge Engine kdebug utilities
 These macros can be used to trigger system strace signposts and get fine-tuned profiling in Instruments.
 See https://developer.apple.com/videos/play/wwdc2016/411/ .
 Only enabled if BE_PROFILING is set to 1, and on iOS >= 10.0.
 */
#if BE_PROFILING
#  define BE_KDEBUG_SCOPED_SIGN(varName,...) BE::KDebugScopedSign varName (__VA_ARGS__)
#  define BE_KDEBUG_SIGN(...) BE::kdebugPost(__VA_ARGS__)
#else
#  define BE_KDEBUG_SCOPED_SIGN(varName, code, ...) BE_MULTI_STATEMENT_MACRO()
#  define BE_KDEBUG_SIGN(code, ...) BE_MULTI_STATEMENT_MACRO()
#endif

//------------------------------------------------------------------------------

#pragma mark - PerformanceMonitor

namespace BE
{

    struct OnlineVarianceEstimator
    {
        double n = 0.;
        double mean = 0.;
        double M2 = 0.;
        double variance = 0.;
        
        void update (double x)
        {
            n = n + 1.0;
            double delta = x - mean;
            mean = mean + delta/n;
            M2 = M2 + delta*(x - mean);
            variance = M2/(n - 1);
        }
    };
    
    // Utility class to monitor the performance (FPS, speed, latency) of a real-time system.
    class PerformanceMonitor
    {
    public:
        PerformanceMonitor (const std::string& name) : _name(name) {}
        
    public:
        const std::string& name () const { return _name; }
        
        double averageFpsFromSampleCount () const { return numSamples() < 2 ? 0. : numSamples() / samplingPeriodInSeconds(); }
        double samplingPeriodInSeconds () const { return isnan(_samplingPeriodStart) ? 0. : (_lastSampleTimestamp - _samplingPeriodStart); }
        double timestampOfFirstSample () const { return _samplingPeriodStart; }
        
        int numSamples () const { return _varianceEstimator.n; }
        
        double meanValue () const { return _varianceEstimator.mean; }
        double varianceValue () const { return _varianceEstimator.variance; }
        double minValue () const { return numSamples() > 0 ? _minValue : 0; }
        double maxValue () const { return numSamples() > 0 ? _maxValue : 0; }
        
    public:
        void addSampleWithTimestamp (const double sampleTimestamp, const double sampleValue)
        {
            be_assert (!isnan(sampleValue), "NaN should be filtered out first");
            
            // The first time we'll start the sampling period from the first sample.
            // Later on we'll start sampling from the last sample in startNewSequenceFromLastSample
            if (isnan(_samplingPeriodStart))
                _samplingPeriodStart = sampleTimestamp;
            
            _lastSampleTimestamp = sampleTimestamp;
            _varianceEstimator.update (sampleValue);
            _minValue = std::min(_minValue, sampleValue);
            _maxValue = std::max(_maxValue, sampleValue);
        }
        
        void addSample (double sampleValue)
        {
            addSampleWithTimestamp(nowInSeconds(), sampleValue);
        }
        
        void startNewSequenceFromLastSample ()
        {
            _varianceEstimator = OnlineVarianceEstimator();
            _minValue = std::numeric_limits<double>::max();
            _maxValue = std::numeric_limits<double>::lowest();
            
            // assumes the new sampling period restarts from the last sample
            _samplingPeriodStart = _lastSampleTimestamp;
            _lastSampleTimestamp = _samplingPeriodStart;
        }
        
    public:
        void showAveragePerSample ()
        {
            NSLog(@"%s avg/sample %.1f ms [%.1f - %.1f]",
                  _name.c_str(),
                  1e3*(meanValue()),
                  1e3*(minValue()),
                  1e3*(maxValue()));
        }
        
    private:
        std::string _name;
        OnlineVarianceEstimator _varianceEstimator;
        double _minValue = std::numeric_limits<double>::max();
        double _maxValue = std::numeric_limits<double>::lowest();
        double _samplingPeriodStart = NAN;
        double _lastSampleTimestamp = NAN;
    };
    
    class ScopeProfiler
    {
    public:
        ScopeProfiler (PerformanceMonitor& monitor, int showResultsPeriod = 30)
        : _monitor (monitor)
        , _showResultsPeriod (showResultsPeriod)
        , _startTime (nowInSeconds())
        {}
        
        ~ScopeProfiler ()
        {
            double endTime = nowInSeconds();
            _monitor.addSample (endTime - _startTime);
            
            if (_monitor.numSamples() >= _showResultsPeriod)
            {
                NSLog(@"%s avg/sample = %.1f ms [%.1f - %.1f], FPS = %.1f",
                      _monitor.name().c_str(),
                       1e3*_monitor.meanValue(),
                       1e3*_monitor.minValue(),
                       1e3*_monitor.maxValue(),
                      _monitor.averageFpsFromSampleCount());
                
                _monitor.startNewSequenceFromLastSample();
            }
        }
        
    private:
        PerformanceMonitor& _monitor;
        double _startTime;
        int _showResultsPeriod;
    };
    
#if BE_PROFILING
#  define BE_SCOPE_PROFILER(VarName, MonitorName, Period) BE::ScopeProfiler VarName(MonitorName, Period)
#else
#  define BE_SCOPE_PROFILER(VarName, MonitorName, Period) BE_MULTI_STATEMENT_MACRO()
#endif

} // BE

#endif // __cplusplus
