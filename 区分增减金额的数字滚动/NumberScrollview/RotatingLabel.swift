//
//  ViewController.swift
//  NumberScrollview
//
//  Created by satoshi_umaM1 on 2023/12/6.
//

import UIKit

/// 一个在文本更改时执行动画的标签。
public class RotatingLabel: UIView {
    /// 动画的方向。
    public enum Direction {
        /// 递增方向。
        case increment
        /// 递减方向。
        case decrement
    }

    /// 文本颜色。
    ///
    /// 默认为 `UIColor.label`。
    public var textColor: UIColor = .label {
        didSet {
            updateTextColor()
        }
    }

    /// 在值增加时闪烁的颜色。
    ///
    /// 默认为 `UIColor.systemGreen`。
    public var incrementingColor: UIColor = .systemGreen

    /// 在值减少时闪烁的颜色。
    ///
    /// 默认为 `UIColor.systemRed`。
    public var decrementingColor: UIColor = .systemRed

    /// 用于呈现文本的字体。
    public var font: UIFont = defaultFont() {
        didSet {
            updateFont()
        }
    }

    /// 一个布尔值，指示标签是否在设备内容大小类别更改时自动更新其字体。
    ///
    /// 要使此属性生效，标签的字体必须设置为与动态类型兼容的字体。
    /// 有关更多信息，请参见[自动缩放字体](https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically#3111283)。
    ///
    /// 默认为 `false`。
    public var adjustsFontForContentSizeCategory: Bool = false {
        didSet {
            updateContentSizeCategoryAdjustmentPreference()
        }
    }

    /// 用于对比旧值和新值的函数。
    ///
    /// 默认为 `DiffingFunction.default`。
    public var diffingFunction: DiffingFunction = .default

    /// 当前文本。
    public var text: String? {
        get { internalText }
        set {
            setText(newValue ?? "", animated: false)
        }
    }

    /// 动画的持续时间。
    public var animationDuration: TimeInterval = 0.2

    /// 动画的定时参数。
    ///
    /// 使用 `UISpringTimingParameters` 来创建 "弹簧效果" 动画，或使用 `UICubicTimingParameters` 来创建立方贝塞尔定时曲线。
    ///
    /// - [UISpringTimingParameters](https://developer.apple.com/documentation/uikit/uispringtimingparameters)
    /// - [UICubicTimingParameters](https://developer.apple.com/documentation/uikit/uicubictimingparameters)
    public var animationTimingParameters: UITimingCurveProvider = UISpringTimingParameters(
        mass: 0.03,
        stiffness: 20,
        damping: 0.9,
        initialVelocity: CGVector(dx: 4.8, dy: 4.8)
    )

    override public var intrinsicContentSize: CGSize {
        var width = CGFloat.zero
        var height = CGFloat.zero

        for frame in calculateFrames() {
            width += frame.value.width
            height = max(height, frame.value.height)
        }

        return CGSize(width: width, height: height)
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return intrinsicContentSize
    }

    private var internalText: String? {
        didSet {
            accessibilityLabel = internalText
        }
    }

    private var labels: [UILabel] = []

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    /// 设置标签的文本。
    ///
    /// 此方法将根据旧文本和新文本自动确定动画的方向。根据文本的格式，动画方向可能不总是正确。在这种情况下，使用 `setText(_:animated:direction:)`。
    ///
    /// - Parameters:
    ///   - newText: 新文本。
    ///   - animated: 是否动画更改。
    public func setText(_ newText: String?, animated: Bool) {
        let direction: Direction = (newText ?? "") >= (internalText ?? "")  ? .increment   : .decrement

        setText(newText, animated: animated, direction: direction)
    }

    /// 设置标签的文本。
    ///
    /// - Parameters:
    ///   - newText: 新文本。
    ///   - animated: 是否动画更改。
    ///   - direction: 动画的方向。
    public func setText(_ newText: String?, animated: Bool, direction: Direction) {
        guard newText != internalText else { return }
        updateContent(from: internalText ?? "", to: newText ?? "", animated: animated, direction: direction)
        internalText = newText
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        let frames = calculateFrames()
        for label in labels {
            label.frame = frames[ObjectIdentifier(label), default: label.frame]
        }
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }
}

extension RotatingLabel {
    private static func defaultFont() -> UIFont {
        #if os(tvOS)
            // 在 tvOS 上，`UILabel.font` 默认为 `.headline` 文本样式。
            return .preferredFont(forTextStyle: .headline)
        #else
            // 在 iOS 上，`UILabel.font` 默认为固定大小的字体。
            return .systemFont(ofSize: UIFont.labelFontSize)
        #endif
    }

    // swift lint: disable: next function_body_length
    private func updateContent(from oldText: String, to newText: String, animated: Bool, direction: Direction) {
        var toBeRemoved: [UILabel] = []
        var newLabels: [UILabel] = []

        let diff = diffingFunction(from: oldText, to: newText)
        for operation in diff {
            switch operation {
            case .remove(offset: let offset, element: _):
                let label = labels.remove(at: offset)
                toBeRemoved.append(label)
            case let .insert(offset: offset, element: element):
                let label = UILabel()
                label.text = String(element)
                label.font = font
                label.adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory

                labels.insert(label, at: offset)
                newLabels.append(label)

                addSubview(label)
            }
        }

        if animated {
            let frames = calculateFrames()

            let translationOffset = font.pointSize

            newLabels.forEach { label in
                label.frame = frames[ObjectIdentifier(label), default: label.frame]
                label.alpha = 0

                label.transform = CGAffineTransform(
                    translationX: 0,
                    y: direction == .increment ? translationOffset : -translationOffset
                ).scaledBy(x: 0.7, y: 0.7)

                label.textColor = direction == .increment
                    ? incrementingColor
                    : decrementingColor
            }

            let animator = UIViewPropertyAnimator(duration: animationDuration, timingParameters: animationTimingParameters)
            animator.isInterruptible = true

            animator.addAnimations { [self] in
                toBeRemoved.forEach { label in
                    label.alpha = 0
                    label.transform = CGAffineTransform(
                        translationX: 0,
                        y: direction == .increment ? -translationOffset : translationOffset
                    ).scaledBy(x: 0.5, y: 0.5)
                }

                newLabels.forEach { label in
                    label.alpha = 1
                    label.transform = .identity
                }

                labels.forEach { label in
                    label.frame = frames[ObjectIdentifier(label), default: label.frame]
                }
            }

            animator.addCompletion { [self] _ in
                toBeRemoved.forEach { $0.removeFromSuperview() }
                newLabels.forEach { $0.textColor = textColor }
            }

            animator.startAnimation()
        } else {
            toBeRemoved.forEach { $0.removeFromSuperview() }
            setNeedsLayout()
        }

        invalidateIntrinsicContentSize()
    }

    private func calculateFrames() -> [ObjectIdentifier: CGRect] {
        var result: [ObjectIdentifier: CGRect] = [:]

        var x: CGFloat = 0

        for label in labels {
            let size = label.intrinsicContentSize

            result[ObjectIdentifier(label)] = CGRect(x: x, y: 0, width: size.width, height: size.height)
            x += size.width
        }

        return result
    }
}

// MARK: - 外观

extension RotatingLabel {
    private func updateFont() {
        for label in labels {
            label.font = font
        }

        invalidateIntrinsicContentSize()
    }

    private func updateTextColor() {
        for label in labels {
            label.textColor = textColor
        }
    }

    private func updateContentSizeCategoryAdjustmentPreference() {
        for label in labels {
            label.adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory
        }

        invalidateIntrinsicContentSize()
    }
}
