//
//  BusLineSearchViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/6.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

class BusLineSearchViewController: UIViewController, BMKMapViewDelegate, BMKBusLineSearchDelegate, BMKPoiSearchDelegate, UITextFieldDelegate  {
    
    @IBOutlet weak var _mapView: BMKMapView!
    @IBOutlet weak var cityField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    
    var buslineSearch: BMKBusLineSearch!
    var poiSearch: BMKPoiSearch!
    
    var poiUidArray: [String]!
    var currentIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buslineSearch = BMKBusLineSearch()
        poiSearch = BMKPoiSearch()
        
        poiUidArray = [String]()
        
        cityField.text = "北京"
        nameField.text = "717"
        cityField.delegate = self
        nameField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _mapView.viewWillAppear()
        _mapView.delegate = self
        buslineSearch.delegate = self
        poiSearch.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        _mapView.viewWillDisappear()
        _mapView.delegate = nil
        buslineSearch.delegate = nil
        poiSearch.delegate = nil
    }
    
    // MARK: - IBAction
    
    @IBAction func buslineSearch(sender: AnyObject) {
        poiUidArray.removeAll(keepCapacity: false)
        citySearch()
    }
    
    @IBAction func buslineSearchNext(sender: AnyObject) {
        if poiUidArray.count > 0 {
            if ++currentIndex >= poiUidArray.count {
                currentIndex -= poiUidArray.count
            }
            bslSearch()
        }else {
            citySearch()
        }
    }
    
    func citySearch() {
        let citySearchOption = BMKCitySearchOption()
        citySearchOption.pageIndex = 0
        citySearchOption.pageCapacity = 10
        citySearchOption.city = cityField.text
        citySearchOption.keyword = nameField.text
        
        let flag = poiSearch.poiSearchInCity(citySearchOption)
        if flag {
            print("城市内检索发送成功")
        }else {
            print("城市内检索发送失败")
        }
    }
    
    func bslSearch() {
        let busLineUid = poiUidArray[currentIndex] as String
        let buslineSearchOption = BMKBusLineSearchOption()
        buslineSearchOption.city = cityField.text
        buslineSearchOption.busLineUid = busLineUid
        
        let flag = buslineSearch.busLineSearch(buslineSearchOption)
        if flag {
            print("公交线路检索发送成功")
        }else {
            print("公交线路检索发送失败")
        }

    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        cityField.resignFirstResponder()
        nameField.resignFirstResponder()
        return true
    }
    
    // MARK: - BMKPoiSearchDelegate

    /**
    *返回POI搜索结果
    *@param searcher 搜索对象
    *@param poiResult 搜索结果列表
    *@param errorCode 错误号，@see BMKSearchErrorCode
    */
    func onGetPoiResult(searcher: BMKPoiSearch!, result poiResult: BMKPoiResult!, errorCode: BMKSearchErrorCode) {
        print("onGetPoiResult code: \(errorCode)");
        
        if errorCode == BMK_SEARCH_NO_ERROR {
            var findBusline = false
            for i in 0..<poiResult.poiInfoList.count {
                let poi = poiResult.poiInfoList[i] as? BMKPoiInfo
                if poi?.epoitype == 2 || poi?.epoitype == 4 {
                    if let poiUid = poi?.uid {
                        findBusline = true
                        poiUidArray.append(poiUid)
                    }
                }
            }
            // 开始 busline 详情搜索
            if findBusline {
                currentIndex = 0
                bslSearch()
            }
        }
    }

    // MARK: - BMKBusLineSearchDelegate
    
    /**
    *返回busdetail搜索结果
    *@param searcher 搜索对象
    *@param busLineResult 搜索结果
    *@param error 错误号，@see BMKSearchErrorCode
    */
    func onGetBusDetailResult(searcher: BMKBusLineSearch!, result busLineResult: BMKBusLineResult!, errorCode error: BMKSearchErrorCode) {
        print("onGetBusDetailResult: \(error)")
        
        _mapView.removeAnnotations(_mapView.annotations)
        _mapView.removeOverlays(_mapView.overlays)
        
        if error == BMK_SEARCH_NO_ERROR {
            var item = RouteAnnotation()
            
            // 站点信息
            let size = busLineResult.busStations.count
            for i in 0..<size {
                let station = busLineResult.busStations[i] as! BMKBusStation
                item = RouteAnnotation()
                item.coordinate = station.location
                item.title = station.title
                item.type = 2
                _mapView.addAnnotation(item)
            }
            
            // 路段信息
            var index = 0
            for i in 0..<busLineResult.busSteps.count {
                let step = busLineResult.busSteps[i] as! BMKBusStep
                index += Int(step.pointsCount)
            }
            
            // 直角坐标划线
            var tempPoints = Array(count: index, repeatedValue: BMKMapPoint(x: 0, y: 0))
            var k = 0
            for i in 0..<busLineResult.busSteps.count {
                let step = busLineResult.busSteps[i] as! BMKBusStep
                for j in 0..<step.pointsCount {
                    let point = BMKMapPoint(x: step.points[Int(j)].x, y: step.points[Int(j)].y)
                    tempPoints[k] = point
                    k++
                }
            }
            
            let polyLine = BMKPolyline(points: &tempPoints, count: UInt(index))
            _mapView.addOverlay(polyLine)
            
            mapViewFitPolyLine(polyLine)
        }
    }
    
    // MARK: - BMKMapViewDelegate
    
    /**
    *根据anntation生成对应的View
    *@param mapView 地图View
    *@param annotation 指定的标注
    *@return 生成的标注View
    */
    func mapView(mapView: BMKMapView!, viewForAnnotation annotation: BMKAnnotation!) -> BMKAnnotationView! {
        if let routeAnnotation = annotation as! RouteAnnotation? {
            return getViewForRouteAnnotation(routeAnnotation)
        }
        return nil
    }
    
    /**
     *根据overlay生成对应的View
     *@param mapView 地图View
     *@param overlay 指定的overlay
     *@return 生成的覆盖物View
     */
    func mapView(mapView: BMKMapView!, viewForOverlay overlay: BMKOverlay!) -> BMKOverlayView! {
        if overlay as! BMKPolyline? != nil {
            let polylineView = BMKPolylineView(overlay: overlay as! BMKPolyline)
            polylineView.strokeColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.7)
            polylineView.lineWidth = 3
            return polylineView
        }
        return nil
    }
    
    // MARK: -
    
    func getViewForRouteAnnotation(routeAnnotation: RouteAnnotation!) -> BMKAnnotationView? {
        var view: BMKAnnotationView?
        
        var imageName: String?
        switch routeAnnotation.type {
        case 0:
            imageName = "nav_start"
        case 1:
            imageName = "nav_end"
        case 2:
            imageName = "nav_bus"
        case 3:
            imageName = "nav_rail"
        case 4:
            imageName = "direction"
        case 5:
            imageName = "nav_waypoint"
        default:
            return nil
        }
        let identifier = "\(imageName)_annotation"
        view = _mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if view == nil {
            view = BMKAnnotationView(annotation: routeAnnotation, reuseIdentifier: identifier)
            view?.centerOffset = CGPointMake(0, -(view!.frame.size.height * 0.5))
            view?.canShowCallout = true
        }
        
        view?.annotation = routeAnnotation
        
        let bundlePath = NSBundle.mainBundle().resourcePath?.stringByAppendingString("/mapapi.bundle/")
        let bundle = NSBundle(path: bundlePath!)
        if let imagePath = bundle?.resourcePath?.stringByAppendingString("/images/icon_\(imageName!).png") {
            var image = UIImage(contentsOfFile: imagePath)
            if routeAnnotation.type == 4 {
                image = imageRotated(image, degrees: routeAnnotation.degree)
            }
            if image != nil {
                view?.image = image
            }
        }
        
        return view
    }
    
    
    //根据polyline设置地图范围
    func mapViewFitPolyLine(polyline: BMKPolyline!) {
        if polyline.pointCount < 1 {
            return
        }
        
        let pt = polyline.points[0]
        var ltX = pt.x
        var rbX = pt.x
        var ltY = pt.y
        var rbY = pt.y
        
        for i in 1..<polyline.pointCount {
            let pt = polyline.points[Int(i)]
            if pt.x < ltX {
                ltX = pt.x
            }
            if pt.x > rbX {
                rbX = pt.x
            }
            if pt.y > ltY {
                ltY = pt.y
            }
            if pt.y < rbY {
                rbY = pt.y
            }
        }
        
        let rect = BMKMapRectMake(ltX, ltY, rbX - ltX, rbY - ltY)
        _mapView.visibleMapRect = rect
        _mapView.zoomLevel = _mapView.zoomLevel - 0.3
    }
    
    //旋转图片
    func imageRotated(image: UIImage!, degrees: Int!) -> UIImage {
        let width = CGImageGetWidth(image.CGImage)
        let height = CGImageGetHeight(image.CGImage)
        let rotatedSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(rotatedSize);
        let bitmap = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
        CGContextRotateCTM(bitmap, CGFloat(Double(degrees) * M_PI / 180.0));
        CGContextRotateCTM(bitmap, CGFloat(M_PI));
        CGContextScaleCTM(bitmap, -1.0, 1.0);
        CGContextDrawImage(bitmap, CGRectMake(-rotatedSize.width/2, -rotatedSize.height/2, rotatedSize.width, rotatedSize.height), image.CGImage);
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }

}
