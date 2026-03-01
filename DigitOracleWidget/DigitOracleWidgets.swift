import WidgetKit
import SwiftUI

@main
struct DigitOracleWidgets: WidgetBundle {
    var body: some Widget {
        QuickCaptureWidget()
        CountWidget()
        StreakWidget()
        RecentSightingWidget()
    }
}
