import WidgetKit
import SwiftUI

@main
struct BinaryCuriousWidgets: WidgetBundle {
    var body: some Widget {
        QuickCaptureWidget()
        CountWidget()
        StreakWidget()
        RecentSightingWidget()
    }
}
