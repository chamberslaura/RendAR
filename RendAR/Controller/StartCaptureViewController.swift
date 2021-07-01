//
//  CaptureButtonViewController.swift
//  RendAR
//
//  Created by Laura Chambers on 2021-03-05.
//

import AVFoundation
import CoreBluetooth
import UIKit

class StartCaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var centralManager: BLEManager?
    var product: Product?
    

    @IBOutlet weak var previewView: UIView!
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToCaptureProgress", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Product ID:  \(product?.ID ?? "None")")
        print("Camera View: \(centralManager?.stateChar as Any)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        else {
            print("Unable to access back camera!")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error {
            print("Error - Unable to initialize back camera: \(error.localizedDescription)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    func setupLivePreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.previewView.bounds
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCaptureProgress" {
            let destinationVC = segue.destination as! CameraViewController
            destinationVC.centralManager = centralManager
            destinationVC.product = product
        }
    }

}
