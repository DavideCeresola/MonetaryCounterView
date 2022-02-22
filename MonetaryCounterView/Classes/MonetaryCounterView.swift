//
//  MonetaryCounterView.swift
//  MonetaryCounterView
//
//  Created by Davide Ceresola on 22/02/22.
//

import UIKit

public class MonetaryCounterView: UIView {
    
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
    
    public var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) {
        didSet {
            updateMaxPreferredFont()
        }
    }
    
    public var textColor: UIColor = UIColor.darkText {
        didSet {
            contentView.arrangedSubviews
                .compactMap { $0 as? MonetaryLabel }
                .forEach { $0.textColor = textColor }
        }
    }
    
    public var highlightedTextColor: UIColor = .red
    
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
        }
    }
    
    public var text: String? {
        didSet {
            update(with: oldValue)
            updateMaxPreferredFont()
        }
    }
    
    private func commonInit() {
        
        configure(with: Locale.current.currencyCode ?? "EUR")
        
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
        ])
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if contentView.frame.width > .zero {
            updateMaxPreferredFont()
        }
        
    }
    
    public func configure(with currencyCode: String) {
        
        numberFormatter.currencyCode = currencyCode

        let identifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currencyCode])
        let locale = Locale(identifier: identifier)
        
        if let currencySymbol = locale.currencySymbol {
            numberFormatter.currencySymbol = currencySymbol
        }
        
    }
    
    private func update(with oldText: String?) {
        
        contentView.arrangedSubviews.forEach {
            contentView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        guard let newText = text else {
            return
        }
        
        let labels = newText.map { char -> UILabel in
            let label = generateLabelComponent()
            label.text = String(char)
            return label
        }
        
        labels.forEach { contentView.addArrangedSubview($0) }
        
    }
    
    private func update(with oldNumber: NSDecimalNumber?) {
        
        guard let oldNumber = oldNumber else {
            return setupForInitial()
        }
        
        guard let newNumber = number else {
            return contentView.arrangedSubviews.forEach {
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
        let highlightedTextColor = self.highlightedTextColor
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
        
        contentView.arrangedSubviews.forEach {
            contentView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        components.forEach { contentView.addArrangedSubview($0) }
        
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
        label.textColor = textColor
        label.font = font
        
        return label
        
    }
    
    private func updateMaxPreferredFont() {
        
        var currentFont = font
        
        var contentSizeWidth = contentView.arrangedSubviews
            .compactMap { $0 as? MonetaryLabel }
            .compactMap { $0.text }
            .map { NSString(string: $0).size(withAttributes: [.font: currentFont]).width }
            .reduce(0, +)
        
        let availableWidth = frame.width - layoutMargins.left - layoutMargins.right
        
        while contentSizeWidth > availableWidth && availableWidth > .zero {
            currentFont = currentFont.withSize(currentFont.pointSize - 1)
            contentSizeWidth = contentView.arrangedSubviews
                .compactMap { $0 as? MonetaryLabel }
                .compactMap { $0.text }
                .map { NSString(string: $0).size(withAttributes: [.font: currentFont]).width }
                .reduce(0, +)
        }

        contentView.arrangedSubviews
            .compactMap { $0 as? MonetaryLabel }
            .forEach { $0.font = currentFont }
        
    }
    
}

private extension MonetaryCounterView {
    
    class MonetaryLabel: UILabel {
        
        func animateUp(with duration: CFTimeInterval, from: Int, to: Int) -> Bool {
            
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
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.duration = duration
        animation.type = kCATransitionPush
        animation.subtype = kCATransitionFromTop
        
        self.add(animation, forKey: kCATransitionPush)
    }
    
    func animateDown(with duration: CFTimeInterval) {
        
        let animation = CATransition()
        animation.beginTime = CACurrentMediaTime()
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.duration = duration
        animation.type = kCATransitionPush
        animation.subtype = kCATransitionFromBottom
        
        self.add(animation, forKey: kCATransitionPush)
    }
    
}

private extension UILabel {
    
    func animateTextColor(highlightedColor: UIColor) {
        
        let current = textColor
        
        UIView.transition(with: self,
                          duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in self?.textColor = highlightedColor },
                          completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.transition(with: self,
                              duration: 0.5,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in self?.textColor = current },
                              completion: nil)
        }
        
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

