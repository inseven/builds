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

// https://en.wikipedia.org/wiki/List_of_HTTP_status_codes

struct HTTPStatusCode: CaseIterable, Equatable, Hashable {

    static func ==(lhs: HTTPStatusCode, rhs: Int) -> Bool {
         return lhs.rawValue == rhs
     }

     static func ==(lhs: Int, rhs: HTTPStatusCode) -> Bool {
         return lhs == rhs.rawValue
     }

    // 1XX Informational Response
    static let `continue` = HTTPStatusCode(rawValue: 100)
    static let switchingProtocols = HTTPStatusCode(rawValue: 101)
    static let processing = HTTPStatusCode(rawValue: 102)
    static let earlyHints = HTTPStatusCode(rawValue: 103)

    // 2XX Success
    static let ok = HTTPStatusCode(rawValue: 200)
    static let created = HTTPStatusCode(rawValue: 201)
    static let accepted = HTTPStatusCode(rawValue: 202)
    static let nonAuthoritativeInformation = HTTPStatusCode(rawValue: 203)
    static let noContent = HTTPStatusCode(rawValue: 204)
    static let resetContent = HTTPStatusCode(rawValue: 205)
    static let partialContent = HTTPStatusCode(rawValue: 206)
    static let multiStatus = HTTPStatusCode(rawValue: 207)
    static let alreadyReported = HTTPStatusCode(rawValue: 208)
    static let imUsed = HTTPStatusCode(rawValue: 226)

    // 3XX Redirection
    static let multipleChoices = HTTPStatusCode(rawValue: 300)
    static let movedPermanently = HTTPStatusCode(rawValue: 301)
    static let found = HTTPStatusCode(rawValue: 302)
    static let seeOther = HTTPStatusCode(rawValue: 303)
    static let notModified = HTTPStatusCode(rawValue: 304)
    static let useProxy = HTTPStatusCode(rawValue: 305)
    static let switchProxy = HTTPStatusCode(rawValue: 306)
    static let temporaryRedirect = HTTPStatusCode(rawValue: 307)
    static let permanentRedirect = HTTPStatusCode(rawValue: 308)

    // 4XX Client Errors
    static let badRequest = HTTPStatusCode(rawValue: 400)
    static let unauthorized = HTTPStatusCode(rawValue: 401)
    static let paymentRequired = HTTPStatusCode(rawValue: 402)
    static let forbidden = HTTPStatusCode(rawValue: 403)
    static let notFound = HTTPStatusCode(rawValue: 404)
    static let methodNotAllowed = HTTPStatusCode(rawValue: 405)
    static let notAcceptable = HTTPStatusCode(rawValue: 406)
    static let proxyAuthenticationRequired = HTTPStatusCode(rawValue: 407)
    static let requestTimeout = HTTPStatusCode(rawValue: 408)
    static let conflict = HTTPStatusCode(rawValue: 409)
    static let gone = HTTPStatusCode(rawValue: 410)
    static let lengthRequired = HTTPStatusCode(rawValue: 411)
    static let preconditionFailed = HTTPStatusCode(rawValue: 412)
    static let payloadTooLarge = HTTPStatusCode(rawValue: 413)
    static let uriTooLong = HTTPStatusCode(rawValue: 414)
    static let unsupportedMediaType = HTTPStatusCode(rawValue: 415)
    static let rangeNotSatisfiable = HTTPStatusCode(rawValue: 416)
    static let expectationFailed = HTTPStatusCode(rawValue: 417)
    static let imATeapot = HTTPStatusCode(rawValue: 418)
    static let misdirectedRequest = HTTPStatusCode(rawValue: 421)
    static let unprocessableContent = HTTPStatusCode(rawValue: 422)
    static let locked = HTTPStatusCode(rawValue: 423)
    static let failedDependency = HTTPStatusCode(rawValue: 424)
    static let tooEarly = HTTPStatusCode(rawValue: 425)
    static let upgradeRequired = HTTPStatusCode(rawValue: 426)
    static let preconditionRequired = HTTPStatusCode(rawValue: 428)
    static let tooManyRequests = HTTPStatusCode(rawValue: 429)
    static let requestHeaderFieldsTooLarge = HTTPStatusCode(rawValue: 431)
    static let unavailableForLegalReasons = HTTPStatusCode(rawValue: 451)

