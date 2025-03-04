//
//  GrowthBookInstance.swift
//  GrowthBook-IOS
//
//  Created by Vitalii Budnik on 2/28/25.
//

import Foundation

public struct GrowthBookInstance: Sendable, Equatable {
    public var apiHostURL: URL
    public var clientKey: String
    public var payloadType: PayloadType
    public var refreshPolicy: RefreshPolicy
}

extension GrowthBookInstance {
    var featuresURL: URL {
        apiHostURL
            .appendingPathComponent("api", isDirectory: true)
            .appendingPathComponent("features", isDirectory: true)
            .appendingPathComponent(clientKey, isDirectory: false)
    }

    var remoteEvalURL: URL {
        apiHostURL
            .appendingPathComponent("api", isDirectory: true)
            .appendingPathComponent("eval", isDirectory: true)
            .appendingPathComponent(clientKey, isDirectory: false)
    }

    var serverSideEventsURL: URL {
        apiHostURL
            .appendingPathComponent("sub", isDirectory: true)
            .appendingPathComponent(clientKey, isDirectory: false)
    }
}
