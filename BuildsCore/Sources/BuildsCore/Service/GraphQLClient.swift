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

    public static func buildExpression(_ expression: any Queryable) -> [any Queryable] {
        [expression]
    }

    public static func buildExpression(_ expression: [any Queryable]) -> [any Queryable] {
        expression
    }
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

    // TODO: Did we loose some important type-safety in the top-level result?
    public func query<T: IdentifiableSelection>(_ query: T, accessToken: String) async throws -> T.Datatype {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(Query(query: query.query()!))  // TODO: !!!!!!!!

        let (data, response) = try await URLSession.shared.data(for: request)
        try response.checkHTTPStatusCode()
        do {
            return try query.decode(data)
        } catch {
            print(String(data: data, encoding: .utf8) ?? "nil")
            throw error
        }
    }

}


// TODO: How do I do aliases?


// ---------------------------------------------------------------------------------------------------------------------

extension CodingUserInfoKey {
   static let fields = CodingUserInfoKey(rawValue: "fields")!
    static let resultKey = CodingUserInfoKey(rawValue: "resultKey")!
    static let selections = CodingUserInfoKey(rawValue: "selections")!
}


// TODO: Perhaps this doesn't need to be a protocol?
public protocol Selectable {

    associatedtype Datatype: Resultable

    func selections() -> [any IdentifiableSelection]
}

public protocol Resultable {

//    // TODO: Rename to codingKey
//    init(with container: KeyedDecodingContainer<UnknownCodingKeys>,
//         key: UnknownCodingKeys,
//         selections: [any IdentifiableSelection]) throws

    init(from decoder: MyDecoder, selections: [any IdentifiableSelection]) throws

}

// Structs whose selection can be defined statically.
// TODO: Perhaps there's a combination protocol these could implement?
public protocol StaticSelectable {

    // TODO: We should probably warn/crash on collisions?
    static func selection() -> [any IdentifiableSelection]

}

@resultBuilder
public struct SelectionBuilder {

    public static func buildBlock(_ components: [any IdentifiableSelection]...) -> [any IdentifiableSelection] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: any IdentifiableSelection) -> [any IdentifiableSelection] {
        [expression]
    }

    public static func buildExpression(_ expression: [any IdentifiableSelection]) -> [any IdentifiableSelection] {
        expression
    }
}

// TODO: It really does make sense to fold all this stuff into NamedSelection we can likely get away with this alone.
public protocol IdentifiableSelection: Selectable {

    var name: String { get }
    var alias: String? { get }
    var resultKey: String { get }

}

extension IdentifiableSelection {

    public func query() -> String? {
        var lookup = name
        if let alias {
            lookup = "\(alias):\(lookup)"
        }
        let subselection = selections()
            .compactMap { selection in
                selection.query()
            }
            .joined(separator: " ")
        guard !subselection.isEmpty else {
            return lookup
        }
        return "\(lookup) { \(subselection) }"
    }

    // TODO: Perhaps this should only exist on query classes? // Top level `Query` protocol for this?
    // Public on query, and private internally?
    public func decode(_ data: Data) throws -> Datatype {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo = [
            .resultKey: resultKey,
            .selections: selections()
        ]
        return try decoder.decode(ResultWrapper<Self>.self, from: data).value
//        return KeyedContainer([
//            resultKey: result
//        ])
    }

    public func result(with container: KeyedDecodingContainer<UnknownCodingKeys>,
                       codingKey: UnknownCodingKeys,
                       selections: [any IdentifiableSelection]) throws -> Datatype {
        let decoder = MyDecoder(key: codingKey, container: container)
        return try Datatype(from: decoder, selections: selections)
    }

}

// This is the magic that allows us to start the decoding stack by getting to the first-level container.
public struct ResultWrapper<T: Selectable>: Decodable {

    let value: T.Datatype

    public init(from decoder: any Decoder) throws {
        let resultKey = UnknownCodingKeys(stringValue: decoder.userInfo[.resultKey] as! String)!
        let selections = decoder.userInfo[.selections] as! [any IdentifiableSelection]
        let container = try decoder.container(keyedBy: UnknownCodingKeys.self)
        let decoder = MyDecoder(key: resultKey, container: container)
        self.value = try T.Datatype(from: decoder, selections: selections)
    }

}

