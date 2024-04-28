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

        XCTAssertEqual(Selection<String>("name").query(), "name")
        XCTAssertEqual(Selection<Int>("id").query(), "id")

        XCTAssertEqual(Selection<String>("name", alias: "alias").query(), "alias:name")

        XCTAssertEqual(Selection<String>("node", arguments: ["id" : 12]).query(), "node(id: 12)")
        XCTAssertEqual(Selection<String>("node", arguments: ["id" : "12"]).query(), "node(id: \"12\")")

        // TODO: Can we only allow the block-based selection constructor _when_ the destination is a keyed container?

        let login = Selection<String>("login")
        let viewer = Selection("viewer") {
            login
        }

        XCTAssertEqual(viewer.query(), "viewer { login }")

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

        XCTAssertEqual(Selection("viewer", alias: "cheese") {
            Selection<String>("login")
        }.query(), "cheese:viewer { login }")

        XCTAssertEqual(Query {
            Selection<String>("id")
        }.query(), "query { id }")

        struct Foo: StaticSelectable {

            static func selections() -> [any IdentifiableSelection] {[
                Selection<Int>("id"),
                Selection<String>("name"),
            ]}

            let id: Int
            let name: String

            init(from decoder: MyDecoder) throws {
                throw BuildsError.authenticationFailure
            }

        }

        XCTAssertEqual(Selection<Foo>("foo").query(), "foo { id name }")

        struct Bar: StaticSelectable {

            static func selections() -> [any IdentifiableSelection] {[
                Selection<Int>("id"),
                Selection<String>("name"),
                Selection<Foo>("foo"),
            ]}

            let id: Int
            let name: String
            let foo: Foo

            init(from decoder: MyDecoder) throws {
                throw BuildsError.authenticationFailure
            }

        }

        XCTAssertEqual(Selection<Bar>("bar").query(), "bar { id name foo { id name } }")

    }

}
