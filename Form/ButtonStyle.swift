//
//  ButtonStyle.swift
//  Form
//
//  Created by Måns Bernhardt on 2015-11-25.
//  Copyright © 2015 iZettle. All rights reserved.
//

import UIKit

public struct ButtonStyle: Style {
    public var buttonType: UIButtonType
    public var contentInsets: UIEdgeInsets
    public var preferredMinimumSize: MinimumSize
    public var alignment: UIControlContentHorizontalAlignment
    public var minimumScalingFactor: CGFloat
    public var states: [UIControlState: ButtonStateStyle]

    public init(buttonType: UIButtonType = .custom, contentInsets: UIEdgeInsets = .zero, preferredMinimumSize: MinimumSize = .none, minimumScalingFactor: CGFloat = 1.0, alignment: UIControlContentHorizontalAlignment = .center, states: [UIControlState: ButtonStateStyle]) {
        self.buttonType = buttonType
        self.contentInsets = contentInsets
        self.preferredMinimumSize = preferredMinimumSize
        self.minimumScalingFactor = minimumScalingFactor
        self.alignment =  alignment
        self.states = states
    }
}

public extension ButtonStyle {
    init(buttonType: UIButtonType = .custom, contentInsets: UIEdgeInsets = .zero, preferredMinimumSize: MinimumSize = .none, minimumScalingFactor: CGFloat = 1.0, alignment: UIControlContentHorizontalAlignment = .center, normal: ButtonStateStyle? = nil, highlighted: ButtonStateStyle? = nil, disabled: ButtonStateStyle? = nil, selected: ButtonStateStyle? = nil) {
        self.init(buttonType: buttonType, contentInsets: contentInsets, preferredMinimumSize: preferredMinimumSize, minimumScalingFactor: minimumScalingFactor, alignment: alignment, states: .init(normal: normal, highlighted: highlighted, disabled: disabled, selected: selected))
    }
}

public extension ButtonStyle {
    static let system = ButtonStyle(button: UIButton(type: .system))
    static var `default`: ButtonStyle { return DefaultStyling.current.button }
}

public extension UIButton {
    convenience init(title: DisplayableString, style: ButtonStyle = .default) {
        self.init(type: style.buttonType)
        setTitle(title, for: .normal)
        setStyle(style)
        sizeToFit()
    }
}

public extension UIButton {
    var style: ButtonStyle {
        get {
            return associatedValue(forKey: &styleKey, initial: ButtonStyle(buttonType: buttonType, contentInsets: contentEdgeInsets, alignment: contentHorizontalAlignment, normal: buttonStyle(for: .normal), highlighted: buttonStyle(for: .highlighted), disabled: buttonStyle(for: .disabled), selected: buttonStyle(for: .selected)))
        }
        set {
            setStyle(newValue)
        }
    }

    func setTitle(_ title: DisplayableString, for state: UIControlState = .normal) {
        self.setTitle(title.displayValue as String?, for: state)
        accessibilityIdentifier = title.accessibilityIdentifier
        accessibilityLabel = title.displayValue
        setStyle(style)
    }

    func clearTitle(for state: UIControlState = .normal) {
        setTitle(nil, for: state)
        setStyle(style)
    }
}

extension ButtonStateStyle {
    init(button: UIButton, state: UIControlState) {
        backgroundImage = button.backgroundImage(for: state)
        let attributes = button.attributedTitle(for: state)?.attributes(at: 0, effectiveRange: nil) ?? [:]
        text = TextStyle(font: attributes[.font] as? UIFont ?? button.titleLabel?.font ?? .systemFont(ofSize: 16), color: button.titleColor(for: state) ?? .black)
    }
}

extension Dictionary where Key == UIControlState, Value == ButtonStateStyle {
    init(button: UIButton) {
        self.init(normal: .init(button: button, state: .normal),
                  highlighted: .init(button: button, state: .highlighted),
                  disabled: .init(button: button, state: .disabled),
                  selected: .init(button: button, state: .selected))
    }
}

extension ButtonStyle {
    init(button: UIButton) {
        self.init(buttonType: button.buttonType, contentInsets: button.contentEdgeInsets, alignment: button.contentHorizontalAlignment, states: .init(button: button))
    }
}

private extension UIButton {
    func applyStateStyle(_ style: ButtonStateStyle, forState state: UIControlState) {
        setBackgroundImage(style.backgroundImage, for: state)
        if style.text.isPlain {
            setTitleColor(style.text.color, for: state)
            if state == .normal {
                titleLabel?.styledText = StyledText(text: title(for: .normal) ?? "", style: style.text)
            }
        } else {
            let attrTitle = NSAttributedString(string: title(for: state) ?? "", attributes: style.text.attributes)
            setAttributedTitle(attrTitle, for: state)
        }
    }

    func buttonStyle(for state: UIControlState) -> ButtonStateStyle? {
        switch state {
        case UIControlState.normal, UIControlState.disabled, UIControlState.selected, UIControlState.highlighted: break
        default: fatalError("State not supported")
        }

        guard let currentStyle: ButtonStyle = associatedValue(forKey: &styleKey) else {
            let textStyle = TextStyle(font: titleLabel?.font ?? UIFont.systemFont(ofSize: 12), color: titleColor(for: state) ?? UIColor.black, alignment: titleLabel?.textAlignment ?? .center)
            return ButtonStateStyle(backgroundImage: backgroundImage(for: state), text: textStyle)
        }
        return currentStyle.states[state]
    }

    func setStyle(_ style: ButtonStyle) {
        assert(style.buttonType == buttonType)
        setAssociatedValue(style, forKey: &styleKey)
        self.contentEdgeInsets = style.contentInsets
        self.contentHorizontalAlignment = style.alignment
        updateMinimumSize(style.preferredMinimumSize)
        titleLabel?.minimumScaleFactor = style.minimumScalingFactor

        for state in UIControlState.standardStates {
            let stateStyle = style.states[state]

            setBackgroundImage(stateStyle?.backgroundImage, for: state)

            guard let style = stateStyle else {
                setTitleColor(nil, for: state)
                continue
            }

            if style.text.isPlain {
                setTitleColor(style.text.color, for: state)
                if state == .normal {
                    titleLabel?.styledText = StyledText(text: title(for: .normal) ?? "", style: style.text)
                }
            } else {
                let attrTitle = NSAttributedString(string: title(for: state) ?? "", attributes: style.text.attributes)
                setAttributedTitle(attrTitle, for: state)
            }
        }
    }

    func updateMinimumSize(_ minimumSize: MinimumSize) {
        updateConstraint(for: widthAnchor, with: minimumSize.width, constraintKey: &widthConstraintKey)
        updateConstraint(for: heightAnchor, with: minimumSize.height, constraintKey: &heightConstraintKey)
    }

    func updateConstraint(for anchor: NSLayoutDimension, with value: CGFloat?, constraintKey key: UnsafeRawPointer) {
        let constant = value ?? 0
        let constraint = associatedValue(forKey: key, initial: anchor >= constant)
        constraint.priority = .defaultHigh
        constraint.constant = constant
        constraint.isActive = (value != nil)
    }
}

private var styleKey = 0
private var widthConstraintKey = 0
private var heightConstraintKey = 0
