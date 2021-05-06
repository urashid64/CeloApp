//
//  CurrencyTextField.swift
//  CeloApp
//
//  Created by Usman Rashid on 5/5/21.
//

import UIKit

class CurrencyTextField: UITextField {
    
    var passTextFieldText: ((String, Double?) -> Void)?
    
    //Used to send clean double value back
    private var amountAsDouble: Double?
    
    var startingValue: Double? {
        didSet {
            self.text = String.init(format: "%0.02f", startingValue!)
        }
    }
    
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
        
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        //If using in SBs
        setup()
    }
    
    //6
    private func setup() {
        self.textAlignment = .right
        self.keyboardType = .numberPad
        self.contentScaleFactor = 0.5

        self.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    //AFTER entered string is registered in the textField
    @objc private func textFieldDidChange() {
        updateTextField()
    }
    
    private func updateTextField() {
        var cleanedAmount = ""
        
        for character in self.text ?? "" {
            if character.isNumber {
                cleanedAmount.append(character)
            }
        }
        
        let amount = Double(cleanedAmount) ?? 0.0
        if (amount.isZero) {
            amountAsDouble = 0.0
            self.text = String.init(format: "%0.02f", startingValue!)
        }
        else {
            amountAsDouble = (amount / 100.0)
            self.text = numberFormatter.string(from: NSNumber(value: amountAsDouble ?? 0.0)) ?? ""
        }
        passTextFieldText?(self.text!, amountAsDouble)
    }
    
    //8
    //Prevents the user from moving the cursor in the textField
    //Source: https://stackoverflow.com/questions/16419095/prevent-user-from-setting-cursor-position-on-uitextfield
    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        let beginning = self.beginningOfDocument
        let end = self.position(from: beginning, offset: self.text?.count ?? 0)
        return end
    }
}
