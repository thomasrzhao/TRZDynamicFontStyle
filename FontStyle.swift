//
//  FontStyle.swift
//  FontStyle
//
//  Created by Thomas Zhao on 3/10/16.
//  Copyright © 2016 Thomas Zhao. All rights reserved.
//

import UIKit

public extension UILabel {
    private struct AssociatedObjectKey {
        static var key = "UILabel+FontStyle"
    }
    
    public var fontStyle:FontStyle? {
        get {
            return FontStyle.associatedFontStyleForObject(self, key: &AssociatedObjectKey.key)
        }
        set {
            FontStyle.setAssociatedFontStyle(newValue, forObject: self, key: &AssociatedObjectKey.key)
        }
    }
}

public extension UITextView {
    private struct AssociatedObjectKey {
        static var key = "UITextView+FontStyle"
    }
    
    public var fontStyle:FontStyle? {
        get {
            return FontStyle.associatedFontStyleForObject(self, key: &AssociatedObjectKey.key)
        }
        set {
            FontStyle.setAssociatedFontStyle(newValue, forObject: self, key: &AssociatedObjectKey.key)
        }
    }
}

public extension UITextField {
    private struct AssociatedObjectKey {
        static var key = "UITextField+FontStyle"
    }
    
    public var fontStyle:FontStyle? {
        get {
            return FontStyle.associatedFontStyleForObject(self, key: &AssociatedObjectKey.key)
        }
        set {
            FontStyle.setAssociatedFontStyle(newValue, forObject: self, key: &AssociatedObjectKey.key)
        }
    }
}

public struct FontStyle:Equatable {
    public enum Size:Equatable {
        case Absolute(size:CGFloat)
        case Relative(offset:CGFloat)
        case Scale(factor:CGFloat)
        case Custom(function:((originalSize:CGFloat)->CGFloat))
    }
    
    public var textStyle:String
    public var baseFontDescriptor:UIFontDescriptor?
    public var symbolicTraits:UIFontDescriptorSymbolicTraits
    public var size:Size
    
    public init(textStyle:String, baseFontDescriptor:UIFontDescriptor? = nil, symbolicTraits:UIFontDescriptorSymbolicTraits = [], size:Size = .Relative(offset: 0)) {
        self.textStyle = textStyle
        self.baseFontDescriptor = baseFontDescriptor
        self.symbolicTraits = symbolicTraits
        self.size = size
    }
    
    public var fontDescriptor:UIFontDescriptor {
        var descriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(textStyle)
        if let baseFontDescriptor = baseFontDescriptor {
            descriptor = baseFontDescriptor.fontDescriptorWithSize(descriptor.pointSize)
        }
        if symbolicTraits != [] {
            descriptor = descriptor.fontDescriptorWithSymbolicTraits(symbolicTraits)
        }
        switch size {
        case let .Absolute(size):
            descriptor = descriptor.fontDescriptorWithSize(size)
        case let .Relative(offset):
            if offset != 0 {
                descriptor = descriptor.fontDescriptorWithSize(descriptor.pointSize + offset)
            }
        case let .Scale(scale):
            if scale != 1.0 {
                descriptor = descriptor.fontDescriptorWithSize(descriptor.pointSize * scale)
            }
        case let .Custom(function):
            let newSize = function(originalSize: descriptor.pointSize)
            if newSize != descriptor.pointSize {
                descriptor = descriptor.fontDescriptorWithSize(newSize)
            }
        }
        return descriptor
    }
}

public extension FontStyle {
    private static func associatedFontStyleManagerForObject(object:AnyObject, key:UnsafePointer<Void>) -> FontStyleManager? {
        return objc_getAssociatedObject(object, key) as? FontStyleManager
    }
    
    private static func setAssociatedFontStyleManager(manager:FontStyleManager?, object:AnyObject, key:UnsafePointer<Void>) {
        objc_setAssociatedObject(object, key, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    public static func associatedFontStyleForObject(object:AnyObject, key:UnsafePointer<Void>) -> FontStyle? {
        guard let manager = objc_getAssociatedObject(object, key) as? FontStyleManager
            else { return nil }
        return manager.fontStyle
    }
    
    public static func setAssociatedFontStyle(fontStyle:FontStyle?, forObject object:AnyObject, key:UnsafePointer<Void>, fontKeyPath:String = "font") {
        let oldManager = associatedFontStyleManagerForObject(object, key: key)
        if oldManager?.fontStyle != fontStyle || oldManager?.fontKeyPath != fontKeyPath {
            if let style = fontStyle {
                let manager = FontStyleManager(object: object, fontStyle: style, fontKeyPath: fontKeyPath)
                setAssociatedFontStyleManager(manager, object: object, key: key)
            } else {
                setAssociatedFontStyleManager(nil, object: object, key: key)
            }
        }
    }
}

public func ==(lhs:FontStyle, rhs:FontStyle) -> Bool {
    return
            lhs.textStyle == rhs.textStyle &&
            lhs.baseFontDescriptor == rhs.baseFontDescriptor &&
            lhs.symbolicTraits == rhs.symbolicTraits &&
            lhs.size == rhs.size
}

public func ==(lhs:FontStyle.Size, rhs:FontStyle.Size) -> Bool {
    switch (lhs, rhs) {
    case let (.Absolute(lval), .Absolute(rval)):
        return lval == rval
    case let (.Relative(lval), .Relative(rval)):
        return lval == rval
    case let (.Scale(lval), .Scale(rval)):
        return lval == rval
    default:
        return false
    }
}

private class FontStyleManager: NSObject {
    private let fontStyle:FontStyle
    private weak var object:AnyObject?
    private let fontKeyPath:String
    
    init(object:AnyObject, fontStyle:FontStyle, fontKeyPath:String) {
        self.fontStyle = fontStyle
        self.object = object
        self.fontKeyPath = fontKeyPath
        
        super.init()
        
        updateFont()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updateFont"), name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    @objc private func updateFont() {
        guard let object = object else { return }
        object.setValue(UIFont(descriptor: fontStyle.fontDescriptor, size: 0), forKeyPath: fontKeyPath)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}