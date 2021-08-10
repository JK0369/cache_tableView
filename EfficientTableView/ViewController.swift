//
//  ViewController.swift
//  EfficientTableView
//
//  Created by 김종권 on 2021/08/10.
//

import Foundation
import UIKit

class ViewController: UIViewController {

    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)

        return control
    }()

    var dataSource: [AnyObject] = []
    var session: URLSession = URLSession.shared
    lazy var cache: NSCache<AnyObject, UIImage> = NSCache()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GameCell")
    }

    @objc
    func refreshTableView(){

        let url:URL! = URL(string: "https://itunes.apple.com/search?term=flappy&entity=software")
        session.downloadTask(with: url, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in

            if location != nil {
                let data:Data! = try? Data(contentsOf: location!)
                do {
                    let dic = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as AnyObject
                    self.dataSource = dic.value(forKey : "results") as! [AnyObject]
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } catch {
                    print("something went wrong, try again")
                }
            }
        }).resume()
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath)
        let dictionary = self.dataSource[(indexPath as NSIndexPath).row] as! [String:AnyObject]
        cell.textLabel!.text = dictionary["trackName"] as? String
        cell.imageView?.image = #imageLiteral(resourceName: "placeholder")

        if (cache.object(forKey: (indexPath as NSIndexPath).row as AnyObject) != nil) {
            /// 해당 row에 해당되는 부분이 캐시에 존재하는 경우
            cell.imageView?.image = cache.object(forKey: (indexPath as NSIndexPath).row as AnyObject)
        } else {
            /// 해당 row에 해당되는 부분이 캐시에 존재하지 않는 경우
            let artworkUrl = dictionary["artworkUrl100"] as! String
            let url:URL! = URL(string: artworkUrl)
            session.downloadTask(with: url, completionHandler: { (location, response, error) -> Void in
                if let data = try? Data(contentsOf: url){

                    /// 이미지가 성공적으로 다운 > imageView에 넣기 위해 main thread로 전환 (주의: background가 아닌 main thread)
                    DispatchQueue.main.async {
                        /// 해당 셀이 보여지게 될때 imageView에 할당하고 cache에 저장
                        /// 이미지를 업데이트하기전에 화면에 셀이 표시되는지 확인 (확인하지 않을경우, 스크롤하는 동안 이미지가 각 셀에서 불필요하게 재사용)
                        if let updateCell = tableView.cellForRow(at: indexPath) {
                            let img:UIImage! = UIImage(data: data)
                            updateCell.imageView?.image = img
                            self.cache.setObject(img, forKey: (indexPath as NSIndexPath).row as AnyObject)
                        }
                    }

                }
            }).resume()
        }
        return cell
    }
}
