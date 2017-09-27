//
// Created by John Austin on 9/27/17.
// Copyright (c) 2017 Occipital. All rights reserved.
//

import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension Double {
    func mapUnitToRange(limits: ClosedRange<Double>, clamp: Bool = false) -> Double {
        let unitValue = clamp ? self.clamped(to: 0.0...1.0) : self;
        return limits.lowerBound + (limits.upperBound - limits.lowerBound) * unitValue;
    }

    func mapValueToUnit(limits: ClosedRange<Double>, clamp: Bool = false) -> Double {
        let fullValue = clamp ? self.clamped(to: limits) : self;
        return (fullValue - limits.lowerBound) / (limits.upperBound - limits.lowerBound);
    }

    func mapBetweenRanges(from: ClosedRange<Double>, to: ClosedRange<Double>, clamp: Bool = false) -> Double {
        let unitValue = self.mapValueToUnit(limits: from, clamp: clamp);
        return unitValue.mapUnitToRange(limits: to, clamp: clamp);
    }
}

// MARK: Double Extension

public extension Double {

    /// Returns a random floating point number between 0.0 and 1.0, inclusive.
    public static var random: Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }

    /// Random double between 0 and n-1.
    ///
    /// - Parameter n:  Interval max
    /// - Returns:      Returns a random double point number between 0 and n max
    public static func random(limits: ClosedRange<Double>) -> Double {
        return Double.random * (limits.upperBound - limits.lowerBound) + limits.lowerBound;
    }
}