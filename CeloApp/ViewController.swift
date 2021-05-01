//
//  ViewController.swift
//  CeloApp
//
//  Created by Usman Rashid on 4/16/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var lblBalance: UILabel!

    var balance: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        balance = ""
        lblBalance.text = balance
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print (segue.identifier!)
        if segue.identifier == "showScanner" {
            let scannerVC = segue.destination as! ScannerViewController
            scannerVC.callback = { text in self.lblBalance.text = text }
        }
    }
}

