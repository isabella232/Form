//
//  Styling.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-10-22.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

/// Marker protocol for styles that allows them to be restyled.
public protocol Style {}

public extension Style {
    /// Creates a new style by restyling an existing Style.
    ///
    ///     let myStyle = TextStyle.defaultLabel.restyled { $0.color = .red }
    func restyled(_ styler: (inout Self) -> ()) -> Self {
        var style = self
        styler(&style)
        return style
    }
}

/// Protocol for styles that might be updated based on context or application updates.
public protocol DynamicStyle {
    /// The type of style generated by `self`.
    associatedtype Style: Form.Style

    /// The type of input used for generating styles.
    associatedtype StyleInput

    /// A generator of styles from style inputs.
    var styleGenerator: (StyleInput) -> Style { get set }
}

public extension DynamicStyle {
    /// Generate a style based on `styleInput`
    func style(from styleInput: StyleInput) -> Style {
        return styleGenerator(styleInput)
    }

    /// Returns a new instance of `Self` where `restyler` will be called to transform a style giving an input.
    func restyledWithStyleAndInput(_ restyler: @escaping (inout Style, StyleInput) -> ()) -> Self {
        var restyled = self
        restyled.styleGenerator = { input in
            var style = self.style(from: input)
            restyler(&style, input)
            return style
        }
        return restyled
    }

    /// Returns a new instance of `Self` where `restyler` will be called to transform a style.
    ///
    ///     let myStyle = SectionStyle.default.restyled { $0.minRowHeight = 80 }
    func restyled(_ restyler: @escaping (inout Style) -> ()) -> Self {
        var restyled = self
        restyled.styleGenerator = { input in
            var style = self.style(from: input)
            restyler(&style)
            return style
        }
        return restyled
    }
}

/// Conforming types are styled using a `DynamicStyle`.
public protocol DynamicStylable {
    associatedtype DynamicStyle: Form.DynamicStyle

    var dynamicStyle: DynamicStyle { get }
    func applyStyle(_ style: DynamicStyle.Style)
}

public extension DynamicStylable where Self: UIView, DynamicStyle.StyleInput == UITraitCollection {
    /// Returns the currently used style.
    var currentStyle: DynamicStyle.Style {
        return dynamicStyle.style(from: traitCollectionWithFallback)
    }

    /// Applies the currently used style.
    func applyStyling() {
        applyStyle(currentStyle)
    }

    /// Apply the currently used style only if `traitCollectionWithFallback` has been updated.
    func applyStylingIfNeeded() {
        let current = traitCollectionWithFallback
        let prev = associatedValue(forKey: &prevTraitKey) as UITraitCollection?

        if let prev = prev, prev == current {
            return
        }

        setAssociatedValue(current, forKey: &prevTraitKey)
        applyStyle(currentStyle)
    }
}

private var prevTraitKey = false
