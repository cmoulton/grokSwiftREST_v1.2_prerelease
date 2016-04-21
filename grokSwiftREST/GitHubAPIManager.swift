//
//  GitHubAPIManager.swift
//  grokSwiftREST
//
//  Created by Christina Moulton on 2016-04-02.
//  Copyright © 2016 Teak Mobile Inc. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Locksmith

class GitHubAPIManager {
  static let sharedInstance = GitHubAPIManager()
  let clientID: String = "1234567890"
  let clientSecret: String = "abcdefghijkl"
  var isLoadingOAuthToken: Bool = false
  
  static let ErrorDomain = "com.error.GitHubAPIManager"
  
  // handler for the OAuth process
  // stored as vars since sometimes it requires a round trip to safari which
  // makes it hard to just keep a reference to it
  var OAuthTokenCompletionHandler:(NSError? -> Void)?
  
  var OAuthToken: String? {
    set {
      if let valueToSave = newValue {
        do {
          try Locksmith.updateData(["token": valueToSave], forUserAccount: "github")
        } catch {
          let _ = try? Locksmith.deleteDataForUserAccount("github")
        }
      } else { // they set it to nil, so delete it
        let _ = try? Locksmith.deleteDataForUserAccount("github")
      }
    }
    get {
      // try to load from keychain
      Locksmith.loadDataForUserAccount("github")
      let dictionary = Locksmith.loadDataForUserAccount("github")
      return dictionary?["token"] as? String
    }
  }
  
  func printPublicGists() -> Void {
    Alamofire.request(GistRouter.GetPublic())
      .responseString { response in
        if let receivedString = response.result.value {
          print(receivedString)
        }
    }
  }
  
  func printMyStarredGistsWithBasicAuth() -> Void {
    Alamofire.request(GistRouter.GetMyStarred())
      .responseString { response in
        guard let receivedString = response.result.value else {
          print("didn't get a string in the response")
          return
        }
        print(receivedString)
    }
  }
  
  func hasOAuthToken() -> Bool {
    if let token = self.OAuthToken {
      return !token.isEmpty
    }
    return false
  }
  
  // MARK: - OAuth flow
  
  func URLToStartOAuth2Login() -> NSURL? {
    let authPath:String = "https://github.com/login/oauth/authorize" +
      "?client_id=\(clientID)&scope=gist&state=TEST_STATE"
    guard let authURL:NSURL = NSURL(string: authPath) else {
      // TODO: handle error
      return nil
    }
    
    return authURL
  }
  
  func extractCodeFromOAuthStep1Response(url: NSURL) -> String? {
    let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
    var code:String?
    guard let queryItems = components?.queryItems else {
      return nil
    }
    for queryItem in queryItems {
      if (queryItem.name.lowercaseString == "code") {
        code = queryItem.value
        break
      }
    }
    return code
  }
  
  func parseOAuthTokenResponse(json: JSON) -> String? {
    var token: String?
    for (key, value) in json {
      switch key {
      case "access_token":
        token = value.string
      case "scope":
        // TODO: verify scope
        print("SET SCOPE")
      case "token_type":
        // TODO: verify is bearer
        print("CHECK IF BEARER")
      default:
        print("got more than I expected from the OAuth token exchange")
        print(key)
      }
    }
    return token
  }
  
