//
//  ViewController.swift
//  BullsEye
//
//  Created by Stephen Cunningham on 02/09/2019.
//  Copyright © 2019 Cunningham Hall Consultancy. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{

    var currentValue: Int = 0
    var targetValue: Int = 0
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var targetLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let roundedValue = slider.value.rounded()
        currentValue = Int(roundedValue)

        startNewRound()
        
    }

    @IBAction func showAlert()
    {
        
        var difference: Int
        
        if currentValue > targetValue
        {
            difference = currentValue - targetValue
        }
        else if targetValue > currentValue
        {
            difference = targetValue = currentValue
        }
        else
        {
            difference = 0
        }
        
        let message = "The value of the slider is now: \(currentValue)" +
                        "\nThe target value is \(targetValue)" +
                        "\nThe difference is \(difference)"
        
        let alert = UIAlertController(title: "Hello, world!", message: message, preferredStyle: .alert)
 
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        //let action2 = UIAlertAction(title: "Here's another thing to do", style: .default, handler: nil)
        
        alert.addAction(action)
        //alert.addAction(action2)
        
        present(alert, animated: true, completion: nil)
        
        startNewRound()
    }
    
    @IBAction func sliderMoved(_ slider: UISlider)
    {
        let roundedValue = slider.value.rounded()
        currentValue = Int(roundedValue)
    }
    
    func startNewRound()
    {
        targetValue = Int.random(in: 1...100)
        
        //targetLabel.text = "\(targetValue)"
        
        currentValue = 50
        slider.value = Float(currentValue)
        
        updateLabels()
        
    }
    
    func updateLabels()
    {
        targetLabel.text = String(targetValue)
    }
    
}

