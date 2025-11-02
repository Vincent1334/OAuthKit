//
//  OAWebSessionCoordinator.swift
//  OAuthKit
//
//  Created by Vincent Schiller on 02.11.25.
//

#if canImport(AuthenticationServices)
import AuthenticationServices
import SwiftUI

@MainActor
public final class OAWebSessionCoordinator: NSObject {

    private var session: ASWebAuthenticationSession?
    private let contextProvider: ASWebAuthenticationPresentationContextProviding
    private let oauth: OAuth

    public init(oauth: OAuth,
                contextProvider: ASWebAuthenticationPresentationContextProviding) {
        self.oauth = oauth
        self.contextProvider = contextProvider
    }

    public func update(state: OAuth.State) {
        switch state {
        case .authorizing(let provider, let grantType):
            startSession(provider: provider, grantType: grantType)
        default:
            break
        }
    }

    private func startSession(provider: OAuth.Provider, grantType: OAuth.GrantType) {
        guard
            let redirectURI = provider.redirectURI,
            let redirectURL = URL(string: redirectURI),
            let callbackScheme = redirectURL.scheme
        else { return }

        guard let request = OAuth.Request.auth(provider: provider, grantType: grantType),
              let authURL = request.url else { return }

        session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, error in
            guard let self else { return }
            if let callbackURL {
                self.handleRedirect(url: callbackURL, provider: provider, grantType: grantType)
            } else {
                self.oauth.state = .error(provider, .badResponse)
            }
        }

        session?.presentationContextProvider = contextProvider
        session?.prefersEphemeralWebBrowserSession = true
        session?.start()
    }

    private func handleRedirect(url: URL, provider: OAuth.Provider, grantType: OAuth.GrantType) {
        guard
            let redirectURI = provider.redirectURI,
            url.absoluteString.starts(with: redirectURI),
            let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let code = comps.queryItems?.first(where: { $0.name == "code" })?.value,
            let state = comps.queryItems?.first(where: { $0.name == "state" })?.value
        else { return }

        switch grantType {
        case .authorizationCode(let expected):
            guard state == expected else { return }
            oauth.token(provider: provider, code: code)
        case .pkce(let pkce):
            guard state == pkce.state else { return }
            oauth.token(provider: provider, code: code, pkce: pkce)
        default:
            break
        }
    }
}
#endif
