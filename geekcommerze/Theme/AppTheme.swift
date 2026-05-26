import SwiftUI

enum AppTheme {

    // MARK: Brand
    enum Brand {
        // Adaptive: deep indigo in light mode, periwinkle in dark mode (sufficient contrast on system backgrounds)
        static let primary = Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.62, green: 0.58, blue: 1.00, alpha: 1)
                : UIColor(red: 0.31, green: 0.25, blue: 0.91, alpha: 1)
        })
        static let accent = Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.78, green: 0.56, blue: 1.00, alpha: 1)
                : UIColor(red: 0.55, green: 0.22, blue: 0.96, alpha: 1)
        })

        // Fixed bold fills for gradient backgrounds — white text always has contrast
        private static let fill1 = Color(red: 0.31, green: 0.25, blue: 0.91)
        private static let fill2 = Color(red: 0.55, green: 0.22, blue: 0.96)

        static var gradient: LinearGradient {
            LinearGradient(colors: [fill1, fill2], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        static var gradientH: LinearGradient {
            LinearGradient(colors: [fill1, fill2], startPoint: .leading, endPoint: .trailing)
        }

        static let tint     = primary.opacity(0.12)
        static let softTint = primary.opacity(0.06)
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
        // Hierarchy: display > screenTitle > sectionHeader > cardTitle/price > body > label > caption > badge
        static let display       = Font.system(size: 22, weight: .black, design: .rounded)
        static let screenTitle   = Font.title2.bold()
        static let sectionHeader = Font.title3.bold()
        static let cardTitle     = Font.subheadline.bold()
        static let price         = Font.subheadline.bold()
        static let button        = Font.headline
        static let body          = Font.body
        static let label         = Font.subheadline
        static let caption       = Font.caption
        static let badge         = Font.caption2.bold()
        static let tag           = Font.caption.bold()
    }
}
