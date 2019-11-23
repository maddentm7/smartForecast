//
//  WeatherDataModel.swift
//  SmartForecast
//
//  Created by Parsa Bagheri on 5/21/18.
//  Copyright © 2018 Parsa Bagheri. All rights reserved.
//
//  This is a group project, sharing files and resources amongst
//  the group mates is consented.
//
//  Group Members:
//  		Parsa Bagheri, Yanting Liu, Taylor Madden,
//  		Kevin Roeske, Bill Shang

import Foundation


/*following struct holds the decrypted data of current weather json file retrieved from openweathermap*/
struct WeatherData {
	
	var weather: Int?;
	var icon: String?;
	var description: String?;
	var temp: Int?;
	var max_temp: Int?;
	var min_temp: Int?;
	var wind_deg: Double?;
	var wind_speed: Double?;
	var humidity: String?;
	var pressure: String?;
	var current_timestamp: String?;
	var sunrise_timestamp: String?;
	var sunset_timestamp: String?;
	var precipitation: String?;
	var snow: String?;
}
/*following struct holds the decrypted data of forecast json file retreived from openweathermap */
struct ForecastData{
	
	var weather: Int?;
	var icon: String?;
	var description: String?;
	var time: String?;
	var temp: Double?;
}
