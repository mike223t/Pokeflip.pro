# CardFlipPro iOS app

This folder is the native SwiftUI iPhone/iPad app direction for CardFlipPro.

## Product goals
- Native camera card scanner using VisionKit
- Card identification and live market-price lookup
- Deal score: BUY / MAYBE / PASS
- Take-home profit after marketplace fees
- Watchlist and collection tracking
- Shared account/backend with the CardFlipPro web product
- Pro subscription with ongoing value

## Live pricing architecture
The iOS app should call a CardFlipPro backend rather than embedding third-party API secrets in the app. The backend will normalize card identity, set/number, condition, market price, recent sales, and confidence into a stable CardFlipPro response.

## Before App Store submission
1. Create an Xcode iOS app target from these SwiftUI sources.
2. Add the Info.plist camera usage description.
3. Connect the live CardFlipPro pricing/identification backend.
4. Add authentication, collection sync, and subscription entitlement handling.
5. Test on physical iPhone/iPad devices.
6. Create the App Store Connect app record, subscription products, screenshots, privacy details, and review notes.

The native scanner is intentional: Apple expects apps to provide useful app-like functionality beyond simply repackaging a website.
