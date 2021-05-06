//
//  PaymentViewController.swift
//  CeloApp
//
//  Created by Usman Rashid on 5/3/21.
//

import UIKit

class PaymentViewController: UIViewController {

    @IBOutlet weak var lblPaymentQRCode: UILabel!
    @IBOutlet weak var lblBalanceQRCode: UILabel!
    @IBOutlet weak var lblPaymentInfo: UILabel!
    @IBOutlet weak var lblBalanceInfo: UILabel!
    @IBOutlet weak var txtAmount: CurrencyTextField!
    
    var privkey: String!
    var address: String!
    var amount: String!

    struct celoAccount: Decodable {
        enum Category: String, Decodable {
            case swift, combine, debugging, xcode
        }

        let celo: String
        let cUsd: String
    }

    var paymentObserver: NSKeyValueObservation?
    var balanceObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        address = ""
        privkey = ""
        amount = ""

        addDoneButtonOnKeyboard()
        txtAmount.startingValue = 0.0
        txtAmount.passTextFieldText = { [weak self] enteredStringAmount, amountAsDouble in
            self?.amount = String(amountAsDouble ?? 0.0)
        }

        paymentObserver = lblPaymentQRCode.observe(\.text) { [weak self] (label, observedChange) in
            let pmtAddress = self?.parseURL(text: self?.lblPaymentQRCode.text ?? "")
            self?.address = pmtAddress?["address"]!
            let addr = String((pmtAddress?["address"]!.dropFirst(2))!)
            let str = addr.uppercased().separate(every: 4)
            self?.lblPaymentInfo.text = str
        }

        balanceObserver = lblBalanceQRCode.observe(\.text) { [weak self] (label, observedChange) in
            let balAddress = self?.parseURL(text: self?.lblBalanceQRCode.text ?? "")
            self?.privkey = balAddress!["privkey"]
            self?.fetchBalace(addr: balAddress!["address"])
        }
    }
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        doneToolbar.items = [flexSpace, done]
        doneToolbar.sizeToFit()
        txtAmount.inputAccessoryView = doneToolbar
    }


    @objc func doneButtonAction(){
        txtAmount.resignFirstResponder()
        print (amount!)
    }

    
    func parseURL(text:String) -> [String:String] {
        guard let url = URL(string:text) else { return [:] }

        var dict = [String:String]()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if let queryItems = components.queryItems {
            for item in queryItems {
                dict[item.name] = item.value!
            }
        }
        return dict
    }
    
    func fetchBalace(addr:String?) -> Void {
        let headers = ["x-api-key": "ee8102cf-dbec-4433-8bb9-37f6c98842a4"]
        let url = "https://api-eu1.tatum.io/v3/celo/account/balance/\(addr ?? "")"

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
                print (returnData!)

                let acct: celoAccount = try! JSONDecoder().decode(celoAccount.self, from: data!)
                print ("Celo: \(acct.celo)")
                print ("cUsd: \(acct.cUsd)")

                DispatchQueue.main.async {
                    self.lblBalanceInfo.text = String("Balance: \(acct.cUsd) cUSD")
                }
             }
        })

        dataTask.resume()
    }
    
    func transfer(toAddr: String, fromPrivKey: String, amount: String) -> Void {
        let headers = [
          "content-type": "application/json",
          "x-api-key": "ee8102cf-dbec-4433-8bb9-37f6c98842a4"
        ]
        let parameters = [
          "data": "My note to recipient.",
          "nonce": 0,
          "to": toAddr,
          "currency": "CUSD",
          "feeCurrency": "CUSD",
          "amount": amount,
          "fromPrivateKey": fromPrivKey
        ] as [String : Any]

        let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])

        let request = NSMutableURLRequest(url: NSURL(string: "https://api-eu1.tatum.io/v3/celo/transaction")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error!)
            }
            else {
                let returnData = String(data: data!, encoding: .utf8)
                print (returnData!)
            }
        })

        dataTask.resume()
    }

    @IBAction func onConfirm(_ sender: Any) {
        transfer(toAddr: address, fromPrivKey: privkey, amount: amount)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "paymentScanner" {
            let scannerVC = segue.destination as! ScannerViewController
            scannerVC.callback = { text in self.lblPaymentQRCode.text = text }
        }
        else if segue.identifier == "balanceScanner" {
            let scannerVC = segue.destination as! ScannerViewController
            scannerVC.callback = { text in self.lblBalanceQRCode.text = text }
        }
    }
}
