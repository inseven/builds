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

import XCTest
@testable import BuildsCore

final class QueryableTests: XCTestCase {

    func testQueries() throws {
        XCTAssertTrue(true)

        XCTAssertEqual(Selection<String>("name").subquery(), "name")
        XCTAssertEqual(Selection<Int>("id").subquery(), "id")

        XCTAssertEqual(Selection<String>("name", alias: "alias").subquery(), "alias:name")

        XCTAssertEqual(Selection<String>("node", arguments: ["id" : 12]).subquery(), "node(id: 12)")
        XCTAssertEqual(Selection<String>("node", arguments: ["id" : "12"]).subquery(), "node(id: \"12\")")

        // TODO: Can we only allow the block-based selection constructor _when_ the destination is a keyed container?

        let login = Selection<String>("login")
        let viewer = Selection<KeyedContainer>("viewer") {
            login
        }

        XCTAssertEqual(viewer.subquery(), "viewer { login }")

        let responseData = """
        {
            "viewer": {
                "login": "cheese"
            }
        }
        """.data(using: .utf8)!

        // TODO: FAILS!
//        let result = try viewer.decode(responseData)
//        print(result.fields)
//        XCTAssertEqual(result[viewer][login], "cheese")

        XCTAssertEqual(Selection<KeyedContainer>("viewer", alias: "cheese") {
            Selection<String>("login")
        }.subquery(), "cheese:viewer { login }")

        XCTAssertEqual(Query {
            Selection<String>("id")
        }.subquery(), "query { id }")

        struct Foo: StaticSelectableContainer {

            static func selections() -> [any Selectable] {[
                Selection<Int>("id"),
                Selection<String>("name"),
            ]}

            let id: Int
            let name: String

            init(from decoder: DecodingContainer) throws {
                throw BuildsError.authenticationFailure
            }

        }

        XCTAssertEqual(Selection<Foo>("foo").subquery(), "foo { id name }")

        struct Bar: StaticSelectableContainer {

            static func selections() -> [any Selectable] {[
                Selection<Int>("id"),
                Selection<String>("name"),
                Selection<Foo>("foo"),
            ]}

            let id: Int
            let name: String
            let foo: Foo

            init(from decoder: DecodingContainer) throws {
                throw BuildsError.authenticationFailure
            }

        }

        XCTAssertEqual(Selection<Bar>("bar").subquery(), "bar { id name foo { id name } }")

    }

    func testPartialDecode() throws {

        let fromage = Selection<String>("fromage")
        let selection = Selection<KeyedContainer>("data") {
            fromage
        }
        let data = """
        {
            "data": {
                "fromage": "Cheese"
            }
        }
        """.data(using: .utf8)!

        let result = try selection.decodeKeyedContainer(data)
        XCTAssertEqual(try result["data"][fromage], "Cheese")
    }

    func testViewerStructureDecode() throws {

        let login = Selection<String>("login")
        let bio = Selection<String>("bio")
        let viewer = Selection<KeyedContainer>("viewer") {
            login
            bio
        }
        let query = Query {
            viewer
        }
        let data = """
        {"data":{"viewer":{"login":"jbmorley","bio":""}}}
        """.data(using: .utf8)!

        let result = try query.decode(data)
        XCTAssertEqual(try result[viewer][login], "jbmorley")
    }

    // TODO: Test ararys!
    // TODO: Test fragments!

    func testStaticSelectableStruct() throws {

        struct Workflow: StaticSelectableContainer {

            static let id = Selection<String>("id")
            static let event = Selection<String>("event")
            static let createdAt = Selection<Date>("createdAt")

            // TODO: Push `SelectionBuilder` into the protocol?
            @SelectionBuilder static func selections() -> [any BuildsCore.Selectable] {
                id
                event
                createdAt
            }

            let id: String
            let event: String
            let createdAt: Date

            // TODO: Ideally this would take a KeyedContainer
            // TODO: Can we actually get away without the custom decoder if we pass in a single value container instead?
            init(from container: DecodingContainer) throws {
                self.id = try container.decode(Self.id)
                self.event = try container.decode(Self.event)
                self.createdAt = try container.decode(Self.createdAt)
            }

        }

        let workflow = Selection<Workflow>("workflow")
        let query = Query {
            workflow
        }

        XCTAssertEqual(workflow.subquery(), "workflow { id event createdAt }")
        XCTAssertEqual(query.query(), "query { workflow { id event createdAt } }")

        let data = """
        {"data":{"workflow":{"id":"WFR_kwLOCatyMs8AAAACEHvAIA","event":"schedule","createdAt":"2024-04-28T09:03:51Z"}}}
        """.data(using: .utf8)!

        let result = try query.decode(data)
        XCTAssertEqual(try result[workflow].id, "WFR_kwLOCatyMs8AAAACEHvAIA")
        XCTAssertEqual(try result[workflow].event, "schedule")
    }

}
