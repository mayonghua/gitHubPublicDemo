//
//  LocationDemoViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/4.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

class LocationDemoViewController: UIViewController, BMKMapViewDelegate, BMKLocationServiceDelegate {
    
    var locationService: BMKLocationService!
    
    @IBOutlet weak var _mapView: BMKMapView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var followHeadingButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加按钮
        let customRightBarButtonItem = UIBarButtonItem(title: "自定义精度圈", style: .Plain, target: self, action: Selector("customLocationAccuracyCircle"))
        self.navigationItem.rightBarButtonItem = customRightBarButtonItem
        
        locationService = BMKLocationService()
        locationService.allowsBackgroundLocationUpdates = true
        
        startButton.enabled = true
        stopButton.enabled = false
        followButton.enabled = false
        followHeadingButton.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        locationService.delegate = self
        _mapView.delegate = self
        _mapView.viewWillAppear()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        locationService.delegate = self
        _mapView.delegate = nil
        _mapView.viewWillDisappear()
    }
    
    //自定义精度圈
    func customLocationAccuracyCircle() {
        let param = BMKLocationViewDisplayParam()
        param.accuracyCircleStrokeColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        param.accuracyCircleFillColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.3)
        _mapView.updateLocationViewWithParam(param)
    }
    
    // MARK: - IBAction
    @IBAction func startLocation(sender: AnyObject) {
        print("进入普通定位态");
        locationService.startUserLocationService()
        _mapView.showsUserLocation = false//先关闭显示的定位图层
        _mapView.userTrackingMode = BMKUserTrackingModeNone;//设置定位的状态
        _mapView.showsUserLocation = true//显示定位图层
        
        startButton.enabled = false
        stopButton.enabled = true
        followButton.enabled = true
        followHeadingButton.enabled = true
    }
    
    @IBAction func stopLocation(sender: AnyObject) {
        locationService.stopUserLocationService()
        _mapView.showsUserLocation = false
        
        startButton.enabled = true
        stopButton.enabled = false
        followButton.enabled = false
        followHeadingButton.enabled = false
    }
    
    @IBAction func followMode(sender: AnyObject) {
        print("进入跟随态");
        _mapView.userTrackingMode = BMKUserTrackingModeFollow;
    }
    
    @IBAction func followHeadingMode(sender: AnyObject) {
        print("进入罗盘态");
        _mapView.userTrackingMode = BMKUserTrackingModeFollowWithHeading
    }
    
    
    // MARK: - BMKMapViewDelegate
   
    
    // MARK: - BMKLocationServiceDelegate
    
    /**
    *在地图View将要启动定位时，会调用此函数
    *@param mapView 地图View
    */
    func willStartLocatingUser() {
        print("willStartLocatingUser");
    }
    
    /**
    *用户方向更新后，会调用此函数
    *@param userLocation 新的用户位置
    */
    func didUpdateUserHeading(userLocation: BMKUserLocation!) {
        print("heading is \(userLocation.heading)")
        _mapView.updateLocationData(userLocation)
    }
    
    /**
    *用户位置更新后，会调用此函数
    *@param userLocation 新的用户位置
    */
    func didUpdateBMKUserLocation(userLocation: BMKUserLocation!) {
        print("didUpdateUserLocation lat:\(userLocation.location.coordinate.latitude) lon:\(userLocation.location.coordinate.longitude)")
        _mapView.updateLocationData(userLocation)
    }
    
    /**
    *在地图View停止定位后，会调用此函数
    *@param mapView 地图View
    */
    func didStopLocatingUser() {
        print("didStopLocatingUser")
    }

}
