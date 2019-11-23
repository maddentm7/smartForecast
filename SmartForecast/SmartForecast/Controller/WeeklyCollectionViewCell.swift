//
//  WeeklyCollectionViewCell.swift
//  SmartForecast
//
//  Created by Parsa Bagheri on 6/2/18.
//  Copyright © 2018 Parsa Bagheri. All rights reserved.
//

import UIKit

class WeeklyCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var weather_description: UILabel!/*weather description*/
	@IBOutlet weak var temp: UILabel!/*the average temprature of the day*/
	@IBOutlet weak var day: UILabel!/*the weekly day*/
	@IBOutlet weak var weather_icon: UIImageView!/*weather icon to be shown*/
	@IBOutlet weak var cellbg: UIView!/*instance of cell background for changing the design*/
	override func awakeFromNib() {
		cellbg.layer.cornerRadius = 10;/*round corners*/
	}
}
