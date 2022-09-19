//
//  MonetaryCounterView.swift
//  MonetaryCounterView
//
//  Created by Davide Ceresola on 22/02/22.
//

import UIKit

public class MonetaryCounterView: UILabel {
    
    private lazy var contentView: UIStackView = {
        
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .leading
        
        return view
        
    }()
    
    public private(set) lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    public var duration: CFTimeInterval = 0.4
    
    public var leftView: UIView? = nil {
        didSet {
            updateForLeftView(oldValue: oldValue)
        }
    }
    
    public override var font: UIFont? {
        didSet {
            applyToLabels { $0.font = font }
        }
    }
    
    public override var textColor: UIColor? {
        didSet {
            applyToLabels { $0.textColor = textColor }
        }
    }
    
    public var highlightedColor: UIColor = .red
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    public var number: NSDecimalNumber? {
        didSet {
            update(with: oldValue)
            updateMaxPreferredFont()
            if let number = number {
                accessibilityValue = numberFormatter.string(from: number)
            } else {
                accessibilityValue = attributedText?.string ?? text
            }
        }
    }
    
    public override var text: String? {
        willSet {
            updateForText()
            accessibilityValue = text
        }
    }
    
    public override var attributedText: NSAttributedString? {
        willSet {
            updateForText()
            accessibilityValue = attributedText?.string ?? text
        }
    }
    
    private func commonInit() {
        
        clipsToBounds = true
        
        font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        textColor = UIColor.darkText
        
        configure(with: Locale.current.currencyCode ?? "EUR")
        
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
        ])
        
        setupAccessibility()
        
    }
    
    private func setupAccessibility() {
        
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        updateMaxPreferredFont()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateMaxPreferredFont()
    }
    
    public func configure(with currencyCode: String) {
        
        numberFormatter.currencyCode = currencyCode

        let identifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currencyCode])
        let locale = Locale(identifier: identifier)
        
        if let currencySymbol = locale.currencySymbol {
            numberFormatter.currencySymbol = currencySymbol
        }
        
    }
    
    private func updateForText() {
        
        contentView.arrangedSubviews
            .filter { $0 != leftView }
            .forEach {
                contentView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        
    }
    
    private func update(with oldNumber: NSDecimalNumber?) {
        
        guard let oldNumber = oldNumber else {
            return setupForInitial()
        }
        
        guard let newNumber = number else {
            return contentView.arrangedSubviews
                .filter { $0 != leftView }
                .forEach {
                    contentView.removeArrangedSubview($0)
                    $0.removeFromSuperview()
                }
        }
        
        //  if the sign changes, simply reconfigure
        if oldNumber.decimalValue.sign != newNumber.decimalValue.sign {
            return setupForInitial()
        }
        
        guard var oldNumberString = numberFormatter.string(from: oldNumber),
              let newNumberString = numberFormatter.string(from: newNumber) else {
                  return
              }
        
        let diff = newNumberString.count - oldNumberString.count
        
        if diff != 0 {
            adjustLabelsForDiff(diff)
        }
        
        let isIncrease = newNumber.compare(oldNumber) == .orderedDescending
        
        if !isIncrease {
            oldNumberString = oldNumberString.substring(fromIndex: abs(diff))
        }
        
        var changedIndexes: Set<Int> = Set()
        
        for i in 0..<newNumberString.count {
            
            let label = contentView.arrangedSubviews[i] as? MonetaryLabel
            
            let newChar = newNumberString[i]
            
            let hasText = label?.text?.isEmpty == false
            
            guard hasText else {
                label?.text = newChar
                changedIndexes.insert(i)
                continue
            }
            
            let oldChar: String
            
            if isIncrease {
                oldChar = oldNumberString[i - diff]
            } else {
                oldChar = oldNumberString[i]
            }
            
            if let oldInt = Int(oldChar), let newInt = Int(newChar) {
                
                if isIncrease {
                    if label?.animateUp(with: duration, from: oldInt, to: newInt) == true {
                        changedIndexes.insert(i)
                    }
                } else {
                    if label?.animateDown(with: duration, from: oldInt, to: newInt) == true {
                        changedIndexes.insert(i)
                    }
                }
                
            }
            
        }
        
        //  animate text changes
        let highlightedTextColor = self.highlightedColor
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            changedIndexes.forEach { index in
                let label = self?.contentView.arrangedSubviews[index] as? MonetaryLabel
                label?.animateTextColor(highlightedColor: highlightedTextColor)
            }
        }
        
    }
    
    private func setupForInitial() {
        
        guard let number = number, let numberString = numberFormatter.string(from: number) else {
            return
        }
        
        let components = numberString.map { singleChar -> MonetaryLabel in
            
            let label = generateLabelComponent()
            label.text = String(singleChar)
            return label
            
        }
        
        contentView.arrangedSubviews
            .filter { $0 != leftView }
            .forEach {
                contentView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        
        components.reversed().forEach { contentView.insertArrangedSubview($0, at: 0) }
        
    }
    
    private func adjustLabelsForDiff(_ diff: Int) {
        
        let startingIndex = contentView.arrangedSubviews
            .compactMap { $0 as? MonetaryLabel }
            .firstIndex(where: { Int($0.text ?? "") != nil }) ?? 0
        
        if diff > 0 {
            
            for _ in 0..<diff {
                let label = generateLabelComponent()
                contentView.insertArrangedSubview(label, at: startingIndex)
            }
            
        } else {
            
            for _ in 0..<abs(diff) {
                let viewToRemove = contentView.arrangedSubviews[startingIndex]
                contentView.removeArrangedSubview(viewToRemove)
                viewToRemove.removeFromSuperview()
            }
            
        }
        
    }
    
    private func generateLabelComponent() -> MonetaryLabel {
        
        let label = MonetaryLabel()
        label.accessibilityElementsHidden = true
        label.textColor = textColor
        label.font = font
        
        return label
        
    }
    
    private func updateMaxPreferredFont() {
        
        guard var currentFont = font else {
            return
        }
        
        applyToLabels { $0.font = currentFont }
        
        var contentSizeWidth = contentView.arrangedSubviews
            .compactMap { $0 as? MonetaryLabel }
            .compactMap { $0.text }
            .map { NSString(string: $0).size(withAttributes: [.font: currentFont]).width }
            .reduce(0, +)
        
        var availableWidth = frame.width
        
        if let view = leftView {
            availableWidth -= view.bounds.width
        }
        
        while contentSizeWidth > availableWidth && availableWidth > .zero {
            currentFont = currentFont.withSize(currentFont.pointSize - 1)
            contentSizeWidth = contentView.arrangedSubviews
                .compactMap { $0 as? MonetaryLabel }
                .compactMap { $0.text }
                .map { NSString(string: $0).size(withAttributes: [.font: currentFont]).width }
                .reduce(0, +)
        }
        
        applyToLabels { $0.font = currentFont }
        
    }
    
    private func updateForLeftView(oldValue: UIView?) {
        
        if let view = leftView {
            contentView.addArrangedSubview(view)
        } else if let oldView = oldValue {
            contentView.removeArrangedSubview(oldView)
            oldView.removeFromSuperview()
        }
        
    }
    
}

