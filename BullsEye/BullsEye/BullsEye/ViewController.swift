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

    var currentValue = 0
    var targetValue = 0
    var score = 0
    var round = 0
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var roundLabel: UILabel!
    
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
        
        let difference = abs(currentValue - targetValue)
        var points = 100 - difference
        
        let title: String
        
        if difference == 0
        {
            title = "Perfect!"
            points += 100
        } else if difference < 5
        {
            title = "You almost had it!"
            if difference == 1
            {
                points += 50
            }
        } else if difference < 10
        {
            title = "Pretty good!"
        } else
        {
            title = "Not even close!"
        }
        
        score += points

        let message = "You guessed \(currentValue) \nYou scored \(points) points"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
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
        round += 1
        targetValue = Int.random(in: 1...100)
        
        //targetLabel.text = "\(targetValue)"
        
        currentValue = 50
        slider.value = Float(currentValue)
        
        updateLabels()
        
    }
    
    func updateLabels()
    {
        targetLabel.text = String(targetValue)
        scoreLabel.text = String(score)
        roundLabel.text = String(round)
    }
    
}

