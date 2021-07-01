//
//  ProductIDViewController.swift
//  RendAR
//
//  Created by Laura Chambers on 2021-02-27.
//

import UIKit

class ProductIDViewController: UIViewController, UITextViewDelegate {
    
    var centralManager: BLEManager?
    var product: Product?

    @IBOutlet weak var productIDTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        product = Product()
        productIDTextField.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap) // Add gesture recognizer to background view
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        product?.ID = self.productIDTextField.text!
        print("Product ID:  \(product?.ID ?? "None")")
        self.performSegue(withIdentifier: "goToCameraView", sender: self)
    }
    
    @objc func handleTap() {
        productIDTextField.resignFirstResponder() // dismiss keyoard
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCameraView" {
            let destinationVC = segue.destination as! CameraViewController
            destinationVC.centralManager = centralManager
            destinationVC.product = product
        }
    }
}

extension ProductIDViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // dismiss keyboard
        return true
    }
}