    // 5XX Server Errors
    static let internalServerError = HTTPStatusCode(rawValue: 500)
    static let notImplemented = HTTPStatusCode(rawValue: 501)
    static let badGateway = HTTPStatusCode(rawValue: 502)
    static let serviceUnavailable = HTTPStatusCode(rawValue: 503)
    static let gatewayTimeout = HTTPStatusCode(rawValue: 504)
    static let httpVersionNotSupported = HTTPStatusCode(rawValue: 505)
    static let variantAlsoNegotiates = HTTPStatusCode(rawValue: 506)
    static let insufficientStorage = HTTPStatusCode(rawValue: 507)
    static let loopDetected = HTTPStatusCode(rawValue: 508)
    static let startingTicketRequired = HTTPStatusCode(rawValue: 509)
    static let notExtended = HTTPStatusCode(rawValue: 510)
    static let networkAuthenticationRequired = HTTPStatusCode(rawValue: 511)

    // 6XX Multi-Sided Errors
    static let inaccessibleRequest = HTTPStatusCode(rawValue: 604)
    static let notAllowed = HTTPStatusCode(rawValue: 605)
    static let requestDeletedOrModified = HTTPStatusCode(rawValue: 644)

    static var allCases: [HTTPStatusCode] = [

        // 1XX Informational Response
        `continue`,
        switchingProtocols,
        processing,
        earlyHints,

        // 2XX Success
        ok,
        created,
        accepted,
        nonAuthoritativeInformation,
        noContent,
        resetContent,
        partialContent,
        multiStatus,
        alreadyReported,
        imUsed,

        // 3XX Redirection
        multipleChoices,
        movedPermanently,
        found,
        seeOther,
        notModified,
        useProxy,
        switchProxy,
        temporaryRedirect,
        permanentRedirect,

        // 4XX Client Errors
        badRequest,
        unauthorized,
        paymentRequired,
        forbidden,
        notFound,
        methodNotAllowed,
        notAcceptable,
        proxyAuthenticationRequired,
        requestTimeout,
        conflict,
        gone,
        lengthRequired,
        preconditionFailed,
        payloadTooLarge,
        uriTooLong,
        unsupportedMediaType,
        rangeNotSatisfiable,
        expectationFailed,
        imATeapot,
        misdirectedRequest,
        unprocessableContent,
        locked,
        failedDependency,
        tooEarly,
        upgradeRequired,
        preconditionRequired,
        tooManyRequests,
        requestHeaderFieldsTooLarge,
        unavailableForLegalReasons,

        // 5XX Server Errors
        internalServerError,
        notImplemented,
        badGateway,
        serviceUnavailable,
        gatewayTimeout,
        httpVersionNotSupported,
        variantAlsoNegotiates,
        insufficientStorage,
        loopDetected,
        startingTicketRequired,
        notExtended,
        networkAuthenticationRequired,

        // 6XX Multi-Sided Codes
        inaccessibleRequest,
        notAllowed,
        requestDeletedOrModified,
    ]

    var isSuccess: Bool {
        return Set<HTTPStatusCode>.allSuccesses.contains(self)
    }

    let rawValue: Int

}

extension HTTPStatusCode {

