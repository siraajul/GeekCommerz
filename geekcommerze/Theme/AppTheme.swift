import SwiftUI

enum AppTheme {

    // MARK: Brand
    enum Brand {
        static let primary = Color(red: 0.31, green: 0.25, blue: 0.91)
        static let accent  = Color(red: 0.55, green: 0.22, blue: 0.96)

        static var gradient: LinearGradient {
            LinearGradient(colors: [primary, accent], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        static var gradientH: LinearGradient {
            LinearGradient(colors: [primary, accent], startPoint: .leading, endPoint: .trailing)
        }

        static let tint     = primary.opacity(0.10)
        static let softTint = primary.opacity(0.05)
    }

    // MARK: Corner radii
    enum Radius {
        static let xs:   CGFloat = 6
        static let sm:   CGFloat = 10
        static let md:   CGFloat = 12
        static let lg:   CGFloat = 16
        static let xl:   CGFloat = 20
        static let xxl:  CGFloat = 24
        static let card: CGFloat = 16
        static let chip: CGFloat = 10
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
        static let primary      = Brand.primary
        static let accent       = Brand.accent
        static let success      = Color(red: 0.07, green: 0.73, blue: 0.45)
        static let warning      = Color.orange
        static let danger       = Color(red: 0.96, green: 0.26, blue: 0.21)
        static let surface      = Color(.systemBackground)
        static let grouped      = Color(.systemGroupedBackground)
        static let secondary    = Color.secondary
        static let imageSurface = Brand.tint
    }

    // MARK: Shadows
    enum Shadow {
        static let cardColor:  Color   = Color.black.opacity(0.09)
        static let cardRadius: CGFloat = 8
        static let cardY:      CGFloat = 4

        static let subtleColor:  Color   = Color.black.opacity(0.05)
        static let subtleRadius: CGFloat = 3
        static let subtleY:      CGFloat = 2

        static let elevatedColor:  Color   = Color.black.opacity(0.14)
        static let elevatedRadius: CGFloat = 14
        static let elevatedY:      CGFloat = 6
    }

    // MARK: Typography
    enum Typography {
        static let sectionHeader = Font.title3.bold()
        static let cardTitle     = Font.subheadline.bold()
        static let badge         = Font.caption2.bold()
        static let caption       = Font.caption
        static let price         = Font.subheadline.bold()
        static let display       = Font.system(size: 22, weight: .bold, design: .rounded)
    }
}
