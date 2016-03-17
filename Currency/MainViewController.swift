//
//  MainViewController.swift
//  Currency
//
//  Created by Nuno Coelho Santos on 11/02/2016.
//  Copyright © 2016 Nuno Coelho Santos. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    var converter = Converter()
    var calculator = Calculator()
    var prefs: NSUserDefaults = NSUserDefaults.standardUserDefaults()

    @IBOutlet weak var inputCurrencyLabel: UILabel!
    @IBOutlet weak var outputCurrencyLabel: UILabel!
    @IBOutlet weak var inputCurrencyCodeButton: UIButton!
    @IBOutlet weak var outputCurrencyCodeButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var equalsButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Style view.
        view.layer.cornerRadius = 3.0
        view.clipsToBounds = true
        
        // If we have the last input currency used saved on the preferences
        // file, let's use it.
        if let currencyCode = prefs.stringForKey("input") {
            converter.setInputCurrency(currencyCode)
            updateInterface()
        }
        
        // If we have the last input currency used saved on the preferences
        // file, let's use it.
        if let currencyCode = prefs.stringForKey("output") {
            converter.setOutputCurrency(currencyCode)
            updateInterface()
        }
        
    }

    @IBAction func digitPressed(sender: UIButton) {
        guard let digit = sender.titleLabel?.text else {
            print("Error setting digit value.")
            return
        }
        if calculator.settingNewValue {
            converter.input = 0
            calculator.settingNewValue = false
        }
        converter.addInput(Double(digit)!)
        updateInterface()
    }

    @IBAction func clearPressed(sender: UIButton) {
        converter.reset()
        calculator.reset()
        updateInterface()
    }
    
    @IBAction func switchPressed(sender: AnyObject) {
        calculator.initialValue = converter.convertToOutputCurrency(calculator.initialValue)
        if calculator.operationInProgress && !calculator.settingNewValue {
            converter.swapInputWithOutput(false)
        } else {
            converter.swapInputWithOutput(true)
        }
        updateInterface()
    }
    
    @IBAction func addPressed(sender: UIButton) {
        calculator.newAddition(converter.input)
        // Update the input label with the latest calculation,
        // at this point stored as the initial value.
        converter.input = calculator.initialValue
        updateInterface()
        // Keep this button highlighted after it's pressed so the user
        // knows a new operation has begun.
        sender.setBackgroundImage(UIImage(named: "buttonAddBackground.png"), forState: .Normal)
        sender.setImage(UIImage(named: "buttonAddIconHighlighted.png"), forState: .Normal)
    }
    
    @IBAction func minusPressed(sender: UIButton) {
        calculator.newSubtraction(converter.input)
        // Update the input label with the latest calculation,
        // at this point stored as the initial value.
        converter.input = calculator.initialValue
        updateInterface()
        // Keep this button highlighted after it's pressed so the user
        // knows a new operation has begun.
        sender.setBackgroundImage(UIImage(named: "buttonSubtractBackground.png"), forState: .Normal)
        sender.setImage(UIImage(named: "buttonSubtractIconHighlighted.png"), forState: .Normal)
    }
    
    @IBAction func equalsPressed(sender: UIButton) {
        let result = calculator.calculate(converter.input)
        converter.input = Double(result)
        updateInterface()
    }
    
    @IBAction func swipedInput(sender: AnyObject) {
        // If a user swipes on the input label, remove on digit.
        // The iOS native calculator app also has this hidden feature.
        converter.removeLastInput()
        updateInterface()
    }
    
    @IBAction func longPressedInput(sender: UIGestureRecognizer) {
        // Copy input label text to clipboard after a long press.
        if sender.state == .Began {
            UIPasteboard.generalPasteboard().string = inputCurrencyLabel.text
            print("Copied input currency value to clipboard.")
        }
    }
    
    @IBAction func longPressedOutput(sender: UIGestureRecognizer) {
        // Copy input label text to clipboard after a long press.
        if sender.state == .Began {
            UIPasteboard.generalPasteboard().string = outputCurrencyLabel.text
            print("Copied output currency value to clipboard.")
        }
    }
    
    func updateInterface() {
        // Update all visible labels and reset buttons to their default styles.
        inputCurrencyLabel.text = converter.inputValue()
        outputCurrencyLabel.text = converter.outputValue()
        inputCurrencyCodeButton.setTitle(converter.inputCurrency.code, forState: .Normal)
        outputCurrencyCodeButton.setTitle(converter.outputCurrency.code, forState: .Normal)
        addButton.setBackgroundImage(nil, forState: .Normal)
        addButton.setImage(UIImage(named: "buttonAddIcon.png"), forState: .Normal)
        minusButton.setBackgroundImage(nil, forState: .Normal)
        minusButton.setImage(UIImage(named: "buttonSubtractIcon.png"), forState: .Normal)
    }
    
    // MARK: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Pass the currency we are changing (input or output) and
        // the current currency code to the Change Currency View Controller.
        
        if segue.identifier == "ChangeInputCurrency" {
            let changeCurrencyViewController = (segue.destinationViewController as! UINavigationController).topViewController as! ChangeCurrencyViewController
            changeCurrencyViewController.targetCurrency = "input"
            changeCurrencyViewController.selectedCurrency = converter.inputCurrency.code
            changeCurrencyViewController.delegate = self
        }
        
        if segue.identifier == "ChangeOutputCurrency" {
            let changeCurrencyViewController = (segue.destinationViewController as! UINavigationController).topViewController as! ChangeCurrencyViewController
            changeCurrencyViewController.targetCurrency = "output"
            changeCurrencyViewController.selectedCurrency = converter.outputCurrency.code
            changeCurrencyViewController.delegate = self
        }
        
    }
    
}

// MARK: - Delegate

extension MainViewController: ChangeCurrencyViewControllerDelegate {
    
    // After selecting a new currency from the Change Currency View Controller,
    // set it as the new currency and update the interface.
    // At this point, also save it to the user preferences file.
    
    func didChangeCurrency(currencyCode: String, targetCurrency: String) {
        if targetCurrency == "input" {
            // If user changes input currency to be the same as the
            // output currency, swap them.
            if currencyCode == converter.outputCurrency.code {
                converter.swapInputWithOutput(true)
                converter.recordAsSelected(currencyCode)
            } else {
                converter.setInputCurrency(currencyCode)
            }
            prefs.setObject(currencyCode, forKey: "input")
            print("Input currency updated to: \(currencyCode)")
        }
        if targetCurrency == "output" {
            // If user changes output currency to be the same as the
            // input currency, swap them.
            if currencyCode == converter.inputCurrency.code {
                converter.swapInputWithOutput(true)
                converter.recordAsSelected(currencyCode)
            } else {
                converter.setOutputCurrency(currencyCode)
            }
            prefs.setObject(currencyCode, forKey: "output")
            print("Output currency updated to: \(currencyCode)")
        }
        updateInterface()
    }
    
}

