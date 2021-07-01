//
//  ViewController.swift
//  RendAR version 3
//
//  Created by Laura Chambers on 2021-02-12.
//

import UIKit
import CoreBluetooth

class NewCaptureViewController: UIViewController {
    
    @IBOutlet weak var newCaptureButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func newCaptureButtonPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToBluetoothConnecting", sender: self)
    }

}

