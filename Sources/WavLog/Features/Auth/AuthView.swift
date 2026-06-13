// AuthView is retired — routing is now handled by InviteGateView and SignInView.
// RootView uses AppState.authRoute to pick the correct screen.
// This file is kept as a placeholder to avoid breaking any lingering references.

import SwiftUI

// Typealias so any leftover references still compile during transition
typealias AuthView = SignInView
