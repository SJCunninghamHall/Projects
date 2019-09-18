//
//  AboutViewController.swift
//  BullsEye
//
//  Created by Stephen Cunningham on 13/09/2019.
//  Copyright © 2019 Cunningham Hall Consultancy. All rights reserved.
//

import UIKit
import WebKit

class AboutViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let htmlPath = Bundle.main.path(forResource:
            "BullsEye", ofType: "html")
        {
            
            let url = URL(fileURLWithPath: htmlPath)
            let request = URLRequest(url: url)
            webView.load(request)
            
        }

        // Do any additional setup after loading the view.
    }
    
    @IBAction func close()
    {
        dismiss(animated: true, completion: nil)
    }

}
