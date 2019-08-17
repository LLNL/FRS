//
//  ResultViewController.swift
//  FRS
//
//  Created by Lee, John on 7/14/19.
//  Copyright © 2019 Lee, John. All rights reserved.
//
import UIKit
import Foundation
import SafariServices
import AWSRekognition
import AWSDynamoDB

class ResultViewController: UIViewController, UINavigationControllerDelegate, SFSafariViewControllerDelegate,  UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var capturedImage: UIImageView!
    
    // Faces
    var image: UIImage!
    var faces: [Face] = []
    
    // Rekognition configuration
    var rekogCollectionId = "faces"     // Rekogntion Collection Id
    var rekogThreshold = 60              // Threshold for simularity match 0 - 100
    var rekogMatches = 10               // Total matches to return by Rekognition
    
    var dispatchGroup = DispatchGroup()
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorView.Style.whiteLarge)
    
    var rekognitionObject: AWSRekognition?
    var dynamoDB: AWSDynamoDB?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if image == nil {
            print ("ERROR! No image was received. Loading default image!")
            self.image = #imageLiteral(resourceName: "bezos")
            //faces = mockFaces() // Debug only
        }
        
        self.capturedImage.image = image
        let faceImage:Data = UIImagePNGRepresentation(image)!
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        activityIndicator.color = .darkGray
        activityIndicator.center = CGPoint(x: tableView.bounds.size.width/2, y: tableView.bounds.size.height/3)
        tableView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        sendImageToRekognition(originalImage: image, faceImageData: faceImage, handleRotation: true, lastorientation: UIDeviceOrientation.portrait)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return faces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell") as! TableCell
        let face = faces[indexPath.row]
        cell.setCell(face: face)
        if(face.simularity < 70.0) {
            cell.lblSimularity.textColor = UIColor.red
        }
        else if(face.simularity >= 90.0) {
            cell.lblSimularity.textColor = UIColor.green
        }
        else {
            cell.lblSimularity.textColor = UIColor.orange
        }
        return cell
    }
    
    // Rekognition to process this image
    func sendImageToRekognition(originalImage: UIImage, faceImageData: Data, handleRotation: Bool, lastorientation: UIDeviceOrientation) {
        self.rekognitionObject = AWSRekognition.default()
        let faceImageAWS = AWSRekognitionImage()
        faceImageAWS?.bytes = faceImageData
        let image = UIImage(data: faceImageData as Data)
        let detectfacesrequest = AWSRekognitionDetectFacesRequest()
        detectfacesrequest?.image = faceImageAWS
        
        self.rekognitionObject?.detectFaces(detectfacesrequest!) {
            (result, error) in
            if error != nil {
                print(error!)
                return
            }
            if (result!.faceDetails!.count > 0) { // Faces found! Process them
                print(String(format:"Number of faces detected in image: %@",String(result!.faceDetails!.count)))
                
                // Faces found, iterate through each
                for (_, face) in result!.faceDetails!.enumerated(){
                    // If confident its face, then let Rekognition identify. This threshold set to an arbitrary number (50??)
                    if(face.confidence!.intValue > 50) {
                        let viewHeight = face.boundingBox?.height  as! CGFloat
                        let viewWidth = face.boundingBox?.width as! CGFloat
                        let toRect = CGRect(x: face.boundingBox?.left as! CGFloat, y: face.boundingBox?.top as! CGFloat, width: viewWidth, height:viewHeight)
                        let croppedImage = self.cropImage(image!, toRect: toRect, viewWidth: viewWidth, viewHeight: viewHeight, handleRotation: handleRotation, lastorientation: lastorientation)
                        let croppedFace: Data = UIImageJPEGRepresentation(croppedImage!, 0.2)!
                        
                        // Resend to Recognition to identify
                        self.rekognizeFace(faceImageData: croppedFace, detectedface: face, croppedFace: croppedImage!, handleRotation: handleRotation, lastorientation: lastorientation)
                    }
                }
            }
            else {
                print("No faces were detected in this image.")
                let workItem = DispatchWorkItem {
                    [weak self] in
                    let face = Face(name: "No faces detected", simularity: 0.0, image: #imageLiteral(resourceName: "error"), scene: self!.capturedImage)
                    self?.faces.append(face)
                    self?.reloadList()
                    self?.activityIndicator.stopAnimating()
                }
                DispatchQueue.main.async(execute: workItem)
            }
        }
    }
    
    // Run Rekognition to identify face
    func rekognizeFace(faceImageData: Data, detectedface: AWSRekognitionFaceDetail, croppedFace: UIImage, handleRotation: Bool, lastorientation: UIDeviceOrientation) {
        rekognitionObject = AWSRekognition.default()
        let faceImageAWS = AWSRekognitionImage()
        faceImageAWS?.bytes = faceImageData
        let imagerequest = AWSRekognitionSearchFacesByImageRequest()
        imagerequest?.collectionId = self.rekogCollectionId
        imagerequest?.faceMatchThreshold = self.rekogThreshold as NSNumber
        imagerequest?.maxFaces = self.rekogMatches as NSNumber
        imagerequest?.image = faceImageAWS
        
        let faceInImage = Face(name: "Unknown", simularity: 0.0, image: croppedFace, scene:  self.capturedImage)
        
        // Get coordinates for detected face in whole image
        faceInImage.boundingBox = ["height":detectedface.boundingBox?.height, "left":detectedface.boundingBox?.left, "top":detectedface.boundingBox?.top, "width":detectedface.boundingBox?.width] as? [String : CGFloat]
        
        self.rekognitionObject?.searchFaces(byImage: imagerequest!) {
            (result, error) in
            
            if (result!.faceMatches!.count > 0) {
                print(String(format:"Total faces matched by Rekogition: %@",String(result!.faceMatches!.count)))
                print ("Attempting to retrieve face information from DynamoDB")
                
                // Faces were found. Lets iterate through all of them
                for (_, face) in result!.faceMatches!.enumerated() {
                    faceInImage.simularity = face.similarity!.floatValue
                    
                    // Get face full name from DynamoDB
                    self.dynamoDB = AWSDynamoDB.default()
                    let iteminput = AWSDynamoDBQueryInput()
                    iteminput?.indexName = "faceid-index"
                    iteminput?.tableName = "index-face"
                    iteminput?.keyConditionExpression = "faceid = :v1"
                    let value = AWSDynamoDBAttributeValue()
                    value?.s = face.face?.faceId
                    iteminput?.expressionAttributeValues = [":v1" : value!]
                    
                    //let x = face.face?.externalImageId
                    //print("HERE X: \(x)")
                    
                    self.dispatchGroup.enter()
                    self.dynamoDB?.query(iteminput!) {
                        (result, err) in
                        
                        if let error = err as NSError? {
                            print("Unable to get face name from dynamo: \(error)")
                            faceInImage.name = "Name Missing"
                        }
                        else {
                            for (_, value1) in
                                result!.items!.enumerated() {
                                    for (_, value2) in value1.enumerated() {
                                        if (value2.key == "name"){
                                            faceInImage.name = value2.value.s!
                                        }
                                    }
                            }
                        }
                        print ("\(face.face?.faceId ?? "") | \(faceInImage.name ?? "unavailable") | \(face.similarity!.floatValue)")
                        let workItem = DispatchWorkItem {
                            [weak self] in
                            let match = Face(name: faceInImage.name!, simularity: face.similarity!.floatValue, image: croppedFace, scene:  self!.capturedImage)
                            self?.faces.append(match)
                            self?.reloadList()
                            self?.activityIndicator.stopAnimating()
                        }
                        DispatchQueue.main.async(execute: workItem)
                    }
                }
            }
            else {
                print("Rekognition could not match any faces")
                let workItem = DispatchWorkItem {
                    [weak self] in
                    self?.faces.append(faceInImage)
                    self?.reloadList()
                    self?.activityIndicator.stopAnimating()
                }
                DispatchQueue.main.async(execute: workItem)
            }
        }
    }
    
    
    //Crop image for individual faces found
    func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect, viewWidth: CGFloat, viewHeight: CGFloat, handleRotation: Bool, lastorientation: UIDeviceOrientation) -> UIImage? {
        // Scale cropRect to handle images larger than shown-on-screen size
        let cropZone = CGRect(x:cropRect.origin.x * inputImage.size.width,
                              y:cropRect.origin.y * inputImage.size.height,
                              width:cropRect.size.width * inputImage.size.width,
                              height:cropRect.size.height * inputImage.size.height)
        
        // Perform cropping in Core Graphics
        guard let cutImageRef: CGImage = inputImage.cgImage?.cropping(to:cropZone)
            else {
                return nil
        }
        
        // Return image to UIImage
        if(handleRotation) {
            var orientation = UIImageOrientation.up
            if lastorientation == UIDeviceOrientation.landscapeLeft || (UIDevice.current.orientation == UIDeviceOrientation.faceUp && UIDevice.current.orientation.isLandscape) {
                orientation = UIImageOrientation.up
            } else if lastorientation == UIDeviceOrientation.landscapeRight {
                orientation = UIImageOrientation.down
            } else if lastorientation == UIDeviceOrientation.portrait || (UIDevice.current.orientation == UIDeviceOrientation.faceUp && UIDevice.current.orientation.isPortrait) {
                orientation = UIImageOrientation.right
            } else if lastorientation == UIDeviceOrientation.portraitUpsideDown {
                orientation = UIImageOrientation.left
            }
            return UIImage(cgImage: cutImageRef, scale: 1.0, orientation: orientation)
        } else {
            return UIImage(cgImage: cutImageRef)
        }
    }

    func reloadList() {
        self.faces.sort() { $0.simularity > $1.simularity }
        tableView.reloadData();
    }
    
    func mockFaces() -> [Face] {
        var faces: [Face] = []
        
        let face1 = Face(name: "Jeff Bezos", simularity: 99, image: #imageLiteral(resourceName: "bezos"), scene: capturedImage)
        let face2 = Face(name: "Bill Gates", simularity: 90, image: #imageLiteral(resourceName: "billgates"), scene: capturedImage)
        let face3 = Face(name: "Steve Jobs", simularity: 80, image: #imageLiteral(resourceName: "stevejobs"), scene: capturedImage)
        let face4 = Face(name: "Mark Zuckerberg", simularity: 70, image: #imageLiteral(resourceName: "markzukerberg"), scene: capturedImage)
        let face5 = Face(name: "Elon Musk", simularity: 60, image: #imageLiteral(resourceName: "elonmusk"), scene: capturedImage)
        
        faces.append(face1)
        faces.append(face2)
        faces.append(face3)
        faces.append(face4)
        faces.append(face5)
        
        return faces
    }
}
