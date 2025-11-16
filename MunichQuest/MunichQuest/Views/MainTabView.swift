import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var locationManager: LocationManager

    @State private var selectedTab = 0
    @State private var jumpToLocationId: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView(jumpToLocationId: $jumpToLocationId)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(0)

            StatsView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(1)

            SocialView()
                .tabItem {
                    Label("Social", systemImage: "person.3.fill")
                }
                .tag(2)

            HelpView()
                .tabItem {
                    Label("Help", systemImage: "questionmark.circle.fill")
                }
                .tag(3)
        }
        .accentColor(Color(red: 0.4, green: 0.49, blue: 0.92))
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("JumpToLocation"))) { notification in
            if let locationId = notification.userInfo?["locationId"] as? String {
                jumpToLocationId = locationId
                selectedTab = 0  // Switch to map tab
            }
        }
    }
}
