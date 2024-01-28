//
//  OrganizationsView.swift
//  Status
//
//  Created by Jason Barrie Morley on 02/04/2022.
//

import SwiftUI

struct OrganizationsView: View {

    @EnvironmentObject var client: GitHubClient

    @State var organizations: [GitHub.Organization] = []

    func fetch() {
        Task {
            do {
                let organizations = try await client.organizations()
                DispatchQueue.main.async {
                    self.organizations = organizations
                }
                print("organizations = \(organizations)")
            } catch {
                print("Failed to fetch repositories with error \(error)")
            }
        }
    }

    var body: some View {
        List {
            ForEach(organizations) { organization in
                Text(organization.login)
            }
        }
        .navigationTitle("Select Action")
        .onAppear {
            fetch()
        }
    }

}
