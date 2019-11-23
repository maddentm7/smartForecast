//
//  ViewController.swift
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


import UIKit
import CoreLocation /*for getting the coordinates*/
import UserNotifications /*for sending local notifications*/

class ViewController: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UNUserNotificationCenterDelegate{
	
	@IBOutlet weak var forecast_collection_view: UICollectionView!
	let appDelegate = UIApplication.shared.delegate as! AppDelegate /*instance of app delegate*/
	let locationManager = CLLocationManager();
	private var notification: NSObjectProtocol?;
	var weather:WeatherData?; /*instance of weather data,
	it will be initialized and filled with data once information retrieved from web*/
	var forecast:[ForecastData]?; /*instance of forecast data,
	it will be initialized and filled with data once information retrieved from web*/
	var locationForecast:[ForecastData]?; /*instance of the forecast of current location,
	it will be initialized and filled with data upon startup and will be used to give notifications every day*/
	var isNotif: Bool = false; /*flag indicating if notification is on or off based on users settings, default is true*/
	var isAccessory: Bool = false; /*flag indicating if accessories is on or off based on users settings*/
	var isClothes: Bool = false; /*flag indicating if clothes is on or off based on users settings*/
	var hour: Int = 8;/*hour to send notification, dfault is 8*/
	var isCelcius: Bool = true; /*flag to check weather temp is celcius or not*/
	
	var content: AppDelegate.notifContent!; /*instance of notifContent struct to hold content to be shown on the notification*/

	/*setting up buttons and labels to be shown on the screen*/
	@IBOutlet weak var weatherbg: UIView!/*weather information view backg ground*/
	@IBOutlet weak var tempbg: UIView!/*temp view backg ground*/
	@IBOutlet weak var temp_unit: UIImageView!
	@IBOutlet weak var weather_description: UILabel!
	@IBOutlet weak var pressure: UILabel!
	@IBOutlet weak var humidity: UILabel!
	@IBOutlet weak var wind: UILabel!
	@IBOutlet weak var sunset: UILabel!
	@IBOutlet weak var sunrise: UILabel!
	@IBOutlet weak var weather_icon: UIImageView!
	@IBOutlet weak var search_bar: UISearchBar!
	@IBOutlet weak var tempreture_label: UILabel!
	@IBOutlet weak var temp_low: UILabel!
	@IBOutlet weak var temp_high: UILabel!
	@IBOutlet weak var city: UILabel!
	@IBOutlet weak var state: UILabel!
	@IBOutlet weak var country: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tempbg.layer.cornerRadius = 15; /*give rounded corners to this view*/
		weatherbg.layer.cornerRadius = 15; /*give rounded corners to this view*/
		self.search_bar.delegate = self; /*setting the search bars delegate to self*/
		self.locationManager.delegate = self; /*set the delegate to self*/
		self.locationManager.requestWhenInUseAuthorization(); /*get the location even when the app is not running*/
		/*we don't need the best accuracy since this is not a map, and overhead of best accuracy is expensive*/
		self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;/*get the location within a kilometer radius*/
		self.locationManager.startMonitoringSignificantLocationChanges(); /*update if significant change happens*/
		
		/*retrieving notification settings from user defaults*/
		self.isNotif = UserDefaults.standard.bool(forKey: "notifSwitch");
		self.isClothes = UserDefaults.standard.bool(forKey: "clothesSwitch");
		self.isAccessory = UserDefaults.standard.bool(forKey: "accessorySwitch");
		self.hour = UserDefaults.standard.integer(forKey: "selectedHour") == 0 ? 8 : UserDefaults.standard.integer(forKey: "selectedHour");
		if(UserDefaults.standard.object(forKey: "isCelcius") != nil){
			self.isCelcius = UserDefaults.standard.bool(forKey: "isCelcius");
		}
		if(self.isCelcius){
			temp_unit.image = #imageLiteral(resourceName: "celc");
		}else{
			temp_unit.image = #imageLiteral(resourceName: "fahr");
		}
		appDelegate.selectedHour = self.hour;
		