    var localizedDescription: String {
        switch self {

        // 1XX Informational Response
        case .continue:
            return "Continue"
        case .switchingProtocols:
            return "Switching Protocols"
        case .processing:
            return "Processing"
        case .earlyHints:
            return "Early Hints"

        // 2XX Success
        case .ok:
            return "OK"
        case .created:
            return "Created"
        case .accepted:
            return "Accepted"
        case .nonAuthoritativeInformation:
            return "Non-Authorative Information"
        case .noContent:
            return "No Content"
        case .resetContent:
            return "Reset Content"
        case .partialContent:
            return "Partial Content"
        case .multiStatus:
            return "Multi-Status"
        case .alreadyReported:
            return "Already Reported"
        case .imUsed:
            return "IM Used"

        // 3XX Redirection
        case .multipleChoices:
            return "Multiple Choices"
        case .movedPermanently:
            return "Moved Permanently"
        case .found:
            return "Found"
        case .seeOther:
            return "See Other"
        case .notModified:
            return "Not Modified"
        case .useProxy:
            return "Use Proxy"
        case .switchProxy:
            return "Switch Proxy"
        case .temporaryRedirect:
            return "Temporary Redirect"
        case .permanentRedirect:
            return "Permanent Redirect"

        // 4XX Client Errors
        case .badRequest:
            return "Bad Request"
        case .unauthorized:
            return "Unauthorized"
        case .paymentRequired:
            return "Payment Required"
        case .forbidden:
            return "Forbidden"
        case .notFound:
            return "Not Found"
        case .methodNotAllowed:
            return "Method Not Allowed"
        case .notAcceptable:
            return "Not Acceptable"
        case .proxyAuthenticationRequired:
            return "Proxy Authentication Required"
        case .requestTimeout:
            return "Request Timeout"
        case .conflict:
            return "Conflict"
        case .gone:
            return "Gone"
        case .lengthRequired:
            return "Length Required"
        case .preconditionFailed:
            return "Precondition Failed"
        case .payloadTooLarge:
            return "Payload Too Large"
        case .uriTooLong:
            return "URI Too Long"
        case .unsupportedMediaType:
            return "Unsupported Media Type"
        case .rangeNotSatisfiable:
            return "Range Not Satisfiable"
        case .expectationFailed:
            return "Expectation Failed"
        case .imATeapot:
            return "I'm a Teapot"
        case .misdirectedRequest:
            return "Misdirected Request"
        case .unprocessableContent:
            return "Unprocessable Content"
        case .locked:
            return "Locked"
        case .failedDependency:
            return "Failed Dependency"
        case .tooEarly:
            return "Too Early"
        case .upgradeRequired:
            return "Upgrade Required"
        case .preconditionRequired:
            return "Precondition Required"
        case .tooManyRequests:
            return "Too Many Requests"
        case .requestHeaderFieldsTooLarge:
            return "Request Header Fields Too Large"
        case .unavailableForLegalReasons:
            return "Unavailable For Legal Reasons"

        // 5XX Server Errors
        case .internalServerError:
            return "Internal Server Error"
        case .notImplemented:
            return "Not Implemented"
        case .badGateway:
            return "Bad Gateway"
        case .serviceUnavailable:
            return "Service Unavailable"
        case .gatewayTimeout:
            return "Gateway Timeout"
        case .httpVersionNotSupported:
            return "HTTP Version Not Supported"
        case .variantAlsoNegotiates:
            return "Variant Also Negotiates"
        case .insufficientStorage:
            return "Insufficient Storage"
        case .loopDetected:
            return "Loop Detected"
        case .startingTicketRequired:
            return "Starting Ticket Required"
        case .notExtended:
            return "Not Extended"
        case .networkAuthenticationRequired:
            return "Network Authentication Required"

        // 6XX Multi-Sided Codes
        case .inaccessibleRequest:
            return "Inaccessible Request"
        case .notAllowed:
            return "Not Allowed"
        case .requestDeletedOrModified:
            return "Request Deleted Or Modified"

        default:
            return "Unknown HTTP response code (\(rawValue))"
        }
    }

}

extension Set where Element == HTTPStatusCode {

    static var allInformationalResponses: Self = .init(100..<200)
    static var allSuccesses: Self = .init(200..<300)
    static var allRedirections: Self = .init(300..<400)
    static var allClientErrors: Self = .init(400..<500)
    static var allServerErrors: Self = .init(500..<600)
    static var allMultiSidedErrors: Self = .init(600..<700)

    private init(_ range: Range<Int>) {
        self = Set(range.map({ HTTPStatusCode(rawValue: $0) }))
    }

    static func |(lhs: Self, rhs: Self) -> Self {
        return lhs.union(rhs)
    }

    static func |(lhs: Self, rhs: HTTPStatusCode) -> Self {
        return lhs.union([rhs])
    }

    static func |(lhs: HTTPStatusCode, rhs: Self) -> Self {
        return rhs.union([lhs])
    }

}

extension HTTPStatusCode {

    static func |(lhs: Self, rhs: Self) -> Set<HTTPStatusCode> {
        return Set([lhs, rhs])
    }

}
