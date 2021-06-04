//
//  UserAuthentication.swift
//  Todos
//
//  Created by Kody Deda on 6/2/21.
//

import SwiftUI
import ComposableArchitecture
import Firebase
import Combine
import AuthenticationServices



struct Authentication {
    struct State: Equatable {
        var signedIn = false
        var attempted = false
        var error: FirebaseError?
        var email = String.init()
        var password = String.init()
    }
    
    enum Action: Equatable {
        case updateEmail(String)
        case updatePassword(String)
        
        case signInButtonTapped(FirebaseAuthentication)
        case signInResult (Result<Bool, FirebaseError>)

        case signOut
    }
    
    struct Environment {
        var signIn: Effect<Action, Never> {
            Firebase.signIn()
                .map(Action.signInResult)
                .eraseToEffect()
        }

        func signIn(_ email: String, _ password: String) -> Effect<Action, Never> {
            Firebase.signIn(email, password)
                .map(Action.signInResult)
                .eraseToEffect()
        }
        
        func signIn(using appleIDCredential: ASAuthorizationAppleIDCredential) -> Effect<Action, Never> {
            Firebase.signIn(using: appleIDCredential)
                .map(Action.signInResult)
                .eraseToEffect()
        }
    }
}

extension Authentication {
    static let reducer = Reducer<State, Action, Environment> { state, action, environment in
        
        switch action {
        
        case let .updateEmail(value):
            state.email = value
            return .none
            
        case let .updatePassword(value):
            state.password = value
            return .none
            
        case let .signInButtonTapped(authentication):
            
            switch authentication {
            
            case .anonymous:
                return environment.signIn
                
            case .email:
                return environment.signIn(state.email, state.password)
                
            case let .apple(token):
                return environment.signIn(using: token)
                
            }

        case .signOut:
            state.signedIn = false
            return .none

        // Results
        case .signInResult(.success):
            state.signedIn.toggle()
            return .none
            
        case let .signInResult(.failure(error)):
            state.error = error
            state.attempted = true
            return .none
        }
    }
}

extension Authentication {
    static let defaultStore = Store(
        initialState: .init(),
        reducer: reducer,
        environment: .init()
    )
}
