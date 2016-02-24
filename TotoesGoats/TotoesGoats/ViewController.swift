//
//  ViewController.swift
//  TotoesGoats
//
//  Created by Guo Xiaoyu on 2/20/16.
//  Copyright © 2016 Xiaoyu Guo. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    //    @IBAction func buttonClicked(sender: UIButton) {
    //        isProcessing = !isProcessing
    //
    //        if isProcessing {
    //            processedLayer.hidden = false
    //            processedLayer.backgroundColor = nil // sets layer to be transparent, so we can see the video feed being shown in the preview layer
    //            previewLayer.hidden = false
    //            button.backgroundColor = UIColor.greenColor()
    //        } else {
    //            processedLayer.hidden = true
    //            previewLayer.hidden = false
    //            button.backgroundColor = UIColor.redColor()
    //        }
    //    }
    
    var session = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer!
    var processedLayer : CALayer!
    
    var backCameraOn = true
    
    @IBOutlet weak var scrollMenu: ACPScrollMenu!
    @IBOutlet weak var frontBackSwitchBtn: UIButton!
    @IBAction func switchBtnClicked(sender: UIButton) {
        
        backCameraOn = !backCameraOn
        
        //Indicate that some changes will be made to the session
        session.beginConfiguration()
        
        //Remove existing input
        let currentCameraInput = session.inputs[0] as! AVCaptureDeviceInput
        
        session.removeInput(currentCameraInput)
        
        //Get new input
        var newCamera : AVCaptureDevice
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
        
        if(currentCameraInput.device.position == .Back)
        {
            newCamera = devices.filter({ (dev) -> Bool in dev.position == .Front}).first!
        }
        else
        {
            newCamera = devices.first!
        }
        
        let input = try! AVCaptureDeviceInput(device: newCamera)
        
        assert(session.canAddInput(input))
        session.addInput(input)
        
        //Commit all the configuration changes at once
        session.commitConfiguration()
    }
    
    var isProcessing = true
    var frameNo = 0
    var faceDetector = CIDetector(ofType: CIDetectorTypeFace,
        context: nil, options:  [
            CIDetectorAccuracy: CIDetectorAccuracyHigh,
            CIDetectorTracking: true
        ]
    )
    
    var itemSelected = -1;
    
    lazy var dogFace : UIImage! = {
        let path = NSBundle.mainBundle().pathForResource("dog", ofType: "png")!
        return UIImage(contentsOfFile: path)
    }()
    
    lazy var eyeImg : UIImage! = {
        let path = NSBundle.mainBundle().pathForResource("eye", ofType: "png")!
        return UIImage(contentsOfFile: path)
    }()
    
    lazy var laughImg : UIImage! = {
        let path = NSBundle.mainBundle().pathForResource("laugh", ofType: "png")!
        return UIImage(contentsOfFile: path)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Get all devices on my phone
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
        
        let device = devices.first!
        //        let device = devices.filter({ (dev) -> Bool in
        //            dev.position == .Front
        //        }).first!
        //let device = devices.filter({ $0.position == .Front}).first!
        
        
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
        
        
        //        // Button
        //        self.view.bringSubviewToFront(button)
        //        button.layer.cornerRadius = button.frame.width / 2.0
        
        processedLayer.hidden = false
        processedLayer.backgroundColor = nil // sets layer to be transparent, so we can see the video feed being shown in the preview layer
        previewLayer.hidden = false
        
        // Set the Camera Switch Button
        frontBackSwitchBtn.setImage(UIImage.init(named: "camera"), forState: .Normal)
        //frontBackSwitchBtn.contentMode = .ScaleAspectFill
        self.view.bringSubviewToFront(frontBackSwitchBtn)
        
        // Init Scroll Menu
        ScrollMenuInit.setUpACPScroll(scrollMenu, inUIViewController: self)
        //self.view.bringSubviewToFront(scrollMenu)
        
        // Start actually capturing
        session.startRunning()
    }
    
    func hackFixOrientation(img: UIImage) -> CGImageRef {
        let debug = CIImage(CGImage: img.CGImage!).imageByApplyingOrientation(6)
        let context = CIContext()
        let fixedImg = context.createCGImage(debug, fromRect: debug.extent)
        return fixedImg
    }
    
    func detectFaces(imageBuffer: CVImageBufferRef) {
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        let height = CVPixelBufferGetHeight(imageBuffer)
        let ciImage = CIImage(CVImageBuffer: imageBuffer)
        
        let faces = faceDetector.featuresInImage(ciImage,
            options:[CIDetectorImageOrientation: 6, CIDetectorSmile : true, CIDetectorEyeBlink : true]) as! [CIFaceFeature]
        
        print("\(faces.count) faces detected")
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0) , {
            // Draw rectangles on detected faces
            UIGraphicsBeginImageContext(ciImage.extent.size)
            let context = UIGraphicsGetCurrentContext()
            
            // Set line properties color and width
            CGContextSetLineWidth(context, 30)
            CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
            
            var T = CGAffineTransformIdentity
            T = CGAffineTransformScale(T, 1, -1)
            T = CGAffineTransformTranslate(T, 0, -CGFloat(height))
            
            
            for face in faces {
                switch(self.itemSelected) {
                case 0:
                    //let faceLoc = CGRectApplyAffineTransform(face.bounds, T)
                    
                    CGContextAddEllipseInRect(context, face.bounds)
                    
                    //dogFace = dogFace?.imageRotatedByDegrees(90, flip: false)
                    CGContextDrawImage(context, face.bounds, self.dogFace.CGImage)
                    break;
                case 1:
                    if face.leftEyeClosed && face.rightEyeClosed {
                        let width = face.bounds.width
                        let xl = face.leftEyePosition.x
                        let yl = face.leftEyePosition.y
                        let xr = face.rightEyePosition.x
                        let yr = face.rightEyePosition.y
                        let lEyeLoc = CGRectMake(xl - width/8, yl - width/8, width/4, width/4)
                        let rEyeLoc = CGRectMake(xr - width/8, yr - width/8, width/4, width/4)
                        CGContextDrawImage(context, lEyeLoc, self.eyeImg.CGImage)
                        CGContextDrawImage(context, rEyeLoc, self.eyeImg.CGImage)
                    }
                    break;
                case 2:
                    if face.hasSmile {
                        let width = face.bounds.width
                        let x = face.mouthPosition.x
                        let y = face.mouthPosition.y
                        let mouthLoc = CGRectMake(x - width/4, y - width/3, width * 1/2, width * 2/3)
                        //dogFace = dogFace?.imageRotatedByDegrees(90, flip: false)
                        CGContextDrawImage(context, mouthLoc, self.laughImg.CGImage)
                    }
                    break;
                default:
                    break;
                }
            }
            
            CGContextStrokePath(context)
            
            let drawnFaces = UIGraphicsGetImageFromCurrentImageContext()
            
            if(drawnFaces == nil) {
                NSLog("nil found hello")
            }
            UIGraphicsEndImageContext()
            
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
            
            self.processedLayer.contents = self.hackFixOrientation(drawnFaces)
            
            // Send to main queue to update UI
            dispatch_async(dispatch_get_main_queue()) {
                if(drawnFaces == nil) {
                    NSLog("nil found")
                }
                else {
                    self.processedLayer.contents = self.hackFixOrientation(drawnFaces)
                }
            }
        })
    }
    
    func colorFilter(imageBuffer: CVImageBufferRef) {
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        var pixels = UnsafeMutablePointer<UInt8>(CVPixelBufferGetBaseAddress(imageBuffer))
        // pixels are stored as (blue, green, red, alpha), one byte per channel
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        let blueValue = UInt8((1.0 + sin(Double(frameNo) / 10)) * 0.5 * 255)
//        let greenValue = UInt8((1.0 + sin(Double(frameNo) / 10)) * 0.5 * 255)
//        let redValue = UInt8((1.0 + sin(Double(frameNo) / 10)) * 0.5 * 255)
        
        for _ in 0 ..< height {
            var idx = 0
            for _ in 0 ..< width {
                pixels[idx    ] = blueValue // Blue
//                pixels[idx + 1] = greenValue // Green
//                pixels[idx + 2] = redValue // Red
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
            //UIImage(CGImage: cgImage)
            self.processedLayer.contents = cgImage
        }
    }
    
    // Method that receives the frame buffers
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        if(isProcessing) {
            guard let frameBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            //            let frameBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            //            if frameBuffer = nil {
            //                return
            //            }
            //colorFilter(frameBuffer)
            //detectFaces(frameBuffer)
            itemSelected == 3 ? colorFilter(frameBuffer) : detectFaces(frameBuffer)
            frameNo += 1
        }
        
    }
    
}

// function used to deal with UIImage
extension UIImage {
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        //        let radiansToDegrees: (CGFloat) -> CGFloat = {
        //            return $0 * (180.0 / CGFloat(M_PI))
        //        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        CGContextScaleCTM(bitmap, yFlip, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension ViewController : ACPScrollDelegate {
    func scrollMenu(menu: ACPScrollMenu!, didSelectIndex selectedIndex: Int) {
        itemSelected = selectedIndex
    }
}
