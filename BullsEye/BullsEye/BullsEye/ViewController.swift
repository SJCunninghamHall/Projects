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

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func showAlert()
    {
        let alert = UIAlertController(title: "Hello, world!", message: "This is my first app!", preferredStyle: .alert)
 
        let action = UIAlertAction(title: "Awesome!", style: .default, handler: nil)
        //let action2 = UIAlertAction(title: "Here's another thing to do", style: .default, handler: nil)
        
        alert.addAction(action)
        //alert.addAction(action2)
        
        present(alert, animated: true, completion: nil)
        
    }
    
}

