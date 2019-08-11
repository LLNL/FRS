//
//  ResultViewController.swift
//  FRS
//
//  Created by Lee, John on 7/14/19.
//  Copyright © 2019 Lee, John. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {

    @IBOutlet weak var capturedImage: UIImageView!
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.capturedImage.image = image
    }
}
