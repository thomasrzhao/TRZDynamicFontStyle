//
//  ViewController.swift
//  TRZFontDescriptor
//
//  Created by Thomas Zhao on 3/10/16.
//  Copyright © 2016 Thomas Zhao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        label.fontStyle = FontStyle(
            textStyle: UIFontTextStyleHeadline,
            baseFontDescriptor: UIFontDescriptor(name: "GillSans", size: 0),
            symbolicTraits: [.TraitBold, .TraitItalic],
            size: .Scale(factor: 1.5)
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

