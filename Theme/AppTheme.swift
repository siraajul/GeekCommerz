import SwiftUI

// MARK: - AppTheme
// Centralised design tokens. Update here to propagate changes app-wide.
// Adoption guide: replace magic numbers in views with the tokens below.

enum AppTheme {

    // MARK: Corner radii
    enum Radius {
        static let xs:   CGFloat = 8
        static let sm:   CGFloat = 10
        static let md:   CGFloat = 12
        static let lg:   CGFloat = 14
        static let xl:   CGFloat = 16
        static let card: CGFloat = 14
    }

    // MARK: Spacing scale
    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 20
        static let xxl: CGFloat = 24
    }

    // MARK: Semantic colours
    enum Colors {
        static let primary   = Color.blue
        static let success   = Color.green
        static let warning   = Color.orange
        static let danger    = Color.red
        static let surface   = Color(.systemBackground)
        static let grouped   = Color(.systemGroupedBackground)
        static let secondary = Color.secondary
    }

    // MARK: Reusable shadow tokens
    enum Shadow {
        static let cardColor:  Color  = Color.black.opacity(0.07)
        static let cardRadius: CGFloat = 4
        static let cardY:      CGFloat = 2

        static let subtleColor:  Color  = Color.black.opacity(0.05)
        static let subtleRadius: CGFloat = 2
        static let subtleY:      CGFloat = 1
    }

    // MARK: Typography
    enum Typography {
        static let sectionHeader = Font.title3.bold()
        static let cardTitle     = Font.subheadline.bold()
        static let badge         = Font.caption2.bold()
        static let caption       = Font.caption
        static let price         = Font.subheadline.bold()
    }
}