		/*setting up tapping functionality to tempreture label*/
		let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapOnScreen))
		tempreture_label.isUserInteractionEnabled = true
		tempreture_label.addGestureRecognizer(tap)
		
		/*add an observer in case the program goes into the background*/
		notification = NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: .main) {
			[unowned self] notification in
			if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways{
				if(!self.isForecastCalled){
					/*upon coming into the foreground, the "getLocationWeather()" gets called*/
					self.locationManager.requestWhenInUseAuthorization(); /*get the location on entering foreground*/
					self.locationManager.startMonitoringSignificantLocationChanges(); /*update if significant change happens*/
					/*set these flags so that code allows entery to the block taht gets weather and forecast of location*/
					self.isWeatherCalled = false;
					self.isLocationForecast = true;
					self.isForecastCalled = false;
					/*get weather and forecast upon entering foreground*/
					self.getLocationWeather();
					self.getLocationForecast();
				}
			}
		}

		/*setting up notification*/
		/*asking for users permission to send notifications*/
		self.appDelegate.notification_center.requestAuthorization(options: [.alert, .sound], completionHandler: {(authorized: Bool, error: Error?)
			in
			if(!authorized){/*if user didn't authorize sending notifications*/
				self.isNotif = false;
				print("didn't allow sending notifications");
			}
			else{
				self.isNotif = true;
				self.isClothes = true;
				self.isAccessory = true;
				UserDefaults.standard.set(true, forKey: "notifSwitch");
				UserDefaults.standard.set(true, forKey: "clothesSwitch");
				UserDefaults.standard.set(true, forKey: "accessorySwitch");
			}
			if(error != nil){/*if error occurs print the error*/
				print("error: \(String(describing: error?.localizedDescription))");
			}
		})
	}
	
	func contentCalc()
	{
		/*helper function to calculate the content of the notification, i.e the self.content variable of type notifContent*/
		if(!self.locationForecast!.isEmpty){
			
			/*the average temperature of the next 12 hours*/
			var avgTmp = 0.0
			for i in 0 ... 4{
				avgTmp += self.locationForecast![i].temp!;
			}
			avgTmp = avgTmp/4;
			
			/*form the message to be sent*/
			var message: (String?, String?) = (nil, nil);
			if let x = self.locationForecast![2].weather{
				if(x>=200 && x<=232){ /*thunderstorm*/
					message.0 = "wear a jacket";
					message.1 = "don't bring an umbrella";
				}else if(x>=300 && x<=321){ /*drizzle*/
					message.0 = "wear a rain jacket if you can't stand getting wet";
					message.1 = "bring an umbrella";
				}else if(x>=500 && x<=531){ /*rain*/
					message.0 = "wear a rain jacket";
					message.1 = "bring an umbrella";
				}else if(x>=600 && x<=622){ /*snow*/
					message.0 = "put on a jacket";
					message.1 = nil;
				}else if((x>=701 && x<=781) || (x>=801 && x<=804)){ /*atmosphere*//*clouds*/
					if(!self.isCelcius){
						if self.locationForecast![2].temp! < 60{
							message.0 = "put on something warm";
						}else{
							if self.locationForecast![2].temp! > 70 {
								message.0 = "put on something cool";
							}
							else {
								message.0 = "put on something not so warm";
							}
						}
					}else{
						if self.locationForecast![2].temp! < 16{
							message.0 = "put on something warm";
						}else{
							if self.locationForecast![2].temp! > 21 {
								message.0 = "put on something cool";
							}
							else {
								message.0 = "put on something not so warm";
							}
						}
					}
					message.1 = nil;
				}else if(x==800){ /*clear*/
					if let y = self.locationForecast![2].icon{
						if y.last! == "n"{
							if(!self.isCelcius){
								if self.locationForecast![2].temp! < 60{
									message.0 = "put on something warm";
								}else{
									if self.locationForecast![2].temp! > 70 {
										message.0 = "put on something cool";
									}
									else {
										message.0 = "put on something not so warm";
									}
								}
							}else{
								if self.locationForecast![2].temp! < 16{
									message.0 = "put on something warm";
								}else{
									if self.locationForecast![2].temp! > 21 {
										message.0 = "put on something cool";
									}
									else {
										message.0 = "put on something not so warm";
									}
								}
							}
							message.1 = nil
						}else if y.last! == "d"{
							if(!self.isCelcius){
								if self.locationForecast![2].temp! < 60{
									message.0 = "put on something warm";
									message.1 = "put on sunglasses"
								}else{
									if self.locationForecast![2].temp! > 70 {
										message.0 = "put on something cool";
										message.1 = "put on sunglasses and wear sunscreen";
									}
									else {
										message.0 = "put on something not so warm";
										message.1 = "put on sunglasses"
									}
								}
							}else{
								if self.locationForecast![2].temp! < 16{
									message.0 = "put on something warm";
									message.1 = "put on sunglasses"
								}else{
									if self.locationForecast![2].temp! > 21 {
										message.0 = "put on something cool";
										message.1 = "put on sunglasses and wear sunscreen";
									}
									else {
										message.0 = "put on something not so warm";
										message.1 = "put on sunglasses"
									}
								}
							}
						}
					}
				}
			}
			self.content = AppDelegate.notifContent(now_weather_description: self.locationForecast![0].description!, now_temp: String(describing: Int(self.locationForecast![0].temp!)), fut_weather_description: self.locationForecast![1].description!, fut_temp: String(describing: Int(avgTmp)), message: message);/*fill up the content of the forecast*/
		}
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder(); /*hides keyboard when user clicks search*/
		
		/*get the location from search bar and send it to getCityWeather function*/
		if let locationString = searchBar.text, !locationString.isEmpty{
			self.getCityWeather(location: locationString);
			self.isCelcius = true;
			self.temp_unit.image = #imageLiteral(resourceName: "celc");
		}
	}
	var isForecastCalled: Bool = false; /*flag to set if the forecastAPI is called so that it won't make API calls again*/
	var isLocationForecast: Bool = true;/* If this is true, it is the forecast of current location, else it's forecast of elsewhere*/
	func getLocationForecast()
	{
		/*
		 * Helper function to be called after getting the location from the device
		 * It will update the forecast array (forecast data of every 3 hrs of the next 5 days)
		 */
		if(!self.isForecastCalled){
			/*get foracast data by calling weatherServices getForecast, initializing the array of instances "forecast"*/
			WeatherService.sharedInstance.getForecast(complete: {
				self.forecast = WeatherService.sharedInstance.forecastData;
				if(!self.isCelcius){
					for i in 0 ... (self.forecast!.count-1){
						self.forecast![i].temp = (Double(self.forecast![i].temp!) * 1.8 + 32);
					}
				}
				/*running reloading data on a seperate core to improve concurrency*/
				DispatchQueue.main.async {
					self.forecast_collection_view.reloadData();
				}
				if(self.isLocationForecast){
					self.isLocationForecast = false; /*set this to false so this block won't be entered again*/
					self.locationForecast = self.forecast /*set the content of locations forecast to what we get right away*/
					self.contentCalc();
					/*if we're getting the forecast of the current location, if notification is allowed set up sending notifications*/
					if(self.isNotif){
						if(self.content != nil){
							self.appDelegate.notification_center.removeAllPendingNotificationRequests();
							
							/*check users preference in terms of clothings*/
							if(!self.isClothes){
								self.content.message.0 = nil
							}
							if(!self.isAccessory){
								self.content.message.0 = nil
							}
							self.appDelegate.addNotification(nc: self.content);
						}
					}
					else{
						self.appDelegate.notification_center.removeAllPendingNotificationRequests();
					}
				}
			});
			self.isForecastCalled = true;
		}
	}
	
	var isWeatherCalled: Bool = false; /*flag to set if the weatherAPI is called*/
	func getLocationWeather()
	{
		/*
		* Helper function to get the location from the device
		* (this function only gets called if user allows access to location)
		*/
		if(!self.isWeatherCalled){ /*make API call only if we don't have the data already*/
			/*get weather data by calling weatherServices getWeather, initializing the instance "weather"*/
			WeatherService.sharedInstance.getWeather(complete: {
				self.weather = WeatherService.sharedInstance.parsedWeather ?? nil;
				/*getting the name of the city and country of the current location*/
				CLGeocoder().reverseGeocodeLocation(self.locationManager.location!, completionHandler: { (placemark: [CLPlacemark]?, error: Error?) in
					if error != nil{
						print("error: \(error!.localizedDescription)\n");
					}
					if let place = placemark?[0]{
						WeatherService.sharedInstance.cur_city = place.locality ?? ""; /*update the city*/
						WeatherService.sharedInstance.cur_state = place.administrativeArea ?? ""; /*update the state*/
						WeatherService.sharedInstance.cur_country = place.country ?? ""; /*update the country*/
						
						/*after retrieving all the information needed, update the labels*/
						self.updateLabels();
					}
				});
			});
			self.isWeatherCalled = true;/*set flag*/
		}
	}
	
	func getCityWeather(location: String){
		/*
		* Helper function to get the weather information of a city
		*/
		
		CLGeocoder().geocodeAddressString(location) {(placemark: [CLPlacemark]?, error: Error?) in
			if error != nil{
				print("error occured\n")
			}
			if let searched_location = placemark?[0]{
				WeatherService.sharedInstance.cur_lat = searched_location.location?.coordinate.latitude;
				WeatherService.sharedInstance.cur_long = searched_location.location?.coordinate.longitude;
				/*make API call to get the weather of the specified city then update the labels accordingly*/
				WeatherService.sharedInstance.getWeather(complete: {
					WeatherService.sharedInstance.cur_city = searched_location.locality ?? ""; /*update the city*/
					WeatherService.sharedInstance.cur_state = searched_location.administrativeArea ?? ""; /*update the state*/
					WeatherService.sharedInstance.cur_country = searched_location.country ?? ""; /*update the country*/
					self.weather = WeatherService.sharedInstance.parsedWeather; /*update the weather service instance*/
					self.updateLabels();
					/*make API call to get the forecast of the specified weather and update the lables accordingly*/
					WeatherService.sharedInstance.getForecast(complete: {
						self.forecast = WeatherService.sharedInstance.forecastData;
						
						/*running reloading data on a seperate core to improve concurrency*/
						DispatchQueue.main.async {
							self.forecast_collection_view.reloadData();
						}
					})
				});
			}
		}
	}
	
	func userDidNotAllowAccessToLocation()
	{
		/*
		* Helper function to show an alert box if
		* user didn't let us use their location
		*/
		
		/*setting up the alert box*/
		let alert_box = UIAlertController(title: "Need Location", message: "We need your location to tell you the weather of where you are", preferredStyle: UIAlertControllerStyle.alert)
		
		/*the "OK" button will take the user to the settings of the app and lets them change their location authorization setting*/
		alert_box.addAction(UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.default, handler: ({ (action) in
			if let url = URL(string: UIApplicationOpenSettingsURLString){
				UIApplication.shared.open(url, options: [:], completionHandler: nil)
			}
		})))
		
		/*the "Don't Care" button will dismiss the message and won't update the location*/
		alert_box.addAction(UIAlertAction(title: "Don't Care", style: UIAlertActionStyle.cancel, handler: { (action) in
			alert_box.dismiss(animated: true, completion: nil)
		}))
		
		/*pops up the alert box*/
		self.present(alert_box, animated: true, completion: nil)
	}
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if self.locationManager.location != nil{
			self.getLocationWeather();
			self.getLocationForecast();
			/*running reloading data on a seperate core to improve concurrency*/
			DispatchQueue.main.async {
				self.forecast_collection_view.reloadData();
			}
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		/*
		* library function; will get called once there is a change in location
		*/
		switch CLLocationManager.authorizationStatus() {
		case .denied: /*if the user has denied access to the location, send a alert box message*/
			self.userDidNotAllowAccessToLocation();
			break;
		case .authorizedAlways, .authorizedWhenInUse:
			/*if access to the location is authorized, keep doing this do-while loop till we get the coordinates*/
			/*do this do-while loop for 1000 times until we have the location*/
			var counter = 0
			repeat{
				self.locationManager.requestWhenInUseAuthorization();
				counter += 1;
				if(counter == 1000){
					break;
				}
			}while(self.locationManager.location == nil);
			/*if the location is still not updated after 1000 times of requesting for location, give a message and stop trying to get location*/
			if(self.locationManager.location == nil){
				
				/*if information is not retrieved, push an error message*/
				let locationErr = UIAlertController(title: "Couldn't get the location!", message: nil, preferredStyle: UIAlertControllerStyle.alert)
				locationErr.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: { (action) in
					locationErr.dismiss(animated: true, completion: nil)
				}))
				self.present(locationErr, animated: true, completion: nil);
			}else{
				let current_location = self.locationManager.location!/*get current location*/
				WeatherService.sharedInstance.cur_lat = current_location.coordinate.latitude;/*update weatherServices latitude*/
				WeatherService.sharedInstance.cur_long = current_location.coordinate.longitude;/*update weatherServices longitude*/
				self.getLocationWeather();
				self.getLocationForecast();
				/*running reloading data on a seperate core to improve concurrency*/
				DispatchQueue.main.async {
					self.forecast_collection_view.reloadData();
				}
			}
			break;
		default:
			break;
		}
	}
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 8; /*returning 8 because this view shows the forecast data of the next 24 hrs every 3 hrs => 24/3 = 8*/
	}
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "forecastCollectionViewCell", for: indexPath) as! forecastCollectionViewCell

		if(self.forecast != nil && !self.forecast!.isEmpty){
			var image: UIImage?;
			/*udpating the weather icon*/
			if let x = self.forecast![indexPath.row].weather{
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
					if let y = self.forecast![indexPath.row].icon{
						if y.last! == "n"{
							image = #imageLiteral(resourceName: "clearnight");
						}else if y.last! == "d"{
							image = #imageLiteral(resourceName: "clearday");
						}
					}
				}else{ /*unknown*/
					image = #imageLiteral(resourceName: "atmosphere");
				}
			}
			cell.forecast_icon.image = image;
			cell.weather_description.text = self.forecast![indexPath.row].description!;
			cell.weather_time.text = self.forecast![indexPath.row].time!;
			cell.weather_temp.text = String(describing: Int(self.forecast![indexPath.row].temp!));
		}
		return cell;
	}
	
	@objc func tapOnScreen()
	{
		/*
		function called upon tapping on tempreture label
		changes the tempreture unit,
		Celcius -> Fahrenheit
		Fahrenheit -> Celcius
		*/
		self.isNotif = UserDefaults.standard.bool(forKey: "notifSwitch") /*update isNotif flag*/
		if weather != nil{
			if isCelcius{

				for i in 0 ... (forecast!.count-1){
					forecast![i].temp = (Double(forecast![i].temp!) * 1.8 + 32);
					if(self.locationForecast != nil){
						locationForecast![i].temp = (Double(locationForecast![i].temp!) * 1.8 + 32);
					}
					/*running reloading data on a seperate core to improve concurrency*/
					DispatchQueue.main.async {
						self.forecast_collection_view.reloadData();
					}
				}
				
				let fahr_temp = Double(weather!.temp!) * 1.8 + 32;/*Fahrenheit conversion formula*/
				let fahr_low = Double(weather!.min_temp!) * 1.8 + 32;
				let fahr_high = Double(weather!.max_temp!) * 1.8 + 32;
				
				tempreture_label.text = String(describing: Int(fahr_temp));
				temp_low.text = "low: \(String(describing: Int(fahr_low)))";
				temp_high.text = "high: \(String(describing: Int(fahr_high)))";
				
				self.temp_unit.image = #imageLiteral(resourceName: "fahr");
				isCelcius = false;
				UserDefaults.standard.set(false, forKey: "isCelcius");
				if(self.isNotif && self.content != nil){
					self.appDelegate.notification_center.removeAllPendingNotificationRequests();
					contentCalc();
					self.appDelegate.addNotification(nc: self.content);
				}
			}else{
				for i in 0 ... (forecast!.count-1){
					forecast![i].temp = ((5/9) * (Double(forecast![i].temp! - 32)));
					if(self.locationForecast != nil){
						self.locationForecast![i].temp = ((5/9) * (Double(self.locationForecast![i].temp! - 32)));
					}
					/*running reloading data on a seperate core to improve concurrency*/
					DispatchQueue.main.async {
						self.forecast_collection_view.reloadData();
					}
				}
				tempreture_label.text =  String(describing: weather!.temp!)/*by default it's celcius, so show default*/
				temp_low.text = "low: \(String(describing: weather!.min_temp!))";
				temp_high.text = "high: \(String(describing: weather!.max_temp!))";
				
				self.temp_unit.image = #imageLiteral(resourceName: "celc");
				isCelcius = true;
				UserDefaults.standard.set(true, forKey: "isCelcius");
				if(self.isNotif && self.content != nil){
					self.appDelegate.notification_center.removeAllPendingNotificationRequests();
					contentCalc();
					self.appDelegate.addNotification(nc: self.content);
				}
			}
		}
	}
	func updateLabels()
	{
		/*
		Helper function to update the labels
		its called in the
		*/
		if (weather != nil){
			
			/*check if users settings is celcius*/
			if(!isCelcius){
				let fahr_temp = Double(weather!.temp!) * 1.8 + 32;/*Fahrenheit conversion formula*/
				let fahr_low = Double(weather!.min_temp!) * 1.8 + 32;
				let fahr_high = Double(weather!.max_temp!) * 1.8 + 32;
				
				tempreture_label.text = String(describing: Int(fahr_temp));
				temp_low.text = "low: \(String(describing: Int(fahr_low)))";
				temp_high.text = "high: \(String(describing: Int(fahr_high)))";
				
			}else{
				tempreture_label.text =  String(describing: weather!.temp!);
				temp_low.text = "low: \(String(describing: weather!.min_temp!))";
				temp_high.text = "high: \(String(describing: weather!.max_temp!))";
			}
			
			/*udpating the weather icon*/
			if let x = weather!.weather{
				if(x>=200 && x<=232){ /*thunderstorm*/
					weather_icon.image = #imageLiteral(resourceName: "thunderstorm");
				}else if(x>=300 && x<=321){ /*drizzle*/
					weather_icon.image = #imageLiteral(resourceName: "drizzle");
				}else if(x>=500 && x<=531){ /*rain*/
					weather_icon.image = #imageLiteral(resourceName: "rain");
				}else if(x>=600 && x<=622){ /*snow*/
					weather_icon.image = #imageLiteral(resourceName: "snow")
				}else if(x>=701 && x<=781){ /*atmosphere*/
					weather_icon.image = #imageLiteral(resourceName: "atmosphere");
				}else if(x>=801 && x<=804){ /*clouds*/
					weather_icon.image = #imageLiteral(resourceName: "clouds");
				}else if(x==800){ /*clear*/
					if let y = weather!.icon{
						if y.last! == "n"{
							weather_icon.image = #imageLiteral(resourceName: "clearnight");
						}else if y.last! == "d"{
							weather_icon.image = #imageLiteral(resourceName: "clearday");
						}
					}
				}else{ /*unknown*/
					
				}
			}
			
			if(weather!.description != nil){
				weather_description.text = "\(String(describing: (weather!.description)!))";
			}
			if(weather!.sunset_timestamp != nil){
				sunset.text = "Sunset: \(weather!.sunset_timestamp!)";
			}
			if(weather!.sunrise_timestamp != nil){
				sunrise.text = "Sunrise: \(weather!.sunrise_timestamp!)";
			}
			if(weather!.humidity != nil){
				humidity.text = "Humidity: \(weather!.humidity!) %";
			}
			if(weather!.pressure != nil){
				pressure.text = "Pressure: \(weather!.pressure!) hPa";
			}
			if(weather!.wind_speed != nil || weather!.wind_deg != nil){
				/*
				converting wind degrees to directions
				1   North               N
				5   Northeast           NE
				9   East                E
				13  Southeast           SE
				17  South               S
				21  Southwest           SW
				25  West                W
				29  Northwest           NW
				*/
				var s = weather!.wind_speed!;
				s = s * 2.23694;
				var d = weather!.wind_deg!;
				d = d/32;
				var w = "Wind: ";
				if(d>=1 && d<5){
					w += "N";
				}else if(d>=5 && d<9){
					w += "NE";
				}else if(d>=9 && d<13){
					w += "E";
				}else if(d>=13 && d<17){
					w += "SE";
				}else if(d>=17 && d<21){
					w += "S";
				}else if(d>=21 && d<25){
					w += "SW";
				}else if(d>=25 && d<29){
					w += "W";
				}else if(d>=29 || d<1){
					w += "NW";
				}
				w+=" \(String(describing: Int(s))) mph"
				wind.text = w;
			}
			
			if(WeatherService.sharedInstance.cur_state! != "" && WeatherService.sharedInstance.cur_country! != "" && WeatherService.sharedInstance.cur_city! != ""){
				city.text = String(describing: WeatherService.sharedInstance.cur_city!);
				state.text = ", \(String(describing: WeatherService.sharedInstance.cur_state!))";
				if (WeatherService.sharedInstance.cur_country! == "United States" || WeatherService.sharedInstance.cur_country! == "Canada"){
					country.text = "";
				}
				else{
					country.text = String(describing: WeatherService.sharedInstance.cur_country!);
				}
			}
				/*cases where 2 or less of the location identifiers are known*/
			else{
				if(WeatherService.sharedInstance.cur_state! != "" &&  WeatherService.sharedInstance.cur_country! != ""){
					city.text = "";
					state.text = "\(String(describing: WeatherService.sharedInstance.cur_state!))";
					country.text = "\(String(describing: WeatherService.sharedInstance.cur_country!))";
				}else if(WeatherService.sharedInstance.cur_city! != "" && WeatherService.sharedInstance.cur_state! != ""){
					city.text = "\(String(describing: WeatherService.sharedInstance.cur_city!))";
					state.text = ", \(String(describing: WeatherService.sharedInstance.cur_state!))";
					country.text = "";
				}else if(WeatherService.sharedInstance.cur_city! != "" && WeatherService.sharedInstance.cur_country! != ""){
					city.text = "\(String(describing: WeatherService.sharedInstance.cur_city!))";
					state.text = "";
					country.text = ", \(String(describing: WeatherService.sharedInstance.cur_country!))";
				}else{
					if(WeatherService.sharedInstance.cur_city! != ""){
						city.text = "\(String(describing: WeatherService.sharedInstance.cur_city!))";
						state.text = "";
						country.text = "";
					}
					else if(WeatherService.sharedInstance.cur_state! != ""){
						city.text = "";
						state.text = "\(String(describing: WeatherService.sharedInstance.cur_state!))";
						country.text = "";
					}
					else{
						city.text = "";
						state.text = "";
						country.text = "\(String(describing: WeatherService.sharedInstance.cur_country!))";
					}
				}
			}
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		/*
		 * Function for transferring the forecast data into the weekly view, for showing the weekly view data
		 * and settings view for updating the notification
		 */
		if(segue.identifier == "show_weekly"){
			let weekly_view = segue.destination as! WeeklyViewController
			weekly_view.forecast = self.forecast;
		}
		else if(segue.identifier == "show_settings"){
			let settings = segue.destination as! SettingsViewController
			if(self.locationForecast != nil){
				settings.forecast = self.locationForecast!;
				settings.content = self.content;
			}
		}
	}
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	deinit { /*destructor*/
		
		/*upon dismissing this view controller class, we need to get rid of the observer we set up earlier*/
		if let notification = notification {
			NotificationCenter.default.removeObserver(notification)
		}
		
		/*resetting the flags*/
		isWeatherCalled = false;
		isForecastCalled = false;
		self.isLocationForecast = true;
	}
}

