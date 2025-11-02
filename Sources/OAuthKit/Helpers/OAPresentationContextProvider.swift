//
//  OAPresentationContextProvider.swift
//  OAuthKit
//
//  Created by Vincent Schiller on 02.11.25.
//

#if canImport(UIKit)
import UIKit
import AuthenticationServices

@MainActor
public final class OAPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    
    public override init() {
        super.init()
    }
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Holt die aktive Scene im Vordergrund
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }!
        
        return UIWindow(windowScene: windowScene)
    }
}
#endif