// TODO: Do queries always returned a named selection and is that how this works? That makes extra sense for the keyed container to be on the result type.
// I think the data type makes no sense here. Is this a side effect of getting the protocols insufficiently fine grained?
public struct GQLQuery: IdentifiableSelection {

    public typealias Datatype = KeyedContainer

    public let name = "query"
    public let alias: String? = nil
    public let resultKey = "data"

    private let _selection: [any IdentifiableSelection]

    public init(@SelectionBuilder selection: () -> [any IdentifiableSelection]) {
        self._selection = selection()
    }

    public func selections() -> [any IdentifiableSelection] {
        return self._selection
    }

}

// TODO: Extract the selection key into a separate correlated protocol?
public struct Selection<T: Resultable>: IdentifiableSelection {

    public typealias Datatype = T

    public let name: String
    public let alias: String?

    public var resultKey: String {
        return alias ?? name
    }

    private let _selections: [any IdentifiableSelection]

    public func selections() -> [any IdentifiableSelection] {
        return _selections
    }

}

public struct KeyedContainer: Resultable {

    // TODO: Rename?
    let fields: [String: Any]

    init(_ fields: [String: Any]) {
        self.fields = fields
    }

    public init(with container: KeyedDecodingContainer<UnknownCodingKeys>, 
                key: UnknownCodingKeys,
                selections: [any IdentifiableSelection]) throws {
        let container = try container.nestedContainer(keyedBy: UnknownCodingKeys.self, forKey: key)
        var fields: [String: Any] = [:]
        for selection in selections {
            let codingKey = UnknownCodingKeys(stringValue: selection.resultKey)!  // <-- TODO: Convenience for this on the identifier?
            fields[selection.resultKey] = try selection.result(with: container,
                                                           codingKey: codingKey,
                                                           selections: selection.selections())
        }
        self.fields = fields
    }

    public init(from decoder: MyDecoder, selections: [any IdentifiableSelection]) throws {
        let container = try decoder.container(keyedBy: UnknownCodingKeys.self)
        var fields: [String: Any] = [:]
        for selection in selections {
            let codingKey = UnknownCodingKeys(stringValue: selection.resultKey)!  // <-- TODO: Convenience for this on the identifier?
            fields[selection.resultKey] = try selection.result(with: container,
                                                           codingKey: codingKey,
                                                           selections: selection.selections())
        }
        self.fields = fields

    }

    public subscript<T: Resultable>(key: Selection<T>) -> Selection<T>.Datatype {
        get {
            return fields[key.resultKey] as! Selection<T>.Datatype
        }
    }


}

extension Selection where Datatype == KeyedContainer {

    public init(_ name: String, alias: String? = nil, @SelectionBuilder selection: () -> [any IdentifiableSelection]) {
        self.name = name
        self.alias = alias
        self._selections = selection()
    }

}

extension Selection where Datatype: StaticSelectable {

    public init(_ name: String, alias: String? = nil) {
        self.name = name
        self.alias = alias
        self._selections = Datatype.selection()
    }

    public init(_ name: CodingKey) {
        self.name = name.stringValue
        self.alias = nil
        self._selections = Datatype.selection()
    }

}

struct Foo: StaticSelectable, Resultable {

    let name: String

    static func selection() -> [any IdentifiableSelection] {[
        Selection<String>("name")
    ]}

    public init(with container: KeyedDecodingContainer<UnknownCodingKeys>,
                key: UnknownCodingKeys,
                selections: [any IdentifiableSelection]) throws {
        throw BuildsError.authenticationFailure
    }

    public init(from decoder: MyDecoder, selections: [any IdentifiableSelection]) throws {
        throw BuildsError.authenticationFailure
    }

}

extension String: StaticSelectable, Resultable {

    public static func selection() -> [any IdentifiableSelection] {
        return []
    }

    public init(with container: KeyedDecodingContainer<UnknownCodingKeys>,
                key: UnknownCodingKeys,
                selections: [any IdentifiableSelection]) throws {
        self = try container.decode(String.self, forKey: key)
    }

