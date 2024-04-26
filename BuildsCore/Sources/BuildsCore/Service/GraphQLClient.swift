// Copyright (c) 2022-2024 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

public protocol PropertyType: Queryable {
    associatedtype UnderlyingType
}

public protocol Queryable: Identifiable {

    associatedtype Response: Decodable

    var id: UUID { get }

    func query() -> String
    func decodeResponse(_ data: Data) throws -> Response
    func decode(from decoder: any Decoder) throws -> Response  // TODO: This is perhaps how we drop the decodable requirement on response?
    func decode(from container: KeyedDecodingContainer<UnknownCodingKeys>) throws -> Response
}

// Is this a property or a field and does it have an alias?
public struct Property<Datatype: Decodable>: PropertyType {

    public typealias Response = Datatype
    public typealias UnderlyingType = Datatype

    public let id = UUID()

    let name: String
    let alias: String?

    public init(_ name: String, alias: String? = nil) {
        self.name = name
        self.alias = alias
    }

    // TODO: This needs to actually include the query of the type itself.
    public func query() -> String {
        if let alias {
            return "\(alias): \(name)"
        }
        return name
    }

    // TODO: Remove this!
    public func decodeResponse(_ data: Data) throws -> Datatype {
        try JSONDecoder().decode(Datatype.self, from: data)
    }

    // This is how we get away with named and unnamed.
    public func decode(from decoder: any Decoder) throws -> Datatype {
        let container = try decoder.container(keyedBy: UnknownCodingKeys.self)
        return try decode(from: container)
    }

    public func decode(from container: KeyedDecodingContainer<UnknownCodingKeys>) throws -> Datatype {
        return try container.decode(Response.self, forKey: UnknownCodingKeys(stringValue: name)!)
    }

}

extension Queryable {
    static func decodeResponse(_ data: Data) throws -> Response {
        try JSONDecoder().decode(Response.self, from: data)
    }
}

@resultBuilder
public struct QueryBuilder {

    public static func buildBlock(_ components: [any Queryable]...) -> [any Queryable] {
        components.flatMap { $0 }
    }

    /// Add support for both single and collections of constraints.
    public static func buildExpression(_ expression: any Queryable) -> [any Queryable] {
        [expression]
    }

    public static func buildExpression(_ expression: [any Queryable]) -> [any Queryable] {
        expression
    }
}

extension CodingUserInfoKey {
   static let fields = CodingUserInfoKey(rawValue: "fields")!
}

public struct QueryResultContainer: Decodable {

    let results: [UUID: Any]

    public init(from decoder: any Decoder) throws {
        let fields = decoder.userInfo[.fields] as! [any Queryable]  // TODO: Don't crash!
        var results: [UUID: Any] = [:]
        for field in fields {
            results[field.id] = try field.decode(from: decoder)
        }
        self.results = results
    }

    init(from decoder: any Decoder, fields: [any Queryable]) throws {
        var results: [UUID: Any] = [:]
        for field in fields {
            results[field.id] = try field.decode(from: decoder)
        }
        self.results = results
    }

    init(from container: KeyedDecodingContainer<UnknownCodingKeys>, fields: [any Queryable]) throws {
        var results: [UUID: Any] = [:]
        for field in fields {
            results[field.id] = try field.decode(from: container)
        }
        self.results = results
    }

    public subscript<T: Queryable>(key: T) -> T.Response {
        get {
            return results[key.id] as! T.Response
        }
    }

    // TODO: Init with container

}


// TODO: Queryable as a protocol?
// TODO: Query is a named field?
public struct Query: Queryable {

    public let id = UUID()

    public typealias Response = QueryResultContainer

    struct DataContainer: Decodable {
        let data: QueryResultContainer
    }

    let fields: [any Queryable]

    public init(@QueryBuilder fields: () -> [any Queryable]) {
        self.fields = fields()
    }

    public func query() -> String {
        return (["query {"] + fields.map { $0.query() } + ["}"])
            .joined(separator: "\n")
    }

    public func decodeResponse(_ data: Data) throws -> Response {
        let decoder = JSONDecoder()
        decoder.userInfo = [.fields: fields]  // TODO: Is this only suported at the top level?
        return try decoder.decode(DataContainer.self, from: data).data
    }

    public func decode(from decoder: any Decoder) throws -> Response {
        // Once we get here we cannot inject anything into the decoder, ooooh but we can inject it ourselves.
        // TODO: This is only going to work if the decoder is set up correctly with our fields.
        // TODO: 'data'
        return try QueryResultContainer(from: decoder, fields: fields)
    }

    public func decode(from container: KeyedDecodingContainer<UnknownCodingKeys>) throws -> QueryResultContainer {
        let inner = try container.nestedContainer(keyedBy: UnknownCodingKeys.self, forKey: UnknownCodingKeys(stringValue: "data")!)
        return try QueryResultContainer(from: inner, fields: fields)
    }

}

// TODO: How do nested queries work?

public struct Field: Queryable {

    public let id = UUID()

    public typealias Response = QueryResultContainer

    let name: String
    let alias: String?

    let fields: [any Queryable]

    public init(_ name: String, alias: String? = nil, @QueryBuilder fields: () -> [any Queryable]) {
        self.name = name
        self.alias = alias
        self.fields = fields()
    }

    // TODO: Could push this down to a common way of structuring the member data?
    public func query() -> String {
        return (["\(name) {"] + fields.map { $0.query() } + ["}"])
            .joined(separator: "\n")
    }

    public func decodeResponse(_ data: Data) throws -> Response {
        let decoder = JSONDecoder()
        decoder.userInfo = [.fields: fields]  // TODO: Is this only suported at the top level?
        return try decoder.decode(Response.self, from: data)
    }

    public func decode(from decoder: any Decoder) throws -> Response {
        // First thing we need to do here is strip away our name. Really we're just a property and it might be
        // nice to implement us as such. But not today.
        let container = try decoder.container(keyedBy: UnknownCodingKeys.self)
        // TODO: Support ALIASES!
        let inner = try container.nestedContainer(keyedBy: UnknownCodingKeys.self, forKey: UnknownCodingKeys(stringValue: name)!)


        // Once we get here we cannot inject anything into the decoder, ooooh but we can inject it ourselves.
        // TODO: This is only going to work if the decoder is set up correctly with our fields.
        return try QueryResultContainer(from: inner, fields: fields)
    }

    public func decode(from container: KeyedDecodingContainer<UnknownCodingKeys>) throws -> QueryResultContainer {
        let inner = try container.nestedContainer(keyedBy: UnknownCodingKeys.self, forKey: UnknownCodingKeys(stringValue: name)!)
        return try QueryResultContainer(from: inner, fields: fields)
    }

}

public struct GraphQLClient {

    struct Query: Codable {
        let query: String
    }

    let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func query<T: Queryable>(_ query: T, accessToken: String) async throws -> T.Response {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(Query(query: query.query()))

        let (data, response) = try await URLSession.shared.data(for: request)
        try response.checkHTTPStatusCode()
        do {
            return try query.decodeResponse(data) // <-- I think this is only used at this level? Unpack here?
        } catch {
            print(String(data: data, encoding: .utf8) ?? "nil")
            throw error
        }

    }

}
