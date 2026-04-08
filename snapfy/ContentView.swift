import SwiftUI

enum AppTab: Hashable {
    case home
    case calendar
    case library
    case settings
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("홈", systemImage: "house")
            }
            .tag(AppTab.home)

            NavigationStack {
                CalendarPageView()
            }
            .tabItem {
                Label("캘린더", systemImage: "calendar")
            }
            .tag(AppTab.calendar)

            NavigationStack {
                LibraryPageView()
            }
            .tabItem {
                Label("최근", systemImage: "photo.stack")
            }
            .tag(AppTab.library)

            NavigationStack {
                SettingsPageView()
            }
            .tabItem {
                Label("설정", systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
    }
}

#Preview {
    ContentView()
}
