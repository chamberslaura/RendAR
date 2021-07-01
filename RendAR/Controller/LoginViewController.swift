//
//  LoginViewController.swift
//  RendAR
//
//  Created by Laura Chambers on 2021-03-18.
//

import UIKit

class LoginViewController: UIViewController {

    @IBAction func loginButtonPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToNewCapture", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
