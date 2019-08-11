//
//  Face.swift
//  FRS
//
//  Created by Lee, John on 7/14/19.
//  Copyright © 2019 Lee, John. All rights reserved.
//
import Foundation
import UIKit
import SafariServices

class Face {
    
    var boundingBox: [String:CGFloat]! //= ["height": 0.0,"left": 0.0,"top": 1.0,"width": 0.0]
    
    var simularity:Float!
    var name:String! //= ""
    var urls:[String]! //= []
    
    var infoLink:String! //= ""
    
    var infoLabel: UILabel! //= UILabel.init()
    
    var infoButton:UIButton! //= UIButton.init()
    
    var scene: UIImageView! //= UIImageView.init()
    
    var face: UIImage!
    //var parentController: UIViewController! //= UIViewController.init()
    
    func createInfoButton()-> UIButton {
        //Determine position of annotations
        let size = CGSize(width: self.boundingBox["width"]! * scene.layer.bounds.width, height:self.boundingBox["height"]!*scene.layer.bounds.height)
        let origin = CGPoint(x: self.boundingBox["left"]!*scene.layer.bounds.width, y: self.boundingBox["top"]!*scene.layer.bounds.height)
        
        //Create a rectangle layer
        let rectangleLayer = CAShapeLayer()
        rectangleLayer.borderColor = UIColor.green.cgColor
        rectangleLayer.borderWidth = 2
        rectangleLayer.frame = CGRect(origin: origin, size: size)
        print(rectangleLayer.frame.origin)
        print(rectangleLayer.frame.size)
        
        //Create and Populate info button
        self.infoButton = UIButton.init(frame: CGRect(origin: CGPoint(x: origin.x, y: origin.y+size.height*0.75), size: CGSize(width: 0.4*scene.layer.bounds.width, height: 0.05*scene.layer.bounds.height)))
        self.infoButton.backgroundColor = UIColor.black
        self.infoButton.clipsToBounds = true
        self.infoButton.layer.cornerRadius = 8
        self.infoButton.setTitleColor(UIColor.white, for: UIControlState.normal)
        self.infoButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.infoButton.titleLabel?.textAlignment = NSTextAlignment.center
        //let title = String(format: "%@ (%.2f%%)", self.name, self.simularity)
        self.infoButton.setTitle( self.name, for: UIControlState.normal)
        
        scene.isUserInteractionEnabled = true
        scene.addSubview(self.infoButton)
        //scene.bringSubview(toFront: self.infoButton)
        //self.infoButton.addTarget(self, action: #selector(handleTap), for: UIControlEvents.touchUpInside)
        return self.infoButton
        
    }
}
