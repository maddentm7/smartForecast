//
//  WeatherService.swift
//  SmartForecast
//
//  Created by Parsa Bagheri on 5/22/18.
//  Copyright © 2018 Parsa Bagheri. All rights reserved.
//
//  This is a group project, sharing files and resources amongst
//  the group mates is consented.
//
//  Group Members:
//  		Parsa Bagheri, Yanting Liu, Taylor Madden,
//  		Kevin Roeske, Bill Shang
//
//  ************************** CREDIT *****************************
//  The Weather WEATHER_URL and APP_ID specifically is registered
//  for Taylor Madden.
//  ***************************************************************
//
//  ************************** CREDIT *****************************
//  The function UTCToLocal used in this file is not my work, it is
//  taken from the following link by "Mrugesh Tank" on Stack Overflow
//  link: https://stackoverflow.com/questions/42803349/swift-3-0-convert-server-utc-time-to-local-time-and-visa-versa
//  ***************************************************************


import Foundation
import CoreLocation
import SwiftyJSON
import Alamofire

class WeatherService
{
	/*following is the openweathermap URL used for retrieving JSON file*/
	let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather";
	let FORECAST_URL = "http://api.openweathermap.org/data/2.5/forecast";
	let APP_ID = "e72ca729af228beabd5d20e3b7749713";
	
	var cur_city: String!;/*current city stored here upon running*/
	var cur_state: String?;/*current state stored here upon running, optional because might not exist*/
	var cur_country: String!;/*current country stored here upon running*/
	var cur_long: CLLocationDegrees!;
	var cur_lat: CLLocationDegrees!;
	var parsedWeather: WeatherData!;
	var isWeatherInitialized: Bool = false; /*flag to know if the parsedWeather instance is initialized or not*/
	var isForecastInitialized: Bool = false; /*flag to know if the forecastData instance is initialized or not*/
	var forecastData: [ForecastData] = []; /*forecast data of every three hr of the next 5 days stored here*/
	static var sharedInstance = WeatherService() /*shared instance to share data*/
	
	/*
	 * Parsa Bagheri:
	 * The following function converts universal time to local time
	 * code is not mine, it is taken from "Mrugesh Tank" linked above
	 * I have made minor changes to make it work with my code
	 */
	func UTCToLocal(date:String) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss +0000"
		dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
		
		let dt = dateFormatter.date(from: date)
		dateFormatter.timeZone = TimeZone.current
		dateFormatter.dateFormat = "h:mm a"
		