    public init(from decoder: MyDecoder, selections: [any IdentifiableSelection]) throws {
        let container = try decoder.singleValueContainer()
        self = try container.decode(String.self)
    }

}

extension Int: StaticSelectable, Resultable {

    public static func selection() -> [any IdentifiableSelection] {
        return []
    }

    public init(with container: KeyedDecodingContainer<UnknownCodingKeys>,
                key: UnknownCodingKeys,
                selections: [any IdentifiableSelection]) throws {
        throw BuildsError.authenticationFailure
    }

    public init(from decoder: MyDecoder, selections: [any IdentifiableSelection]) throws {
        let container = try decoder.singleValueContainer()
        self = try container.decode(Int.self)
    }

}


extension IdentifiableSelection {

    func selection() -> String {
        return ""
//        return Datatype.selection()
    }

}

struct Bar: StaticSelectable, Resultable {

    let id: Int
    let name: String

    static func selection() -> [any IdentifiableSelection] {[
        Selection<Int>("id"),
        Selection<String>("name"),
    ]}

    public init(with container: KeyedDecodingContainer<UnknownCodingKeys>,
                key: UnknownCodingKeys,
                selections: [any IdentifiableSelection]) throws {
        throw BuildsError.authenticationFailure
    }

    public init(from decoder: MyDecoder, selections: [any IdentifiableSelection]) throws {
        throw BuildsError.authenticationFailure
    }

}

struct Baz: StaticSelectable {

    let id: Int
    let foo: Foo
    let bar: Bar

    static func selection() -> [any IdentifiableSelection] {[
        Selection<Int>("id"),
        Selection<Foo>("foo"),
        Selection<Bar>("bar"),
    ]}

}

//struct Catlin: Selectable {
//
//    let id: Int
//    let foo: String
//    let bar: Int
//
//    static func selection() -> [any IdentifiableSelection] {[
//        NamedSelection<Int>("id"),
////        NamedSelection<Field>("inner") {[
////            NamedSelection<String>("foo"),
////            NamedSelection<Int>("bar"),
////        ]},
//    ]}
//
//}

// Part of the challenge with the object-definition and the dynamic field definition is that one of them requires an
// instance method to define the properties, and the other requires a dynamic callback?


// TODO: How do I get the list of properties from an instance, or from a static definition?



public struct MyDecoder {

//    var codingPath: [any CodingKey]
//
//    var userInfo: [CodingUserInfoKey : Any]
//
//    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
//
//    }
//
//    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
//
//    }
//
//    func singleValueContainer() throws -> any SingleValueDecodingContainer {
//
//    }

    let key: UnknownCodingKeys
    let container: KeyedDecodingContainer<UnknownCodingKeys>

    init(key: UnknownCodingKeys, container: KeyedDecodingContainer<UnknownCodingKeys>) {
        self.key = key
        self.container = container
    }

    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return try container.nestedContainer(keyedBy: Key.self, forKey: key)
    }

    public func singleValueContainer() throws -> any SingleValueDecodingContainer {
        return MySingleVlaueDecodingContainer(key: key, container: container)
    }

    // TODO: `unkeyedContainer...`

}

public struct MySingleVlaueDecodingContainer: SingleValueDecodingContainer {

    // TODO: INVERT THESEE
    let key: UnknownCodingKeys
    let container: KeyedDecodingContainer<UnknownCodingKeys>

    public var codingPath: [any CodingKey] {
        return container.codingPath + [key]
    }

    public func decodeNil() -> Bool {
        return (try? container.decodeNil(forKey: key)) ?? false
    }

    public func decode(_ type: Bool.Type) throws -> Bool {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: String.Type) throws -> String {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: Double.Type) throws -> Double {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: Float.Type) throws -> Float {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: Int.Type) throws -> Int {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: Int8.Type) throws -> Int8 {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: Int16.Type) throws -> Int16 {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: Int32.Type) throws -> Int32 {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: Int64.Type) throws -> Int64 {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: UInt.Type) throws -> UInt {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try container.decode(type, forKey: key)
    }

    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try container.decode(type, forKey: key)
    }

    public func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try container.decode(type, forKey: key)
    }

}
