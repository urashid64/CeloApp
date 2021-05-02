//
//  ViewController.swift
//  CeloApp
//
//  Created by Usman Rashid on 4/16/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var lblQRCode: UILabel!
    @IBOutlet weak var lblBalance: UILabel!
    var textObserver: NSKeyValueObservation?

    var balance: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        balance = ""
        lblQRCode.text = balance

        textObserver = lblQRCode.observe(\.text) { [weak self] (label, observedChange) in
            self?.parseURL(text: self?.lblQRCode.text ?? "")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showScanner" {
            let scannerVC = segue.destination as! ScannerViewController
            scannerVC.callback = { text in self.lblQRCode.text = text }
        }
    }
    
    func parseURL(text:String) -> Void {
        guard let url = URL(string:text) else { return }

        var dict = [String:String]()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if let queryItems = components.queryItems {
            for item in queryItems {
                dict[item.name] = item.value!
            }
        }
        let addr = String((dict["address"]?.dropFirst(2))!)
        print(addr.separate(every: 4))
        self.lblBalance.text = addr.uppercased().separate(every: 4)
    }
}

extension String {
    func separate(every stride: Int = 4, with separator: Character = " ") -> String {
        return String(enumerated().map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1]}.joined())
    }
}
