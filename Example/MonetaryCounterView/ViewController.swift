//
//  ViewController.swift
//  MonetaryCounterView
//
//  Created by Davide Ceresola on 02/22/2022.
//  Copyright (c) 2022 Davide Ceresola. All rights reserved.
//

import UIKit
import MonetaryCounterView

class ViewController: UIViewController {
    
    private lazy var counterView: MonetaryCounterView = {
       
        let view = MonetaryCounterView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.configure(with: "EUR")
        view.font = UIFont.boldSystemFont(ofSize: 20)
        
        return view
        
    }()
    
    private lazy var textField: UITextField = {
       
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.placeholder = "Insert here number"
        view.keyboardType = .numberPad
        view.returnKeyType = .go
        
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.delegate = self
        
        view.addSubview(textField)
        view.addSubview(counterView)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: counterView.topAnchor, constant: -30),
            textField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            counterView.heightAnchor.constraint(equalToConstant: 50),
            counterView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            counterView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            counterView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
        
    }

}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       
        guard
            let text = textField.text,
            let number = Double(text)
        else {
            return false
        }
        
        view.endEditing(true)
        counterView.number = NSDecimalNumber(value: number)
        
        return true
    }
    
}

