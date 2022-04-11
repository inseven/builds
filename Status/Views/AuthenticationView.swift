//
//  AuthenticationView.swift
//  Status
//
//  Created by Jason Barrie Morley on 31/03/2022.
//

import SwiftUI
import WebKit

struct AuthenticationView: UIViewRepresentable {

    class Coordinator: NSObject, WKNavigationDelegate {

        var parent: AuthenticationView

        init(_ parent: AuthenticationView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            else {
                return .cancel
            }

            // TODO: Check this against the github endpoint?
            if components.host == "127.0.0.1" {
                if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                    let result = await parent.client.authenticate(with: code)
                    DispatchQueue.main.async { [parent] in
                        parent.completion(result)
                    }
                }
                return .cancel
            }

            return .allow
        }

        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {
            DispatchQueue.main.async { [parent] in
                parent.completion(.failure(error))
            }
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            DispatchQueue.main.async { [parent] in
                parent.completion(.failure(error))
            }
        }

    }

    var client: GitHubClient
    var completion: (Result<GitHub.Authentication, Error>) -> Void

    init(client: GitHubClient, completion: @escaping (Result<GitHub.Authentication, Error>) -> Void) {
        self.client = client
        self.completion = completion
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: client.authorizationUrl())
        webView.load(request)
    }

}
