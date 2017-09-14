//
//  ClusterDemoViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/9.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

/*
*点聚合Annotation
*/
class ClusterAnnotation : BMKPointAnnotation {
    var size: UInt = 0
}

/*
*点聚合AnnotationView
*/
class ClusterAnnotationView : BMKPinAnnotationView {
    var label: UILabel?
    
    override init(annotation: BMKAnnotation!, reuseIdentifier: String!) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.bounds = CGRectMake(0, 0, 22, 22)
        label = UILabel(frame: CGRectMake(0, 0, 22, 22))
        label?.textColor = UIColor.whiteColor()
        label?.font = UIFont.systemFontOfSize(11)
        label?.textAlignment = NSTextAlignment.Center
        self.addSubview(label!)
        self.alpha = 0.85;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func setSize(size :UInt) {
        if size == 1 {
            label?.hidden = true
            self.pinColor = UInt(BMKPinAnnotationColorRed)
            return;
        }
        label?.hidden = false
        if size > 20 {
            label?.backgroundColor = UIColor.redColor()
        } else if size > 10 {
            label?.backgroundColor = UIColor.purpleColor()
        } else if size > 5 {
            label?.backgroundColor = UIColor.blueColor()
        } else {
            label?.backgroundColor = UIColor.greenColor()
        }
        label?.text = "\(size)"
    }

}


class ClusterDemoViewController: UIViewController, BMKMapViewDelegate  {
    
    @IBOutlet weak var _mapView: BMKMapView!
    
    //点聚合管理类
    var _clusterManager: BMKClusterManager!
    //聚合级别
    var _clusterZoom: Int! = 0
    //点聚合缓存标注
    var _clusterCaches = Array(count: 19, repeatedValue: [ClusterAnnotation]())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
         //点聚合管理类
        _clusterManager = BMKClusterManager()
        let coor = CLLocationCoordinate2DMake(39.915, 116.404)
        //向点聚合管理类中添加标注
        for _ in 0..<20 {
            let lat = Double(arc4random() % 100) / 1000.0
            let lon = Double(arc4random() % 100) / 1000.0
            let clusterItem = BMKClusterItem()
            clusterItem.coor = CLLocationCoordinate2DMake(coor.latitude + lat, coor.longitude + lon)
            _clusterManager.addClusterItem(clusterItem)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _mapView.viewWillAppear()
        _mapView.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        _mapView.viewWillDisappear()
        _mapView.delegate = nil
    }

    // MARK: - 
    //更新聚合状态
    func updateClusters() {
        _clusterZoom = Int(_mapView.zoomLevel)
        var clusters = _clusterCaches[_clusterZoom - 3]
        if clusters.count > 0 {
            _mapView.removeAnnotations(_mapView.annotations)
            _mapView.addAnnotations(clusters)
        } else {
            dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
                ///获取聚合后的标注
                if let array = self._clusterManager.getClusters(Float(self._clusterZoom)) as? [BMKCluster] {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        for item in array {
                            let annotation = ClusterAnnotation()
                            annotation.coordinate = item.coordinate
                            annotation.size = item.size
                            annotation.title = "我是\(item.size)个"
                            clusters.append(annotation)
                        }
                        self._mapView.removeAnnotations(self._mapView.annotations)
                        self._mapView.addAnnotations(clusters)
                    })
                }
            })
        }
    }
    
    // MARK: - BMKMapViewDelegate
    
    // 根据anntation生成对应的View
    func mapView(mapView: BMKMapView!, viewForAnnotation annotation: BMKAnnotation!) -> BMKAnnotationView! {
        if let cluster = annotation as? ClusterAnnotation {
            let annotationView = ClusterAnnotationView(annotation: cluster, reuseIdentifier: "clustermark")
            annotationView.setSize(cluster.size)
            annotationView.annotation = cluster
            return annotationView
        }
        return nil
    }
   
    
    /**
    *当点击annotation view弹出的泡泡时，调用此接口
    *@param mapView 地图View
    *@param view 泡泡所属的annotation view
    */
    func mapView(mapView: BMKMapView!, annotationViewForBubble view: BMKAnnotationView!) {
        if view is ClusterAnnotationView {
            if let cluster = view.annotation as? ClusterAnnotation {
                if cluster.size > 1 {
                    _mapView.centerCoordinate = cluster.coordinate
                    _mapView.zoomIn()
                }
            }
        }
    }
    
    /**
    *地图初始化完毕时会调用此接口
    *@param mapview 地图View
    */
    func mapViewDidFinishLoading(mapView: BMKMapView!) {
        updateClusters()
    }
    
    /**
    *地图渲染每一帧画面过程中，以及每次需要重绘地图时（例如添加覆盖物）都会调用此接口
    *@param mapview 地图View
    *@param status 此时地图的状态
    */
    func mapView(mapView: BMKMapView!, onDrawMapFrame status: BMKMapStatus!) {
        if (_clusterZoom != 0 && _clusterZoom != Int(mapView.zoomLevel)) {
            updateClusters()
        }
    }

}