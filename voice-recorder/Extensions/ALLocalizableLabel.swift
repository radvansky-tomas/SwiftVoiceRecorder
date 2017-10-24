//
//  ALLocalizableLabel.swift
//  entreinfidele
//
//  Created by Tomas Radvansky on 02/02/2015.
//  Copyright (c) 2015 Tomas Radvansky. All rights reserved.

import UIKit

@IBDesignable class ALLocalizableLabel: UILabel {
    // Flag for InterfaceBuilder
    var isInterfaceBuilder: Bool = false
    override func prepareForInterfaceBuilder() {
        self.isInterfaceBuilder = true
    }
    
    @IBInspectable
    var localizeString:String = "" {
        didSet {
            if !self.isInterfaceBuilder {
                #if TARGET_INTERFACE_BUILDER
                    let bundle = Bundle(for: type(of: self))
                    self.text = bundle.localizedString(forKey: self.localizeString, value:"", table: nil)
                #else
                    self.text = NSLocalizedString(self.localizeString, comment:"");
                #endif
            }
        }
    }
    
}
