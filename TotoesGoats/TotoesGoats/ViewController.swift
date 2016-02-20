//
//  ViewController.swift
//  TotoesGoats
//
//  Created by Guo Xiaoyu on 2/20/16.
//  Copyright © 2016 Xiaoyu Guo. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var button: UIButton!

    @IBAction func buttonClicked(sender: UIButton) {
        isProcessing = !isProcessing
        
        if isProcessing {
            processedLayer.hidden = false
            previewLayer.hidden = true
            button.backgroundColor = UIColor.greenColor()
        } else {
            processedLayer.hidden = true
            previewLayer.hidden = false
            button.backgroundColor = UIColor.redColor()
        }
    }
    
    var session = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer!
    var processedLayer : CALayer!
    
    var isProcessing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Get all devices on my phone
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
        let device = devices.first!
        
        //
        let input = try! AVCaptureDeviceInput(device: device)
        //        do {
        //            input =AVCaptureDeviceInput(device: device)
        //        } catch {
        //            assert(false)
        //        }
        
        assert(session.canAddInput(input))
        session.addInput(input)
        
        // Create preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = self.view.bounds
        self.view.layer.addSublayer(previewLayer)
        
        // Create processed video layer
        processedLayer = CALayer()
        processedLayer.frame = self.view.bounds
        processedLayer.hidden = true
        processedLayer.backgroundColor = UIColor.redColor().CGColor
        self.view.layer.addSublayer(processedLayer)
        
        // Create data output
        let frameProcessingQueue = dispatch_queue_create("goatface.frameprocessing", DISPATCH_QUEUE_SERIAL);
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA) ]
        output.setSampleBufferDelegate(self, queue: frameProcessingQueue)
        assert(session.canAddOutput(output))
        session.addOutput(output)
        
        // Button
        self.view.bringSubviewToFront(button)
        button.layer.cornerRadius = button.frame.width / 2.0
        
        // Start actually capturing
        session.startRunning()
    }
    
    func colorFilter(imageBuffer: CVImageBufferRef) {
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        var pixels = UnsafeMutablePointer<UInt8>(CVPixelBufferGetBaseAddress(imageBuffer))
        // pixels are stored as (blue, green, red, alpha), one byte per channel
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        for _ in 0 ..< height {
            var idx = 0
            for _ in 0 ..< width {
                pixels[idx    ] = 0 // Blue
//                pixels[idx + 1] = 0 // Green
//                pixels[idx + 2] = 0 // Red
//                pixels[idx + 3] = 0 // Alpha
                idx += 4
            }
            pixels += bytesPerRow
        }
        
        // Create an image with this buffer
        let context = CIContext()
        let ciImage = CIImage(CVImageBuffer: imageBuffer).imageByApplyingOrientation(6)
        let cgImage = context.createCGImage(ciImage, fromRect: ciImage.extent)
        
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.processedLayer.contents = cgImage
        }
        processedLayer.contents = cgImage
    }
    
    // Method that receives the frame buffers
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        if(isProcessing) {
            guard let frameBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
//            let frameBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//            if frameBuffer = nil {
//                return
//            }
            colorFilter(frameBuffer)
            
        }
        
    }


}

