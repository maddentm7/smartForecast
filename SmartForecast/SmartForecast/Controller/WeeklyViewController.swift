//
//  WeeklyViewController.swift
//  SmartForecast
//
//  Created by Parsa Bagheri on 6/2/18.
//  Copyright © 2018 Parsa Bagheri. All rights reserved.
//
//  ************************** CREDIT *****************************
//  The Date extension in this file is not my work, it is
//  taken from the following link by "brandonscript" on stack overflow
//  link: https://stackoverflow.com/questions/25533147/get-day-of-week-using-nsdate/35006174
//  ***************************************************************
import UIKit

class WeeklyViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
	
	@IBOutlet weak var cell: WeeklyCollectionViewCell! /*instance of the cell to be manipulated*/
	var forecast: [ForecastData]?; /*will be populated upon entering this view, if data is available*/
	let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]; /*days of the week to be displayed*/
	
	override func viewDidLoad() {
		super.viewDidLoad();
	}
	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil);
	}
	func avgWeather(index: Int) -> (UIImage?, String?)
	{
		/*helper function to get the average weather of a day*/
		if(self.forecast != nil){
			
			var image: UIImage?;
			/*udpating the weather icon*/
			let desc = self.forecast![index*8].description
			if let x = self.forecast![index*8].weather{
				if(x>=200 && x<=232){ /*thunderstorm*/
					image = #imageLiteral(resourceName: "thunderstorm");
				}else if(x>=300 && x<=321){ /*drizzle*/
					image = #imageLiteral(resourceName: "drizzle");
				}else if(x>=500 && x<=531){ /*rain*/
					image = #imageLiteral(resourceName: "rain");
				}else if(x>=600 && x<=622){ /*snow*/
					image = #imageLiteral(resourceName: "snow")
				}else if(x>=701 && x<=781){ /*atmosphere*/
					image = #imageLiteral(resourceName: "atmosphere");
				}else if(x>=801 && x<=804){ /*clouds*/
					image = #imageLiteral(resourceName: "clouds");
				}else if(x==800){ /*clear*/
					image = #imageLiteral(resourceName: "clearday");
				}else{ /*unknown*/
					image = #imageLiteral(resourceName: "atmosphere");
				}
			}
			return (image, desc);
		}
		return (nil, nil);
	}
	func avgTemp(index: Int) -> Int
	{
		/*helper function to get the average temperature of a day*/
		var avgtmp = 0.0;
		switch index {
		case 0:
			for i in 0...8{
				avgtmp += forecast![i].temp!;
			}
			avgtmp = avgtmp/8;
		case 1:
			for i in 8...16{
				avgtmp += forecast![i].temp!;
			}
			avgtmp = avgtmp/8;
		case 2:
			for i in 16...24{
				avgtmp += forecast![i].temp!;
			}
			avgtmp = avgtmp/8;
		case 3:
			for i in 24...32{
				avgtmp += forecast![i].temp!;
			}
			avgtmp = avgtmp/8;
		case 4:
			if(forecast!.count>=36){
				for i in 32...(forecast!.count-1){
					avgtmp += forecast![i].temp!;
				}
				avgtmp = avgtmp/(Double(forecast!.count) - 32.0);
			}
			break;
		default:
			break;
		}
		return Int(avgtmp);
	}
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 5; /*show five days of forecast*/
	}
	var errorFlag = false;/*if the error is not shown, we'll set it so that it doesn't show the same error multiple times*/
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "weekly_cell", for: indexPath) as! WeeklyCollectionViewCell;
		
		/*We need at leas 36 entries in the forecast array for the next weekly view*/
		/*if something goes wrong and we don't have that enough info show a message*/
		if(forecast == nil || (forecast!.count < 36)){
			if(!errorFlag){
				errorMessage();
				errorFlag = true;/*error is shown*/
			}
		}
		/*if we do have at least 36 entries, map the data onto the weekly view*/
		else{
			cell.temp.text = String(describing: Int(forecast![indexPath.row].temp!))
			let dayIndex = Date().dayNumberOfWeek()!-1;
			switch(indexPath.row){
			case 0:
				let report = avgWeather(index: 0)
				cell.day.text = weekdays[dayIndex];
				cell.temp.text = String(describing: avgTemp(index: 0))
				cell.weather_icon.image = report.0
				cell.weather_description.text = report.1
			case 1:
				let report = avgWeather(index: 1)
				if dayIndex < 6{
					cell.day.text = weekdays[dayIndex+1];
				}
				else{
					cell.day.text = weekdays[0];
				}
				cell.temp.text = String(describing: avgTemp(index: 1))
				cell.weather_icon.image = report.0
				cell.weather_description.text = report.1
			case 2:
				let report = avgWeather(index: 2)
				if dayIndex+1 < 6{
					cell.day.text = weekdays[dayIndex+2];
				}
				else{
					cell.day.text = weekdays[1];
				}
				cell.temp.text = String(describing: avgTemp(index: 2))
				cell.weather_icon.image = report.0
				cell.weather_description.text = report.1
			case 3:
				let report = avgWeather(index: 3)
				if dayIndex+2 < 6{
					cell.day.text = weekdays[dayIndex+3];
				}
				else{
					cell.day.text = weekdays[2];
				}
				cell.temp.text = String(describing: avgTemp(index: 3))
				cell.weather_icon.image = report.0
				cell.weather_description.text = report.1
			case 4:
				let report = avgWeather(index: 4)
				if dayIndex+3 < 6{
					cell.day.text = weekdays[dayIndex+4];
				}
				else{
					cell.day.text = weekdays[3];
				}
				cell.temp.text = String(describing: avgTemp(index: 4))
				cell.weather_icon.image = report.0
				cell.weather_description.text = report.1
			default:
				break;
			}
		}
		return cell;
	}
	
	func errorMessage()
	{
		/*helper function showing an error pop up in case we couldn't get data*/
		/*if information is not retrieved, push an error message*/
		let forecastErr = UIAlertController(title: "Couldn't get the Forecast Data!", message: nil, preferredStyle: UIAlertControllerStyle.alert)
		forecastErr.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: { (action) in
			forecastErr.dismiss(animated: true, completion: nil);
		}))
		self.present(forecastErr, animated: true, completion: nil);
	}
	
	deinit {/*deconstructor, free forecast once left this view*/
		forecast = nil;
	}
}

/*
 * The following extention of date class gets the day number of today
 * This is not my work, the credits and link is mentioned above
 */
extension Date {
	func dayNumberOfWeek() -> Int? {
		return Calendar.current.dateComponents([.weekday], from: self).weekday
	}
}
