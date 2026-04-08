import SwiftUI

enum AppTab: Hashable {
    case library
    case calendar
    case settings
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .calendar

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LibraryPageView()
            }
            .tabItem {
                Label("갤러리", systemImage: "photo.stack")
            }
            .tag(AppTab.library)

            NavigationStack {
                CalendarPageView()
            }
            .tabItem {
                Label("캘린더", systemImage: "calendar")
            }
            .tag(AppTab.calendar)

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
