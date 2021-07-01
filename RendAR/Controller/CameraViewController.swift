//
//  CameraViewController.swift
//  RendAR
//
//  Created by Laura Chambers on 2021-02-13.
//

import AVFoundation
import CoreBluetooth
import UIKit

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var centralManager: BLEManager?
    var product: Product?
    var count = 0
    let standby:UInt8 = 0x00
    let measuringMass:UInt8 = 0x01
    let massMeasurementComplete:UInt8 = 0x02
    let takePhoto:UInt8 = 0x03
    let rotating:UInt8 = 0x04
    let photoTaken:UInt8 = 0x05
    let captureComplete:UInt8 = 0x06
    let cameraReady:UInt8 = 0x07
    let startPressed:UInt8 = 0x08
    
    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var image1View: UIImageView!
    @IBOutlet weak var image2View: UIImageView!
    @IBOutlet weak var image3View: UIImageView!
    @IBOutlet weak var image4View: UIImageView!
    @IBOutlet weak var buttonView: UIButton!
    
    
    @IBAction func backButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        centralManager!.write(value: Data(_: [cameraReady]), characteristic: centralManager!.stateChar!)
        backgroundView.image = UIImage(named: "StartCaptureScreen");
        buttonView.setImage(UIImage(named: "BlueButton"), for: .normal)
        print("Wrote state: cameraReady")
    }
    
    func trigger() {
        print("Photo triggered!")
        count += 1
        print("Count = \(count)")
        if (count == 6) {
            print("Wrote state: captureComplete")
            centralManager!.write(value: Data(_: [captureComplete]), characteristic: centralManager!.stateChar!)
            self.performSegue(withIdentifier: "goToSummary", sender: self)
        } else {
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            stillImageOutput.capturePhoto(with: settings, delegate: self)
            centralManager!.write(value: Data([photoTaken]), characteristic: centralManager!.stateChar!)
            print("Wrote state: photo taken")
        }
    }
    
    @objc func onStateDidUpdate(_ notification: Notification){
        if centralManager?.stateValue! == startPressed {
            print("State received = startPressed")
            backgroundView.image = UIImage(named: "CaptureProgressScreen");
            buttonView.setImage(nil, for: .normal)
            trigger()
            print("~~~~~~~~~~~~~~~")
        } else if centralManager?.stateValue! == takePhoto {
            trigger()
        }
    }
    
    @objc func onMassDidUpdate(_ notification: Notification){
        print("Mass update received")
        let mass = Double((centralManager?.massValue)!)
        product?.mass = 5*mass
        print("Read mass: \(mass) g")
        print("Total mass: \(product?.mass ?? 0) g")
        print("~~~~~~~~~~~~~~~")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.image = UIImage(named: "CameraAlignmentScreen");
        progressIndicator.transform = CGAffineTransform.init(scaleX: 2, y: 2)
        print("Product ID:  \(product?.ID ?? "None")")
        print("Camera View: \(centralManager?.stateChar as Any)")
        NotificationCenter.default.addObserver(self, selector: #selector(onStateDidUpdate(_:)), name: .stateDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onMassDidUpdate(_:)), name: .massDidUpdate, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
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
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        let image = UIImage(data: imageData)
        //UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        
        if count == 1 {
            product?.image1 = image
            image1View.image = image
            image1View.layer.masksToBounds = true
            image1View.layer.cornerRadius = 8
        } else if count == 2 {
            product?.image2 = image
            image2View.image = image
            image1View.layer.masksToBounds = true
            image2View.layer.cornerRadius = 8
        } else if count == 3 {
            product?.image3 = image
            image3View.image = image
            image3View.layer.masksToBounds = true
            image3View.layer.cornerRadius = 8
        } else if count == 5 {
            product?.image4 = image
            image4View.image = image
            image4View.layer.masksToBounds = true
            image4View.layer.cornerRadius = 8
        }
        print("Image \(count) saved")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToSummary" {
            let destinationVC = segue.destination as! SummaryViewController
            destinationVC.centralManager = centralManager
            destinationVC.product = product
        }
    }
}
