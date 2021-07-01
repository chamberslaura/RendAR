//
//  SummaryViewController.swift
//  RendAR
//
//  Created by Laura Chambers on 2021-02-27.
//

import UIKit
import CoreBluetooth
import CoreImage

class SummaryViewController: UIViewController {

    var centralManager: BLEManager?
    var product: Product?
    var singleImage: UIImage!
    var enhancedImage1: UIImage!
    var enhancedImage2: UIImage!
    var enhancedImage3: UIImage!
    var enhancedImage4: UIImage!
    
    @IBOutlet weak var image1View: UIImageView!
    @IBOutlet weak var image2View: UIImageView!
    @IBOutlet weak var image3View: UIImageView!
    @IBOutlet weak var image4View: UIImageView!
    @IBOutlet weak var productLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var massLabel: UILabel!
    @IBOutlet weak var dimensionsLabel: UILabel!
    
    

    @IBAction func image1Pressed(_ sender: Any) {
        self.singleImage = enhancedImage1 //product?.image1
        self.performSegue(withIdentifier: "goToSingleImage", sender: self)
    }
    
    
    @IBAction func image2Pressed(_ sender: Any) {
        self.singleImage = enhancedImage2
        self.performSegue(withIdentifier: "goToSingleImage", sender: self)
    }
    
    
    @IBAction func image3Pressed(_ sender: Any) {
        self.singleImage = enhancedImage3
        self.performSegue(withIdentifier: "goToSingleImage", sender: self)
    }
    
    
    @IBAction func image4Pressed(_ sender: Any) {
        self.singleImage = enhancedImage4
        self.performSegue(withIdentifier: "goToSingleImage", sender: self)
    }
    
    @IBAction func redoPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToNewCapture", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enhancedImage1 = product?.image1!.autoEnhance()
        self.image1View.image = enhancedImage1
        self.image1View.layer.masksToBounds = true
        self.image1View.layer.cornerRadius = 10
        enhancedImage2 = product?.image2!.autoEnhance()
        self.image2View.image = enhancedImage2
        self.image2View.layer.masksToBounds = true
        self.image2View.layer.cornerRadius = 10
        enhancedImage3 = product?.image3!.autoEnhance()
        self.image3View.image = enhancedImage3
        self.image3View.layer.masksToBounds = true
        self.image3View.layer.cornerRadius = 10
        enhancedImage4 = product?.image4!.autoEnhance()
        self.image4View.image = enhancedImage4
        self.image4View.layer.masksToBounds = true
        self.image4View.layer.cornerRadius = 10
        
        UIImageWriteToSavedPhotosAlbum(enhancedImage1, nil, nil, nil)
        UIImageWriteToSavedPhotosAlbum(enhancedImage2, nil, nil, nil)
        UIImageWriteToSavedPhotosAlbum(enhancedImage3, nil, nil, nil)
        UIImageWriteToSavedPhotosAlbum(enhancedImage4, nil, nil, nil)
        
        productLabel.text = product?.ID
        massLabel.text = ("\(String(Int((product?.mass)!))) g")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToSingleImage" {
            let destinationVC = segue.destination as! SingleImageViewController
            destinationVC.centralManager = centralManager
            destinationVC.singleImage = singleImage
        }
        if segue.identifier == "goToNewCapture" {
            let destinationVC = segue.destination as! NewCaptureViewController
        }
    }
}

extension UIImage {
    func autoEnhance() -> UIImage? {
        if var ciImage = CIImage.init(image: self) {
            let adjustments = ciImage.autoAdjustmentFilters()
            for filter in adjustments {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                if let outputImage = filter.outputImage {
                    ciImage = outputImage
                }
            }
            let context = CIContext.init(options: nil)
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let finalImage = UIImage.init(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
                return finalImage
            }
        }
        return nil
    }
}
