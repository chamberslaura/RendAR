//
//  SingleImageViewController.swift
//  RendAR
//
//  Created by Laura Chambers on 2021-03-06.
//

import UIKit

class SingleImageViewController: UIViewController, UIScrollViewDelegate {

    var centralManager: BLEManager?
    var product: Product?
    var singleImage: UIImage!
    
    @IBOutlet weak var singleImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        singleImageView.image = singleImage
        singleImageView.isUserInteractionEnabled = true
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture))
        singleImageView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func pinchGesture(sender: UIPinchGestureRecognizer) {
        sender.view?.transform = (sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale))!
        sender.scale = 1.0
    }
}
