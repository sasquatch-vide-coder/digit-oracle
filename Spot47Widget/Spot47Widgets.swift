import WidgetKit
import SwiftUI

@main
struct Spot47Widgets: WidgetBundle {
    var body: some Widget {
        QuickCaptureWidget()
        CountWidget()
        StreakWidget()
        RecentSightingWidget()
    }
}
