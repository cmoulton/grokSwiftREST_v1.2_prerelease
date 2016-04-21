//
//  DetailViewController.swift
//  grokSwiftREST
//
//  Created by Christina Moulton on 2016-04-02.
//  Copyright © 2016 Teak Mobile Inc. All rights reserved.
//

import UIKit
import SafariServices

class DetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet weak var tableView: UITableView!
  var isStarred: Bool?
  
  var gist: Gist? {
    didSet {
      // Update the view.
      self.configureView()
    }
  }
  
  func configureView() {
    fetchStarredStatus()
    if let detailsView = self.tableView {
      detailsView.reloadData()
    }
  }
  
  func fetchStarredStatus() {
    guard let gistId = gist?.id else {
      return
    }
    GitHubAPIManager.sharedInstance.isGistStarred(gistId) {
      result in
      guard result.error == nil else {
        print(result.error)
        return
      }
      if let status = result.value where self.isStarred == nil { // just got it
        self.isStarred = status
        self.tableView?.insertRowsAtIndexPaths(
          [NSIndexPath(forRow: 2, inSection: 0)],
          withRowAnimation: .Automatic)
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    self.configureView()
  }
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 2
  }
  
  func tableView(tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      if let _ = isStarred {
        return 3
      }
      return 2
    } else {
      return gist?.files?.count ?? 0
    }
  }
  
  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      return "About"
    } else {
      return "Files"
    }
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath
    indexPath: NSIndexPath)
    -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        cell.textLabel?.text = gist?.description
      } else if indexPath.row == 1 {
        cell.textLabel?.text = gist?.ownerLogin
      } else {
        if let starred = isStarred {
          if starred {
            cell.textLabel?.text = "Unstar"
          } else {
            cell.textLabel?.text = "Star"
          }
        }
      }
    } else {
      if let file = gist?.files?[indexPath.row] {
        cell.textLabel?.text = file.filename
      }
    }
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.section == 1 {
      guard let file = gist?.files?[indexPath.row],
        urlString = file.raw_url,
        url = NSURL(string: urlString) else {
          return
      }
      let safariViewController = SFSafariViewController(URL: url)
      safariViewController.title = file.filename
      self.navigationController?.pushViewController(safariViewController, animated: true)
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}
