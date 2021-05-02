//
//  ViewController.swift
//  CeloApp
//
//  Created by Usman Rashid on 4/16/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var lblQRCode: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblBalance: UILabel!

    var textObserver: NSKeyValueObservation?

    var address: String!
    var balance: String!

    struct celoAccount: Decodable {
        enum Category: String, Decodable {
            case swift, combine, debugging, xcode
        }

        let celo: String
        let cUsd: String
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        balance = ""
        lblQRCode.text = ""
        lblAddress.text = ""
        lblBalance.text = ""

        textObserver = lblQRCode.observe(\.text) { [weak self] (label, observedChange) in
            self?.parseURL(text: self?.lblQRCode.text ?? "")
            self?.fetchBalace(addr: (self?.lblQRCode.text)!)
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
        address = dict["address"]
        let addr = String((dict["address"]?.dropFirst(2))!)
        
        self.lblAddress.text = addr.uppercased().separate(every: 4)
        self.lblBalance.text = "Fetching..."
    }
    
    
    func fetchBalace(addr:String) -> Void {
        let headers = ["x-api-key": "ee8102cf-dbec-4433-8bb9-37f6c98842a4"]
        let url = "https://api-eu1.tatum.io/v3/celo/account/balance/\(address ?? "")"

        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error!)
            }
            else {
                let returnData = String(data: data!, encoding: .utf8)
                self.balance = returnData
                print (returnData!)

                let acct: celoAccount = try! JSONDecoder().decode(celoAccount.self, from: data!)
                print ("Celo: \(acct.celo)")
                print ("cUsd: \(acct.cUsd)")
                
                DispatchQueue.main.async {
                    self.formatBalance(account: acct)
                }
             }
        })

        dataTask.resume()
    }
    
    
    func formatBalance(account: celoAccount) -> Void {
        lblBalance.text = String("CELO: \(account.celo)\ncUSD: \(account.cUsd)")
    }
}


extension String {
    func separate(every stride: Int = 4, with separator: Character = " ") -> String {
        return String(enumerated().map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1]}.joined())
    }
}
