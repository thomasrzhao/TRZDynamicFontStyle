TRZDynamicFontStyle
===

A better way to use Dynamic Type.

Why?
---
Dynamic Type is a great feature in iOS that lets users set their preferred text size at a system-wide level. Unfortunately, the API for this feature is quite annoying to use, requiring you to register for notifications and re-set the font whenever the user changes the preferred text size while the app is still running.

This library makes correctly using Dynamic Type much easier by allowing you to specify a `FontStyle` instead of a `UIFont` for system views. Once a `FontStyle` is specified, an appropriate font is automatically chosen in response to the system text size changing and no manual font updating is required.

Setup
---
1. Drag FontStyle.swift into your project.
2. There is no step 2.

Usage
---
```swift
let label = UILabel()
label.fontStyle = FontStyle(textStyle: UIFontTextStyleBody)
```

That's it! The label's font will automatically update when the preferred system text size changes—no need to listen to `UIContentSizeCategoryDidChangeNotification` and update the font manually.

Advanced Usage
---
You can specify more advanced parameters to further specify the final font that is produced. The `FontStyle` struct initializer has up to four possible arguments:

- `textStyle:String` 
The semantic text style describing the intended use for a font. These values are defined by the system and start with `UIFontTextStyle`. This argument is required.

- `baseFontDescriptor:UIFontDescriptor?` 
The base font descriptor to use. When `nil`, the system font is used. You can specify a custom base font by setting this parameter.

- `symbolicTraits:UIFontDescriptorSymbolicTraits` 
A bit mask that describes the traits of the generated font descriptor. For example, to create a bold font, specify `.TraitBold`.

- `size:FontStyle.Size` 
An enum that describes how the final font should be sized. See the Sizing section for more details.

```swift
label.fontStyle = FontStyle(
    textStyle: UIFontTextStyleHeadline, //This label is semantically a headline
    baseFontDescriptor: UIFontDescriptor(name: "GillSans", size: 0), //Use Gill Sans as the base font; the size parameter is ignored
    symbolicTraits: [.TraitBold, .TraitItalic], //Make the final font bold and italic
    size: .Scale(factor: 1.5) //The final font should be 1.5 times as big as the default font size for this text style
)
```

Sizing
---
The system has predefined font sizes that are determined by the combination of the text style and the user-specified system-wide text size. However, you can tweak the final result by specifying a custom value for the `size` parameter, which takes an enum of type `FontStyle.Size`:

- `.Absolute(size:CGFloat)`
The font size will always be the value specified. Not recommended, since a fixed size basically defeats the purpose of Dynamic Type.
- `.Relative(offset:CGFloat)`
The font size will be determined by adding the given offset to the default font size. For example, to make a font 1pt smaller than the default size, pass in `.Relative(offset: -1)` as the `size` parameter.
- `.Scale(factor:CGFloat)`
The font size will be scaled by multiplying the given scale factor to the default font size. For example, to make a font half the size of the default, pass in `.Scale(factor: 0.5)` as the `size` parameter.
- `.Custom(function:((originalSize:CGFloat)->CGFloat))`
Allows you to specify an arbitrarily complex function to determine the final font size. For example, to specify a font size that is half the size of the default, yet no smaller than 8pts, you can do the following:
```swift
label.fontStyle = FontStyle(textStyle: UIFontTextStyleBody, size: .Custom(function: { max($0/2, 8) }))
```

Custom Views
---
Extensions are already provided for `UILabel`, `UITextView`, and `UITextField`, so you can just directly set the `fontStyle` property on those objects. However, it's easy to add `FontStyle` support to your custom views as well. For example, the excellent [JVFloatLabeledTextField](https://github.com/jverdi/JVFloatLabeledTextField) has a `floatingLabelFont` property. To make this font respond to Dynamic Type, simply add the following extension:

```swift
public extension JVFloatLabeledTextField {
    //Unique namespaced key to use for the associated object API
    //See: http://nshipster.com/swift-objc-runtime/
    private struct AssociatedObjectKey {
        static var floatingLabelFontStyleKey = "JVFloatLabeledTextField+FloatingLabelFontStyle"
    }

    public var floatingLabelFontStyle:FontStyle? {
        get {
            return FontStyle.associatedFontStyleForObject(self, key: &AssociatedObjectKey.floatingLabelFontStyleKey)
        }
        set {
            FontStyle.setAssociatedFontStyle(newValue, forObject: self, key: &AssociatedObjectKey.floatingLabelFontStyleKey, fontKeyPath: "floatingLabelFont") //Specify the appropriate key path here
        }
    }
}
```

Potential Pitfalls
---
- Once a `fontStyle` is set, you should not touch the `font` property yourself. Any changes you make to that property will be overwritten if the system text size setting changes. Instead, make appropriate changes to the `fontStyle`.
- This library does not attempt to preserve attributed text. If you have attributed text set as the contents for a `UILabel`, for example, you should manually manage font size changes yourself, since this library sets the `font` property and will overwrite any custom font attributes present.
- It's possible to construct invalid combinations of symbolic traits for a given base font descriptor, in which case the font will end up being the standard system font.