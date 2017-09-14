//
//  RadarUploadViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/9.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

let MY_LOCATION_UPDATE_NOTIFICATION = "MY_LOCATION_UPDATE_NOTIFICATION"


class RadarUploadViewController: UIViewController, BMKRadarManagerDelegate, BMKLocationServiceDelegate  {
    
    @IBOutlet weak var userTextField: UITextField!
    @IBOutlet weak var infoTextField: UITextField!
    @IBOutlet weak var autoUploadButton: UIButton!
    @IBOutlet weak var stopUploadButton: UIButton!
    
    var locServer: BMKLocationService! = BMKLocationService()
    var radarManager: BMKRadarManager! = BMKRadarManager.getRadarManagerInstance()
    var isAutoUploading = false
    
    var coorLock = NSLock()
    var currCoordinate: CLLocationCoordinate2D! = CLLocationCoordinate2D()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "周边雷达-上传"
        self.tabBarItem.title = "上传位置"
        
        locServer.delegate = self
        locServer.startUserLocationService()
        
        autoUploadButton.enabled = true
        stopUploadButton.enabled = false
        let tap = UITapGestureRecognizer(target: self, action: Selector("hiddenKeyBoard"))
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        radarManager.addRadarManagerDelegate(self)//添加radar delegate
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        radarManager.removeRadarManagerDelegate(self)//不用需移除，否则影响内存释放
    }
    
    deinit {
        radarManager = nil
        BMKRadarManager.releaseRadarManagerInstance()
        locServer.delegate = nil
        locServer.stopUserLocationService()
        locServer = nil
    }

    // MARK: - IBAction
    ///上传我的位置信息
    @IBAction func uploadAction(sender: UIButton) {
        hiddenKeyBoard()
        let res = radarManager.uploadInfoRequest(getCurrInfo())
        if res {
            print("upload 请求成功");
        } else {
            print("upload 请求失败");
        }
    }
    
    ///启动自动上传
    @IBAction func autoUploadAction(sender: UIButton) {
        hiddenKeyBoard()
        radarManager.startAutoUpload(5)
        isAutoUploading = true
        autoUploadButton.enabled = false
        stopUploadButton.enabled = true
    }
    
    ///停止自动上传
    @IBAction func stopAutoUploadAction(sender: UIButton) {
        hiddenKeyBoard()
        radarManager.stopAutoUpload()
        isAutoUploading = false
        autoUploadButton.enabled = true
        stopUploadButton.enabled = false
    }
    
    ///清除我的位置信息
    @IBAction func clearAction(sender: AnyObject) {
        hiddenKeyBoard()
        if radarManager.clearMyInfoRequest() {
            print("clear 请求成功");
        } else {
            print("clear 请求失败");
        }
    }
    
    ///userId编辑完毕
    @IBAction func userIdTextEditEnd(sender: UITextField) {
        hiddenKeyBoard()
        if userTextField.text?.characters.count > 0 {
            if radarManager.userId != userTextField.text {
                radarManager.userId = userTextField.text
            }
        }
    }
    
    // MARK: - BMKRadarManagerDelegate
    
    /*
    *开启自动上传，需实现该回调
    */
    func getRadarAutoUploadInfo() -> BMKRadarUploadInfo! {
        return getCurrInfo()
    }
    
    /**
    *返回雷达 上传结果
    *@param error 错误号，@see BMKRadarErrorCode
    */
    func onGetRadarUploadResult(error: BMKRadarErrorCode) {
        print("onGetRadarUploadResult: \(error)")
        if error == BMK_RADAR_NO_ERROR {
            PromptInfo.showText("成功上传我的位置")
        }
    }
    
    /**
    *返回雷达 清除我的信息结果
    *@param error 错误号，@see BMKRadarErrorCode
    */
    func onGetRadarClearMyInfoResult(error: BMKRadarErrorCode) {
        print("onGetRadarClearMyInfoResult: \(error)")
        if error == BMK_RADAR_NO_ERROR {
            PromptInfo.showText("成功清除我的位置")
        }
    }
    
    // MARK: - BMKLocationServiceDelegate
    
    /**
    *在地图View将要启动定位时，会调用此函数
    *@param mapView 地图View
    */
    func willStartLocatingUser() {
        print("willStartLocatingUser")
    }
    
    /**
     *用户位置更新后，会调用此函数
     *@param userLocation 新的用户位置
     */
    func didUpdateBMKUserLocation(userLocation: BMKUserLocation!) {
        NSNotificationCenter.defaultCenter().postNotificationName(MY_LOCATION_UPDATE_NOTIFICATION, object: nil, userInfo: ["loc" : userLocation])
        coorLock.lock()
        currCoordinate.latitude = userLocation.location.coordinate.latitude
        currCoordinate.longitude = userLocation.location.coordinate.longitude
        coorLock.unlock()
    }
    
    /**
     *在地图View停止定位后，会调用此函数
     *@param mapView 地图View
     */
    func didStopLocatingUser() {
        print("didStopLocatingUser")
    }

    
    // MARK: -
    func hiddenKeyBoard() {
        userTextField.resignFirstResponder()
        infoTextField.resignFirstResponder()
    }

    ///获取当前的信息
    func getCurrInfo() -> BMKRadarUploadInfo {
        let info = BMKRadarUploadInfo()
        info.extInfo = infoTextField.text
        coorLock.lock()
        info.pt = currCoordinate
        coorLock.unlock()
        return info
    }

}