//
//  ClosureSelector.swift
//  icargonaut
//
//  Created by Tomas Radvansky on 10/11/2016.
//  Copyright © 2016 Tomas Radvansky. All rights reserved.
//

import Foundation
import UIKit

var handle: Int = 0

extension UIControl {
    
    func addTarget(forControlEvents controlEvents : UIControlEvents, withClosure closure : @escaping (UIControl) -> Void) {
        let closureSelector = ClosureSelector<UIControl>(withClosure: closure)
        objc_setAssociatedObject(self, &handle, closureSelector, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.addTarget(closureSelector, action: closureSelector.selector, for: controlEvents)
    }
    
}
//Parameter is the type of parameter passed in the selector
public class ClosureSelector<Parameter> {
    
    public let selector : Selector
    private let closure : ( Parameter ) -> ()
    
    init(withClosure closure : @escaping ( Parameter ) -> ()){
        self.selector = #selector(ClosureSelector.target(param:))
        self.closure = closure
    }
    
    // Unfortunately we need to cast to AnyObject here
    @objc func target( param : AnyObject) {
        closure(param as! Parameter)
    }
}
