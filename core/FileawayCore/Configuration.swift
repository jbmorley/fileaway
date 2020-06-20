//
//  Configuration.swift
//  FileawayCore
//
//  Created by Jason Barrie Morley on 14/09/2018.
//  Copyright © 2018 InSeven Limited. All rights reserved.
//

import Foundation

public struct Configuration: Codable {
    public let variables: [Variable]
    public let destination: [Component]
    public init(variables: [Variable], destination: [Component]) {
        self.variables = variables
        self.destination = destination
    }
}

public enum ComponentType: String, Codable {
    case text = "text"
    case variable = "variable"
}

public struct Component: Codable {
    public let type: ComponentType
    public let value: String

    public init(type: ComponentType, value: String) {
        self.type = type
        self.value = value
    }
}

public enum VariableType: CaseIterable {

    case string
    case date(hasDay: Bool)

    public static var allCases: [VariableType] {
        return [.string, .date(hasDay: true), .date(hasDay: false)]
    }
}

public struct Variable {
    public let name: String
    public let type: VariableType

    public init(name: String, type: VariableType) {
        self.name = name
        self.type = type
    }
}

extension Variable: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case dateParams
    }

    enum RawType: String, Codable {
        case string
        case date
    }

    struct DateParams: Codable {
        let hasDay: Bool

        init(hasDay: Bool = true) {
            self.hasDay = hasDay
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)

        switch type {
        case .string:
            try container.encode(RawType.string, forKey: .type)
        case .date(let hasDay):
            try container.encode(RawType.date, forKey: .type)
            try container.encode(DateParams(hasDay: hasDay), forKey: .dateParams)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let name = try container.decode(String.self, forKey: .name)
        let type = try container.decode(RawType.self, forKey: .type)

        switch type {
        case .string:
            self = Variable(name: name, type: .string)
        case .date:
            let dateParams = try container.decodeIfPresent(DateParams.self, forKey: .dateParams)
                ?? DateParams()
            self = Variable(name: name, type: .date(hasDay: dateParams.hasDay))
        }
    }
}

public struct Task {
    public let name: String
    public let configuration: Configuration
    public init(name: String, configuration: Configuration) {
        self.name = name
        self.configuration = configuration
    }
}