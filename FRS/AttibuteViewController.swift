//
//  AttributeViewController.swift
//  FRS
//
//  Created by Lee, John on 8/17/19.
//  Copyright © 2019 Lee, John. All rights reserved.
//

import UIKit
import Foundation
import SafariServices
import AWSRekognition

class AttributeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var capturedImage: UIImageView!
    
    var image: UIImage!
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorView.Style.whiteLarge)
    
    var rekognitionObject: AWSRekognition?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if image == nil {
            print ("ERROR! No image was received. Loading default image!")
            image = #imageLiteral(resourceName: "bezos")
            //faces = mockFaces() // Debug only
        }
        
        capturedImage.image = image
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        activityIndicator.color = .darkGray
        activityIndicator.center = CGPoint(x: tableView.bounds.size.width/2, y: tableView.bounds.size.height/3)
        tableView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeTableCell") as! EmployeeTableCell
        return cell
    }
    
}
