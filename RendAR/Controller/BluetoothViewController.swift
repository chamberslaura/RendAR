//
//  BluetoothViewController.swift
//  RendAR
//
//  Created by Laura Chambers on 2021-03-05.
//

import UIKit
import CoreBluetooth

class BluetoothViewController: UIViewController {

    var centralManager: BLEManager?
    
    @IBOutlet weak var connectingIndicator: UIActivityIndicatorView!
    
    @IBAction func skipButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToProductID", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = BLEManager()
        connectingIndicator.transform = CGAffineTransform.init(scaleX: 2, y: 2)
        NotificationCenter.default.addObserver(self, selector: #selector(onBLEDidConnect(_:)), name: .BLEDidConnect, object: nil)
    }
    
    @objc func onBLEDidConnect(_ notification: Notification){
        self.performSegue(withIdentifier: "goToProductID", sender: self)
    }
    
    //MARK : Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToProductID" {
            let destinationVC = segue.destination as! ProductIDViewController
            destinationVC.centralManager = centralManager
        }
    }

}
