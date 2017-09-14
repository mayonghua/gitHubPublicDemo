//
//  RadarNearbyViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/9.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

class RadarNearbyViewController: UIViewController, BMKMapViewDelegate, BMKRadarManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var segControl: UISegmentedControl!
    @IBOutlet weak var preButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var curPageLabel: UILabel!
 
    var tableView: UITableView!
    var _mapView: BMKMapView!
    
    var radarManager: BMKRadarManager! = BMKRadarManager.getRadarManagerInstance()
    
    var myCoor = CLLocationCoordinate2D()
    
    var curPageIndex = 0
    var nearbyInfos = [BMKRadarNearbyInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "周边雷达-检索"
        self.tabBarItem.title = "检索周边"
        
        let rect = scrollView.frame
        scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * 2, scrollView.frame.size.height);
        tableView = UITableView(frame: CGRectMake(0, 0, rect.size.width, rect.size.height - 30))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.scrollEnabled = true
        tableView.clipsToBounds = true
        scrollView.addSubview(tableView)
        _mapView = BMKMapView(frame: CGRectMake(rect.size.width, 0, rect.size.width, rect.size.height))
        _mapView.showsUserLocation = true;
        scrollView.addSubview(_mapView)
        
        preButton.enabled = false
        nextButton.enabled = false
        curPageLabel.hidden = false
        curPageLabel.text = ""
        
        ///我的位置改变通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updateMyLocation:"), name: MY_LOCATION_UPDATE_NOTIFICATION, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _mapView.viewWillAppear()
        _mapView.delegate = self
        radarManager.addRadarManagerDelegate(self)//添加radar delegate
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        _mapView.viewWillDisappear()
        _mapView.delegate = nil
        radarManager.removeRadarManagerDelegate(self)//不用需移除，否则影响内存释放
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        radarManager = nil
        BMKRadarManager.releaseRadarManagerInstance()
    }


    // MARK: - IBAction
    ///获取周边信息
    @IBAction func nearbyAction(sender: UIButton) {
        nearbySearchWithPageIndex(0)
    }
    ///清除本地缓存
    @IBAction func clearAction(sender: UIButton) {
        updateNearbyInfos([BMKRadarNearbyInfo]())
        preButton.enabled = false
        nextButton.enabled = false
        curPageLabel.text = ""
    }
    ///切换附近信息显示方式
    @IBAction func switchResShowAction(sender: UISegmentedControl) {
        let x = scrollView.frame.size.width * CGFloat(segControl.selectedSegmentIndex)
        scrollView.setContentOffset(CGPointMake(x, 0), animated: true)
    }
    
    ///上一页
    @IBAction func prePageAction(sender: UIButton) {
        nearbySearchWithPageIndex(curPageIndex - 1)
    }
    ///下一页
    @IBAction func nextPageAction(sender: UIButton) {
        nearbySearchWithPageIndex(curPageIndex + 1)
    }
    
    func nearbySearchWithPageIndex(pageIndex: Int) {
        if pageIndex < 0 {
            return
        }
        let option = BMKRadarNearbySearchOption()
        option.radius = 8000
        option.sortType = BMK_RADAR_SORT_TYPE_DISTANCE_FROM_NEAR_TO_FAR
        option.centerPt = myCoor
        option.pageIndex = pageIndex
        option.pageCapacity = 2
        let res = radarManager.getRadarNearbySearchRequest(option)
        if res {
            print("get 请求成功")
        } else {
            print("get 请求失败")
        }
    }
    
    // MARK: - BMKRadarManagerDelegate
    /**
    *返回雷达 查询周边的用户信息结果
    *@param result 结果，类型为@see BMKRadarNearbyResult
    *@param error 错误号，@see BMKRadarErrorCode
    */
    func onGetRadarNearbySearchResult(result: BMKRadarNearbyResult!, error: BMKRadarErrorCode) {
        print("onGetRadarNearbySearchResult: \(error)")
        if error == BMK_RADAR_NO_ERROR {
            print("result.infoList.count: \(result.infoList.count)")
            updateNearbyInfos(result.infoList as! [BMKRadarNearbyInfo])
            curPageIndex = result.pageIndex
            curPageLabel.text = "\(curPageIndex + 1)"
            nextButton.enabled = (curPageIndex + 1 != result.pageNum)
            preButton.enabled = curPageIndex != 0
        }
    }


    // MARK: - UITableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyInfos.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let CellIdentifier = "BaiduMapRadarDemoCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
        if  cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: CellIdentifier)
        }
        let info = nearbyInfos[indexPath.row]
        cell!.textLabel!.text = info.userId
        cell!.detailTextLabel!.text = "\(info.distance)米   \(info.extInfo)"
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let annotation = _mapView.annotations[indexPath.row] as! BMKAnnotation
        _mapView.centerCoordinate = annotation.coordinate
        _mapView.selectAnnotation(annotation, animated: false)
        segControl.selectedSegmentIndex = 1
        switchResShowAction(segControl)
    }
    
    // MARK: - BMKMapViewDelegate
    /**
    *根据anntation生成对应的View
    *@param mapView 地图View
    *@param annotation 指定的标注
    *@return 生成的标注View
    */
    func mapView(mapView: BMKMapView!, viewForAnnotation annotation: BMKAnnotation!) -> BMKAnnotationView! {
        let AnnotationViewID = "renameMark"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(AnnotationViewID) as! BMKPinAnnotationView?
        if annotationView == nil {
            annotationView = BMKPinAnnotationView(annotation: annotation, reuseIdentifier: AnnotationViewID)
            // 设置颜色
            annotationView!.pinColor = UInt(BMKPinAnnotationColorRed)
            // 从天上掉下的动画
            annotationView!.animatesDrop = true
            // 设置是否可以拖拽
            annotationView!.draggable = false
        }
        annotationView?.annotation = annotation
        return annotationView
    }
    
    // MARK: - 
    ///更新缓存附近信息数据并刷新地图显示
    func updateNearbyInfos(infos: [BMKRadarNearbyInfo]) {
        nearbyInfos.removeAll()
        nearbyInfos.appendContentsOf(infos)
        
        tableView.reloadData()
        _mapView.removeAnnotations(_mapView.annotations)
        
        var annotations = [BMKPointAnnotation]()
        for info in nearbyInfos {
            let annotation = BMKPointAnnotation()
            annotation.coordinate = info.pt
            annotation.title = info.userId
            annotation.subtitle = info.extInfo
            annotations.append(annotation)
        }
        _mapView.addAnnotations(annotations)
        _mapView.showAnnotations(annotations, animated: true)
    }
    
    ///更新我的位置
    func updateMyLocation(notification: NSNotification) {
        if let location = notification.userInfo!["loc"] as? BMKUserLocation {
            myCoor = location.location.coordinate
            _mapView.updateLocationData(location)
        }
    }

}