		return dateFormatter.string(from: dt!)
	}
	
	func getWeather(complete: (()->())?)
	{
		/*
		 * procedure to retrive the weather
		 * takes nothing and returns a struct containing weather data
		 */
		let weatherURL = URL(string: "\(WEATHER_URL)?lat=\(cur_lat!)&lon=\(cur_long!)&appid=\(APP_ID)");
		Alamofire.request(weatherURL!).responseJSON(completionHandler: { (response) in
			if let jsonWeatherReport = response.result.value{
				let serialized_json = JSON(jsonWeatherReport);
				if(!self.isWeatherInitialized){
					self.parsedWeather = WeatherData(weather: serialized_json["weather"][0]["id"].intValue,
													 icon: serialized_json["weather"][0]["icon"].stringValue,
													 description: serialized_json["weather"][0]["description"].stringValue,
													 temp: Int(serialized_json["main"]["temp"].doubleValue - 273.15), /*data is in Kelvin, convert it to Celcius*/
													 max_temp: Int(serialized_json["main"]["temp_max"].doubleValue - 273.15),
													 min_temp: Int(serialized_json["main"]["temp_min"].doubleValue - 273.15),
													 wind_deg: serialized_json["wind"]["deg"].doubleValue,
													 wind_speed: serialized_json["wind"]["speed"].doubleValue,
													 humidity: serialized_json["main"]["humidity"].stringValue,
													 pressure: serialized_json["main"]["pressure"].stringValue,
													 /*time is in timestamps convert that to UTC then to local time*/
													 current_timestamp: self.UTCToLocal(date: String(describing: Date(timeIntervalSince1970: (serialized_json["dt"].doubleValue)))),
													 sunrise_timestamp: self.UTCToLocal(date: String(describing: Date(timeIntervalSince1970: (serialized_json["sys"]["sunrise"].doubleValue)))),
													 sunset_timestamp: self.UTCToLocal(date: String(describing: Date(timeIntervalSince1970: (serialized_json["sys"]["sunset"].doubleValue)))),
													 precipitation: serialized_json["rain"]["3h"].stringValue,
													 snow: serialized_json["snow"]["3h"].stringValue)
					self.isWeatherInitialized = true;
				}
				else{
					self.parsedWeather.weather = serialized_json["weather"][0]["id"].intValue;
					self.parsedWeather.icon = serialized_json["weather"][0]["icon"].stringValue;
					self.parsedWeather.description = serialized_json["weather"][0]["description"].stringValue;
					self.parsedWeather.temp = Int(serialized_json["main"]["temp"].doubleValue - 273.15);
					self.parsedWeather.max_temp = Int(serialized_json["main"]["temp_max"].doubleValue - 273.15);
					self.parsedWeather.min_temp = Int(serialized_json["main"]["temp_min"].doubleValue - 273.15);
					self.parsedWeather.wind_deg = serialized_json["wind"]["deg"].doubleValue
					self.parsedWeather.wind_speed = serialized_json["wind"]["speed"].doubleValue;
					self.parsedWeather.humidity = serialized_json["main"]["humidity"].stringValue;
					self.parsedWeather.pressure = serialized_json["main"]["pressure"].stringValue;
					self.parsedWeather.current_timestamp = self.UTCToLocal(date: String(describing: Date(timeIntervalSince1970: (serialized_json["dt"].doubleValue))));
					self.parsedWeather.sunrise_timestamp = self.UTCToLocal(date: String(describing: Date(timeIntervalSince1970: (serialized_json["sys"]["sunrise"].doubleValue))));
					self.parsedWeather.sunset_timestamp = self.UTCToLocal(date: String(describing: Date(timeIntervalSince1970: (serialized_json["sys"]["sunset"].doubleValue))));
					self.parsedWeather.precipitation = serialized_json["rain"]["3h"].stringValue;
					self.parsedWeather.snow = serialized_json["snow"]["3h"].stringValue;
				}
			}/*end parsing*/
			complete?();
		})
		
	}
	
	func getForecast(complete: (()->())?)
	{
		/*
		 * This function makes a call to OpenWeatherMap API and retrieves the 5day/3hr forecast
		 * It then fills an array of 36-40 forecastData instances to be shown on the screen
		 */
		let forecastURL = URL(string: "\(FORECAST_URL)?lat=\(cur_lat!)&lon=\(cur_long!)&appid=\(APP_ID)");
		Alamofire.request(forecastURL!).responseJSON(completionHandler: { (response) in
			if let jsonWeatherReport = response.result.value{
				let serialized_json = JSON(jsonWeatherReport);
				if(!self.isForecastInitialized){
					self.isForecastInitialized = true
					for i in serialized_json["list"]{
						self.forecastData.append(ForecastData(weather: i.1["weather"][0]["id"].intValue,
															  icon: i.1["weather"][0]["icon"].stringValue,
															  description: i.1["weather"][0]["description"].stringValue,
															  time: self.UTCToLocal(date: (i.1["dt_txt"].stringValue + " +0000")),
															  temp: (i.1["main"]["temp"].doubleValue - 273.15) /*data is in Kelvin, convert it to Celcius*/))
					}
				}
				else{
					for i in 0 ... (self.forecastData.count-1){
						self.forecastData[i].description = serialized_json["list"][i]["weather"][0]["description"].stringValue;
						self.forecastData[i].icon = serialized_json["list"][i]["weather"][0]["icon"].stringValue;
						self.forecastData[i].time = self.UTCToLocal(date: (serialized_json["list"][i]["dt_txt"].stringValue + " +0000"));
						self.forecastData[i].weather = serialized_json["list"][i]["weather"][0]["id"].intValue;
						self.forecastData[i].temp = (serialized_json["list"][i]["main"]["temp"].doubleValue - 273.15); /*data is in Kelvin, convert it to Celcius*/
					}
				}
			}
			complete?();
		})
	}
}
