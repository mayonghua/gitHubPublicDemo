//
//  IndoorDemoViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 16/5/26.
//  Copyright © 2016年 baidu. All rights reserved.
//

import UIKit

class IndoorDemoViewController: UIViewController, BMKMapViewDelegate, BMKPoiSearchDelegate, UITableViewDataSource, UITableViewDelegate {
    var _mapView: BMKMapView!
    var _search: BMKPoiSearch!
    var _floorTableView: UITableView!//显示楼层条
    var _indoorMapInfoFocused: BMKBaseIndoorMapInfo!//存储当前聚焦的室内图
    
    @IBOutlet weak var _searchView: UIView!
    @IBOutlet weak var _keywordText: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let topHeight = (self.navigationController?.navigationBar.frame.height)! + UIApplication.sharedApplication().statusBarFrame.height
        
        //add mapview
        _mapView = BMKMapView(frame: CGRect(x: 0, y: topHeight, width: self.view.frame.width, height: self.view.frame.height - topHeight))
        self.view.addSubview(_mapView)
        self.view.sendSubviewToBack(_mapView)
        _mapView.zoomLevel = 18
        _mapView.centerCoordinate = CLLocationCoordinate2DMake(39.917, 116.379)
        _mapView.baseIndoorMapEnabled = true//打开室内图
        _indoorMapInfoFocused = BMKBaseIndoorMapInfo()
        
        //init search
        _search = BMKPoiSearch()
        
        //init search view
        _keywordText.text = "美食"
        _searchView.hidden = true
        
        //add floor view
        _floorTableView = UITableView()
        let h : CGFloat = 150
        let y = (self.view.frame.size.height - h - 100.0)
        _floorTableView.frame = CGRectMake(10, y, 35, h)
        _floorTableView.alpha = 0.8
        _floorTableView.layer.borderWidth = 1
        _floorTableView.layer.borderColor = UIColor.grayColor().colorWithAlphaComponent(0.7).CGColor
        _floorTableView.delegate = self
        _floorTableView.dataSource = self
        _floorTableView.separatorStyle = .None
        _floorTableView.hidden = true
        _floorTableView.allowsSelection = true
        self.view.addSubview(_floorTableView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(IndoorDemoViewController.hiddenKeyBoard))
        tap.cancelsTouchesInView = false//添加自定义手势时，需设置，否则影响地图的操作
        tap.delaysTouchesEnded = false//添加自定义手势时，需设置，否则影响地图的操作
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _mapView.viewWillAppear()
        _mapView.delegate = self
        _search.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        _mapView.viewWillDisappear()
        _mapView.delegate = nil
        _search.delegate = nil
    }
    
    // 发起室内检索
    @IBAction func indoorSearchAction(sender: UIButton) {
        let option = BMKPoiIndoorSearchOption()
        option.indoorId = _indoorMapInfoFocused?.strID
        option.keyword = _keywordText.text
        option.pageIndex = 0
        option.pageCapacity = 20
        let flag = _search.poiIndoorSearch(option)
        if !flag {
            PromptInfo.showText("室内检索发送失败")
        }
    }
    
    //隐藏键盘
    func hiddenKeyBoard() {
        _keywordText.resignFirstResponder()
    }
    
    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if _indoorMapInfoFocused?.arrStrFloors != nil {
            return (_indoorMapInfoFocused?.arrStrFloors.count)!
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("FloorCell") as? BMKIndoorFloorCell
        if cell == nil {
            cell = BMKIndoorFloorCell(style: .Default, reuseIdentifier: "FloorCell")
        }
        cell!.floorTitleLabel.text = _indoorMapInfoFocused?.arrStrFloors[indexPath.row] as? String
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 30.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //进行楼层切换
        let error = _mapView.switchBaseIndoorMapFloor(_indoorMapInfoFocused.arrStrFloors[indexPath.row] as! String, withID: _indoorMapInfoFocused.strID)
        if error == BMKSwitchIndoorFloorSuccess {
            _floorTableView.scrollToNearestSelectedRowAtScrollPosition( .Middle, animated: true)
            print("切换楼层成功")
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
    
    // MARK: - BMKMapViewDelegate
    
    /**
     *地图进入/移出室内图会调用此接口
     *@param mapview 地图View
     *@param flag  YES:进入室内图; NO:移出室内图
     *@param info 室内图信息
     */
    func mapview(mapView: BMKMapView!, baseIndoorMapWithIn flag: Bool, baseIndoorMapInfo info: BMKBaseIndoorMapInfo!) {
        var showIndoor = false
        if flag {//进入室内图
            if info != nil && info.arrStrFloors.count > 0 {
                _indoorMapInfoFocused.arrStrFloors = info.arrStrFloors
                _indoorMapInfoFocused.strFloor = info.strFloor
                _indoorMapInfoFocused.strID = info.strID
                
                _floorTableView.reloadData()
                let index = info.arrStrFloors.indexOfObject(info.strFloor)
                _floorTableView.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: true, scrollPosition: .Middle)
                showIndoor = true
            }
        }
        
        _floorTableView.hidden = !showIndoor;
        _searchView.hidden = !showIndoor;
    }
    
    // MARK: - BMKPoiSearchDelegate
    /**
     *返回POI室内搜索结果
     *@param searcher 搜索对象
     *@param poiIndoorResult 搜索结果列表
     *@param errorCode 错误号，@see BMKSearchErrorCode
     */
    func onGetPoiIndoorResult(searcher: BMKPoiSearch!, result poiIndoorResult: BMKPoiIndoorResult!, errorCode: BMKSearchErrorCode) {
        print("onGetPoiIndoorResult errorcode: \(errorCode)")
        
        if errorCode == BMK_SEARCH_NO_ERROR {
            //成功获取结果
            for element in poiIndoorResult.poiIndoorInfoList {
                let info = element as! BMKPoiIndoorInfo
                print("name: \(info.name)  uid: \(info.uid)  floor: \(info.floor)")
            }
            PromptInfo.showText("室内检索成功，共获取\(poiIndoorResult.poiIndoorInfoList.count)条信息")
        } else {
            //检索失败
            PromptInfo.showText("室内检索失败")
        }
    }
    
}


class BMKIndoorFloorCell: UITableViewCell {
    
    var floorTitleLabel: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clearColor()
        
        floorTitleLabel = UILabel(frame: CGRectMake(0, 0, 35, 30))
        floorTitleLabel.textAlignment = .Center
        floorTitleLabel.textColor = UIColor.blackColor()
        self.addSubview(floorTitleLabel)
        
        let selectedBg = UIView(frame: self.frame)
        selectedBg.backgroundColor = UIColor(red: 50.0/255, green:120.0/255.0, blue:1, alpha:0.8)
        self.selectedBackgroundView = selectedBg
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}