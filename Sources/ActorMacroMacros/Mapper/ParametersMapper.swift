//
//  ParametersMapper.swift
//
//
//  Created by Анастасия Ищенко on 29.02.2024.
//

import SwiftSyntax

struct ParametersMapper {
    
    static func mapProtectionLevel(_ level: LabeledExprSyntax?) -> DeclModifierSyntax? {
        guard let name = level?.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        else { return nil }
        return DeclModifierSyntax(
            name: TokenSyntax(stringLiteral: String(name.dropLast()))
        )
    }
}
