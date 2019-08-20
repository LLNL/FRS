//
//  AddViewController.swift
//  FRS
//
//  Created by Lee, John on 8/18/19.
//  Copyright © 2019 Lee, John. All rights reserved.
//

import UIKit

class AddViewController: UIViewController {

    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var btnSave: UIButton!
    @IBOutlet weak var tbName: UITextField!
    
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
