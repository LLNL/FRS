//
//  DetailsTableCell.swift
//  FRS
//
//  Created by Lee, John on 8/17/19.
//  Copyright © 2019 Lee, John. All rights reserved.
//

import UIKit

class DetailsTableCell: UITableViewCell {
    
    @IBOutlet weak var imgExists: UIImageView!
    @IBOutlet weak var lblTrait: UILabel!
    
    func setCell(exists: Bool, trait: String) {
        lblTrait.text = trait
        if (exists) {
            imgExists.image = #imageLiteral(resourceName: "checkYes")
        } else {
            imgExists.image = #imageLiteral(resourceName: "checkNo")
        }
    }
}