private extension MonetaryCounterView {
    
    var labels: [UILabel] {
        return contentView.arrangedSubviews.compactMap { $0 as? UILabel }
    }
    
    func applyToLabels(_ apply: ((UILabel) -> Void)) {
        labels.forEach { apply($0) }
    }
    
}

private extension MonetaryCounterView {
    
    class MonetaryLabel: UILabel {
        
        func animateUp(with duration: CFTimeInterval, from: Int, to: Int) -> Bool {
            
            layer.removeAllAnimations()
            
            var finalTo = to
            
            if to < from {
                finalTo += 10
            }
            
            if finalTo == from {
                return false
            }
            
            let singleDelay = duration / Double(finalTo - from)
            
            var currentIteration = 0
            
            for i in from..<finalTo {
                let current = i + 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + singleDelay * Double(currentIteration)) {
                    self.layer.animateUp(with: singleDelay)
                    self.text = String(String(current).last!)
                }
                
                currentIteration += 1
                
            }
            
            return true
            
        }
        
        func animateDown(with duration: CFTimeInterval, from: Int, to: Int) -> Bool {
            
            layer.removeAllAnimations()
            
            var finalFrom = from
            
            if finalFrom < to {
                finalFrom += 10
            }
            
            if finalFrom == to {
                return false
            }
            
            let singleDelay = duration / Double(finalFrom - to)
            
            var currentIteration = 0
            
            for i in (to..<finalFrom).reversed() {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + singleDelay * Double(currentIteration)) {
                    self.layer.animateDown(with: singleDelay)
                    self.text = String(String(i).last!)
                }
                
                currentIteration += 1
                
            }
            
            return true
            
        }
        
    }
    
}

private extension CALayer {
    
    func animateUp(with duration: CFTimeInterval) {
        
        let animation = CATransition()
        animation.beginTime = CACurrentMediaTime()
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = duration
        animation.type = .push
        animation.subtype = .fromTop
        
        self.add(animation, forKey: CATransitionType.push.rawValue)
    }
    
    func animateDown(with duration: CFTimeInterval) {
        
        let animation = CATransition()
        animation.beginTime = CACurrentMediaTime()
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = duration
        animation.type = .push
        animation.subtype = .fromBottom
        
        self.add(animation, forKey: CATransitionType.push.rawValue)
    }
    
}

private extension UILabel {
    
    func animateTextColor(highlightedColor: UIColor) {
        
        let currentColor = textColor
        
        let changeColor = CATransition()
        changeColor.duration = 3

        CATransaction.begin()

        CATransaction.setCompletionBlock { [weak self] in
            self?.layer.add(changeColor, forKey: nil)
            self?.textColor = currentColor
        }

        textColor = highlightedColor

        CATransaction.commit()
        
    }
    
}

private extension String {
    
    var length: Int {
        return count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
}
