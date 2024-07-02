//
//  SyntaxHelper.swift
//
//
//  Created by Анастасия Ищенко on 13.03.2024.
//

import SwiftSyntax

struct SyntaxHelper {
    
    static func shouldCreateSetFunc(
        for variable: VariableDeclSyntax
    ) -> Bool {
        variable.bindingSpecifier.text != "let" && !variable.isGetOnly
    }
}
