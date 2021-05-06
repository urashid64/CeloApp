//
//  ViewController.swift
//  CeloApp
//
//  Created by Usman Rashid on 4/16/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var lblQRCode: UILabel!
    @IBOutlet weak var lblCELO: UILabel!
    @IBOutlet weak var lblCUSD: UILabel!
    @IBOutlet weak var indNetActivity: UIActivityIndicatorView!
    
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


    //-----------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        lblQRCode.text = ""
        balance = ""
        lblCELO.text = ""
        lblCUSD.text = ""

        textObserver = lblQRCode.observe(\.text) { [weak self] (label, observedChange) in
            self?.onQRCodeUpdate()
        }
    }

    //-----------------------------------------------------------------------------
    func onQRCodeUpdate () {
        // QR Code changed, clear all fields
        balance = ""
        lblCELO.text = ""
        lblCUSD.text = ""

        for tag in 101...110 {
            if let label = self.view.viewWithTag(tag) as? UILabel {
                label.text = ""
            }
        }

        // Get account address from URL
        let items = parseURL(text: lblQRCode.text ?? "")
        address = items["address"]

        if (address == nil) {
            let alert = UIAlertController (title: "Error", message: "Invalid QR Code!", preferredStyle: .alert)
            alert.addAction (UIAlertAction (title: "OK", style: .default, handler: nil))

            self.present(alert, animated: true, completion: nil)
            return
        }

        // Start Activity Indicator
        indNetActivity.startAnimating()

        // Get Balance for address and update fields
        fetchBalace(addr: address)
    }


    //-----------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showScanner" {
            let scannerVC = segue.destination as! ScannerViewController
            scannerVC.callback = { text in
                scannerVC.dismiss(animated: true, completion: {self.lblQRCode.text = text})
            }
        }
    }
    
    
    //-----------------------------------------------------------------------------
    func parseURL(text:String) -> [String:String] {
        guard let url = URL(string:text) else { return [:] }

        var dict = [String:String]()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if let queryItems = components.queryItems {
            for item in queryItems {
                dict[item.name] = item.value!
            }
        }
        print (dict)
        return dict
    }
    
    
    //-----------------------------------------------------------------------------
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
    
    
    //-----------------------------------------------------------------------------
    func formatBalance(account: celoAccount) -> Void {
        indNetActivity.stopAnimating()

        let addr = String(address.dropFirst(2))
        let str = addr.uppercased().separate(every: 4)
        let addrComponents = str.components(separatedBy: " ")
        
        for tag in 101...110 {
            if let label = self.view.viewWithTag(tag) as? UILabel {
                label.text = addrComponents[tag - 101]
            }
        }

        lblCELO.text = String (format: "%0.02f", Double(account.celo) ?? "")
        lblCUSD.text = String (format: "%0.02f", Double(account.cUsd) ?? "")
    }

    
    @IBAction func cancelPayment( _ seg: UIStoryboardSegue) {
    }
}


//-----------------------------------------------------------------------------
extension String {
    func separate(every stride: Int = 4, with separator: Character = " ") -> String {
        return String(enumerated().map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1]}.joined())
    }
}

/*
 //-----------------------------------------------------------------------------
 - (IBAction)genQRCode:(UIButton *)sender
 //-----------------------------------------------------------------------------
 {
     NSData* data = [self.strMnemonic dataUsingEncoding:NSISOLatin1StringEncoding];
     CIFilter* filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
     [filter setValue:data forKey:@"inputMessage"];
     [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
     
     CIImage *image = filter.outputImage;
     
     CGRect imageSize = CGRectIntegral(image.extent);
     CGSize displaySize = CGSizeMake(170.0, 170.0);
     CIImage* resizedImage = [image imageByApplyingTransform:
                              CGAffineTransformMakeScale(displaySize.width/CGRectGetWidth(imageSize),
                                                         displaySize.height/CGRectGetHeight(imageSize))];
     
     UIImage* qrCodeImage = [UIImage imageWithCIImage:resizedImage];
     self.imgQRCode.image = qrCodeImage;
     [self.view bringSubviewToFront:self.imgQRCode];
 }
 */