  func swapAuthCodeForToken(code: String) {
    let getTokenPath:String = "https://github.com/login/oauth/access_token"
    let tokenParams = ["client_id": clientID,
                       "client_secret": clientSecret,
                       "code": code]
    let jsonHeader = ["Accept": "application/json"]
    Alamofire.request(.POST, getTokenPath, parameters: tokenParams,
      headers: jsonHeader)
      .responseString { response in
        guard response.result.error == nil,
          let receivedResults = response.result.value else {
            print(response.result.error!)
            if let completionHandler = self.OAuthTokenCompletionHandler {
              let error = NSError(domain: GitHubAPIManager.ErrorDomain, code: -1,
                userInfo: [NSLocalizedDescriptionKey:
                  "Could not obtain an OAuth token",
                  NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
              completionHandler(error)
            }
            self.isLoadingOAuthToken = false
            return
        }
        
        // extract the token from the response
        guard let jsonData = receivedResults.dataUsingEncoding(NSUTF8StringEncoding,
          allowLossyConversion: false) else {
            print("no data received or data not JSON")
            if let completionHandler = self.OAuthTokenCompletionHandler {
              let error = NSError(domain: GitHubAPIManager.ErrorDomain, code: -1,
                userInfo: [NSLocalizedDescriptionKey:
                  "Could not obtain an OAuth token",
                  NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
              completionHandler(error)
            }
            self.isLoadingOAuthToken = false
            return
        }
        let jsonResults = JSON(data: jsonData)
        self.OAuthToken = self.parseOAuthTokenResponse(jsonResults)
        self.isLoadingOAuthToken = false
        
        if let completionHandler = self.OAuthTokenCompletionHandler {
          if (self.hasOAuthToken()) {
            completionHandler(nil)
          } else  {
            let noOAuthError = NSError(domain: GitHubAPIManager.ErrorDomain,
              code: -1, userInfo:
              [NSLocalizedDescriptionKey: "Could not obtain an OAuth token",
                NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
            completionHandler(noOAuthError)
          }
        }
    }
  }
  
  func processOAuthStep1Response(url: NSURL) {
    // extract the code from the URL
    guard let code = extractCodeFromOAuthStep1Response(url) else {
      self.isLoadingOAuthToken = false
      if let completionHandler = self.OAuthTokenCompletionHandler {
        let error = NSError(domain: GitHubAPIManager.ErrorDomain, code: -1,
                            userInfo: [NSLocalizedDescriptionKey:
                              "Could not obtain an OAuth code",
                              NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
        completionHandler(error)
      }
      return
    }
    
    swapAuthCodeForToken(code)
  }
  
  // MARK: - OAuth 2.0
  func printMyStarredGistsWithOAuth2() -> Void {
    let alamofireRequest = Alamofire.request(GistRouter.GetMyStarred())
      .responseString { response in
        guard let receivedString = response.result.value else {
          print(response.result.error!)
          self.OAuthToken = nil
          return
        }
        print(receivedString)
    }
    debugPrint(alamofireRequest)
  }
  
  // MARK: API Calls
  
  func fetchGists(urlRequest: URLRequestConvertible, completionHandler:
    (Result<[Gist], NSError>, String?) -> Void) {
    Alamofire.request(urlRequest)
      .responseArray { (response:Response<[Gist], NSError>) in
        // need to figure out if this is the last page
        // check the link header, if present
        let next = self.parseNextPageFromHeaders(response.response)
        completionHandler(response.result, next)
    }
  }
  
  func fetchPublicGists(pageToLoad: String?, completionHandler:
    (Result<[Gist], NSError>, String?) -> Void) {
    if let urlString = pageToLoad {
      fetchGists(GistRouter.GetAtPath(urlString), completionHandler: completionHandler)
    } else {
      fetchGists(GistRouter.GetPublic(), completionHandler: completionHandler)
    }
  }
  
  func fetchMyStarredGists(pageToLoad: String?, completionHandler:
    (Result<[Gist], NSError>, String?) -> Void) {
    if let urlString = pageToLoad {
      fetchGists(GistRouter.GetAtPath(urlString), completionHandler: completionHandler)
    } else {
      fetchGists(GistRouter.GetMyStarred(), completionHandler: completionHandler)
    }
  }
  
  func imageFromURLString(imageURLString: String, completionHandler:
    (UIImage?, NSError?) -> Void) {
    Alamofire.request(.GET, imageURLString)
      .response { (request, response, data, error) in
        // use the generic response serializer that returns NSData
        guard let data = data else {
          completionHandler(nil, nil)
          return
        }
        
        let image = UIImage(data: data as NSData)
        completionHandler(image, nil)
    }
  }
  
  // MARK: Pagination
  private func parseNextPageFromHeaders(response: NSHTTPURLResponse?) -> String? {
    guard let linkHeader = response?.allHeaderFields["Link"] as? String else {
      return nil
    }
    /* looks like:
     <https://api.github.com/user/20267/gists?page=2>; rel="next", <https://api.github.com/user/20267/gists?page=6>; rel="last"
     */
    // so split on ","
    let components = linkHeader.characters.split {$0 == ","}.map { String($0) }
    // now we have 2 lines like
    // '<https://api.github.com/user/20267/gists?page=2>; rel="next"'
    // So let's get the URL out of there:
    for item in components {
      // see if it's "next"
      let rangeOfNext = item.rangeOfString("rel=\"next\"", options: [])
      guard rangeOfNext != nil else {
        continue
      }
      // this is the "next" item
      // extract the URL
      let rangeOfPaddedURL = item.rangeOfString("<(.*)>;",
                                                options: .RegularExpressionSearch)
      guard let range = rangeOfPaddedURL else {
        return nil
      }
      let nextURL = item.substringWithRange(range)
      
      // strip off the < and >;
      let startIndex = nextURL.startIndex.advancedBy(1)
      let endIndex = nextURL.endIndex.advancedBy(-2)
      let urlRange = startIndex..<endIndex
      return nextURL.substringWithRange(urlRange)
    }
    return nil
  }
}
