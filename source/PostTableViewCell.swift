//
//  PostTableViewCell.swift
//  source
//
//  Created by Orbit on 28/1/18.
//  Copyright © 2018 Orbit. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var rightArrowIndicator: UIImageView!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var readIndicator: UIImageView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		// Configure the view for the selected state
	}
	
}
