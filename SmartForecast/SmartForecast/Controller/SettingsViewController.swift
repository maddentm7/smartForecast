//
//  SettingsViewController.swift
//  SmartForecast
//
//  Created by Parsa Bagheri on 6/2/18.
//  Copyright © 2018 Parsa Bagheri. All rights reserved.
//
//  This is a group project, sharing files and resources amongst
//  the group mates is consented.
//
//  Group Members:
//  		Parsa Bagheri, Yanting Liu, Taylor Madden,
//  		Kevin Roeske, Bill Shang

import UIKit

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
	
	var selected_hr: Int = 8; /*default is at 8*/
	let hrs = [8, 11, 14, 17, 20, 23, 2, 5]; /*the times that the user can select from*/
	let pickerViewHrs = ["8:00 AM", "11:00 AM", "2:00 PM", "5:00 PM", "8:00 PM", "11:00 PM", "2:00 AM", "5:00 AM"];
	var content: (AppDelegate.notifContent)!; /*instance of notifContent passed to this view from view controller*/
	var content_message: (String?, String?)!; /*instance of the message that content will have for local use*/
	let appDelegate = UIApplication.shared.delegate as! AppDelegate /*instance of app delegate*/
	@IBOutlet weak var time_picker: UIPickerView!
	@IBOutlet weak var show_notif: UISwitch!
	@IBOutlet weak var suggest_accessories: UISwitch!
	@IBOutlet weak var suggest_clothes: UISwitch!
	let app_delegate  = UIApplication.shared.delegate as? AppDelegate /*instance of the AppDelegate*/
	var forecast: [ForecastData]?; /*instance of forecast data*/
	
	/*following fucntions set up the picker view for selecting time*/
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return hrs.count;
	}
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		self.selected_hr = hrs[row];
		UserDefaults.standard.set(self.selected_hr, forKey: "selectedHour");
		self.appDelegate.notification_center.removeAllPendingNotificationRequests();
		if(content != nil){
			self.appDelegate.selectedHour = self.selected_hr;
			self.appDelegate.addNotification(nc: content);
		}
	}
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return pickerViewHrs[row];
	}
	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
		let titleData = pickerViewHrs[row];
		let myTitle = NSAttributedString(string: titleData, attributes: [NSAttributedStringKey.font:UIFont(name: "Georgia", size: 15.0)!,NSAttributedStringKey.foregroundColor:UIColor.white])
		return myTitle
	}
	
	/*function that determines what to do one the accessories switch is turned on/off*/
	@IBAction func suggestAccsSwitch(_ sender: UISwitch) {
		if(sender.isOn){
			/*if on and content is not empty, set the 2nd element of the message tuple which is the accessories to the appropriate message and start sending notifications*/
			if(self.content != nil){
				self.content.message.1 = self.content_message.1;
				self.appDelegate.notification_center.removeAllPendingNotificationRequests();
				self.appDelegate.selectedHour = self.selected_hr;
				self.appDelegate.addNotification(nc: content);
			}
		}else{
			/*if off and content is not empty, set the 2nd element of the message tuple which is the accessories to nil and start sending notifications*/
			if(self.content != nil){
				self.content.message.1 = nil;
				self.appDelegate.notification_center.removeAllPendingNotificationRequests();
				self.appDelegate.selectedHour = self.selected_hr;
				self.appDelegate.addNotification(nc: content);
			}
		}
		UserDefaults.standard.set(suggest_accessories.isOn, forKey: "accessorySwitch");
	}
	@IBAction func suggestClothesSwitch(_ sender: UISwitch) {
		if(sender.isOn){
			/*if on and content is not empty, set the 1st element of the message tuple which is the clothing options to the appropriate message and start sending notifications*/
			if(self.content != nil){
				self.content.message.0 = self.content_message.0;
				self.appDelegate.notification_center.removeAllPendingNotificationRequests();
				self.appDelegate.selectedHour = self.selected_hr;
				self.appDelegate.addNotification(nc: content);
			}
		}else{
			/*if on and content is not empty, set the 1st element of the message tuple which is the clothing options to nil and start sending notifications*/
			if(self.content != nil){
				self.content.message.0 = nil;
				self.appDelegate.notification_center.removeAllPendingNotificationRequests();
				self.appDelegate.selectedHour = self.selected_hr;
				self.appDelegate.addNotification(nc: content);
			}
		}
		UserDefaults.standard.set(suggest_clothes.isOn, forKey: "clothesSwitch");
	}
	@IBAction func showNotifSwitch(_ sender: UISwitch) {
		if(sender.isOn){
			/*if on, everythin is enabled and we start sending notifications*/
			suggest_accessories.isEnabled = true;
			suggest_clothes.isEnabled = true;
			time_picker.isUserInteractionEnabled = true;
			self.appDelegate.notification_center.removeAllPendingNotificationRequests();
			if(content != nil){
				self.appDelegate.selectedHour = self.selected_hr;
				self.appDelegate.addNotification(nc: content);
			}
		}else{
			/*if off, everythin is disabled and we stop sending notifications*/
			suggest_accessories.isEnabled = false;
			suggest_clothes.isEnabled = false;
			time_picker.isUserInteractionEnabled = false;
			self.appDelegate.notification_center.removeAllPendingNotificationRequests();
		}
		UserDefaults.standard.set(show_notif.isOn, forKey: "notifSwitch");

	}
	@IBOutlet weak var settings_view: UIView!/*the view where all the settings is in*/
	override func viewDidLoad() {
		super.viewDidLoad()
		settings_view.layer.cornerRadius = 15; /*give settings view round corners*/
		if(self.content != nil){
			self.content_message = self.content.message;
		}
		selected_hr = UserDefaults.standard.integer(forKey: "selectedHour") == 0 ? 8 : UserDefaults.standard.integer(forKey: "selectedHour");
		time_picker.selectRow(hrs.index(of: selected_hr)!, inComponent: 0, animated: false);
		show_notif.isOn = UserDefaults.standard.bool(forKey: "notifSwitch");
		suggest_accessories.isOn = UserDefaults.standard.bool(forKey: "accessorySwitch");
		suggest_clothes.isOn = UserDefaults.standard.bool(forKey: "clothesSwitch");
		suggest_clothes.isEnabled = show_notif.isOn;
		suggest_accessories.isEnabled = show_notif.isOn;
		time_picker.isUserInteractionEnabled = show_notif.isOn;
	}

	@IBAction func done(_ sender: UIButton) {
		dismiss(animated: true, completion: nil)
	}
}
