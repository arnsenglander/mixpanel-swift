//
//  DecideRequest.swift
//  Mixpanel
//
//  Created by Yarden Eitan on 8/5/16.
//  Copyright © 2016 Mixpanel. All rights reserved.
//

import Foundation

class DecideRequest: Network {

    typealias DecideResult = [String: AnyObject]
    let decidePath = "/decide"
    var networkRequestsAllowedAfterTime = 0.0
    var networkConsecutiveFailures = 0

    struct DecideQueryItems {
        let version: URLQueryItem
        let lib: URLQueryItem
        let token: URLQueryItem
        let distinctId: URLQueryItem
        let properties: URLQueryItem

        init(distinctId: String, token: String) {
            self.version = URLQueryItem(name: "version", value: "1")
            self.lib = URLQueryItem(name: "lib", value: "iphone")
            self.token = URLQueryItem(name: "token", value: token)
            self.distinctId = URLQueryItem(name: "distinct_id", value: distinctId)

            let propertiesData = try! JSONSerialization.data(withJSONObject: AutomaticProperties.peopleProperties)
            let propertiesString = String(data: propertiesData, encoding: String.Encoding.utf8)
            self.properties = URLQueryItem(name: "properties", value: propertiesString)
        }

        func toArray() -> [URLQueryItem] {
            return [version, lib, token, distinctId, properties]
        }
    }

    func sendRequest(distinctId: String,
                     token: String,
                     completion: (DecideResult?) -> Void) {

        let responseParser: (Data) -> DecideResult? = { data in
            var response: AnyObject? = nil
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                Logger.warn(message: "exception decoding api data")
            }
            return response as? DecideResult
        }

        let queryItems = DecideQueryItems(distinctId: distinctId, token: token)
        let resource = Network.buildResource(path: decidePath,
                                             method: Method.GET,
                                             queryItems: queryItems.toArray(),
                                             headers: ["Accept-Encoding": "gzip"],
                                             parse: responseParser)

        decideRequestHandler(BasePath.MixpanelAPI,
                             resource: resource,
                             completion: { result in
                                completion(result)
        })
    }

    private func decideRequestHandler(_ base: String,
                                      resource: Resource<DecideResult>,
                                      completion: (DecideResult?) -> Void) {
        Network.apiRequest(base: base, resource: resource,
            failure: { (reason, data, response) in
                Logger.warn(message: "API request to \(resource.path) has failed with reason \(reason)")
                completion(nil)
            }, success: { (result, response) in
                completion(result)
            })
    }

}
