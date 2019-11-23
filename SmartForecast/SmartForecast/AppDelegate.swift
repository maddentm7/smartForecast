//
//  AppDelegate.swift
//  SmartForecast
//
//  Created by Parsa Bagheri on 5/20/18.
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
//  Weather Icons used in this app are taken from the following link
//  link: <a href='https://www.freepik.com/free-vector/weather-icons-set_709126.htm'>Designed by Freepik</a>
//  The background image is taken from this website:
//  link: https://blog.oxforddictionaries.com/2015/12/11/mountain-names/
//  ***************************************************************

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate{

	var window: UIWindow?
	let notification_center = UNUserNotificationCenter.current();/*instance of notification framework*/
	var interval_components = DateComponents()/*starts on the first day of 2018*/
	var selectedHour = 8; /*sends notification every day at this hour, defualt is 8 but can be changed*/
	var isCelcius: Bool!;
	struct notifContent{
		/*weather right now*/
		var now_weather_description: String?;
		var now_temp: String?;
		/*weather in 3hrs*/
		var fut_weather_description: String?;
		var fut_temp: String?;
		var message: (String?, String?);
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		return true;
	}
	
	func addNotification(nc: notifContent)
	{
		/*
		* this function will set up the notification and interval of sending notifications
		*/
		
		/*setting up the content of the notification*/
		/*check if user has set their temp unit*/
		if(UserDefaults.standard.object(forKey: "isCelcius") != nil){
			isCelcius = UserDefaults.standard.bool(forKey: "isCelcius");
		}else{
			/*celcius by default*/
			isCelcius = true;
		}
		let content = UNMutableNotificationContent();
		content.title = "Todays Weather";
		let message = isCelcius ? "Now: \(nc.now_weather_description!), \(nc.now_temp!) ˚C\nIn a few hours: \(nc.fut_weather_description!)\nAvg temp of next 12 hrs: \(nc.fut_temp!) ˚C\n\(nc.message.0 ?? "") \(nc.message.1 ?? "")" : "Now: \(nc.now_weather_description!), \(nc.now_temp!) ˚F\nIn a few hours: \(nc.fut_weather_description!)\nAvg temp of next 12 hrs: \(nc.fut_temp!) ˚F\n\(nc.message.0 ?? "") \(nc.message.1 ?? "")";
		content.body = message
		content.badge = 1
		
		/*setting up the date and interval of the notification to be triggered*/
		self.interval_components.hour = self.selectedHour; /*send a notification every day at this hour*/
//		self.interval_components.second = 0 /*for testing perpuses set it so that it'll send a notifiaction every minute*/
		let trigger = UNCalendarNotificationTrigger(dateMatching: self.interval_components, repeats: true);/*repeats every day*/
		
		/*setting up the scheduling*/
		let request = UNNotificationRequest(identifier: "WeatherRequest", content: content, trigger: trigger);
		notification_center.add(request) { (error: Error?) in
			if(error != nil){
				print("error: \(String(describing: error?.localizedDescription))");
			}
		}
	}
	
}

