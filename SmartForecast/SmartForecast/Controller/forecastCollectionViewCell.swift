//
//  forecastCollectionViewCell.swift
//  SmartForecast
//
//  Created by Parsa Bagheri on 5/30/18.
//  Copyright © 2018 Parsa Bagheri. All rights reserved.
//
//  This is a group project, sharing files and resources amongst
//  the group mates is consented.
//
//  Group Members:
//  		Parsa Bagheri, Yanting Liu, Taylor Madden,
//  		Kevin Roeske, Bill Shang

import UIKit

class forecastCollectionViewCell: UICollectionViewCell {

	@IBOutlet weak var cellbg: UIView!
	@IBOutlet weak var forecast_icon: UIImageView!
	@IBOutlet weak var weather_time: UILabel!
	@IBOutlet weak var weather_temp: UILabel!
	@IBOutlet weak var weather_description: UILabel!
	override func awakeFromNib() {
		super.awakeFromNib();
		cellbg.layer.cornerRadius = 10;
	}
}
