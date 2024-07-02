//
//  StringsHelper.swift
//  
//
//  Created by Анастасия Ищенко on 07.02.2024.
//

import SwiftSyntax
import SwiftSyntaxBuilder

struct StringsHelper {
    
    /// Убирает один уровень отступов слева
    /// 1 - Считаем кол-во пробелов, которые необходимо убрать
    /// 2 - Заменяем последовательность перехода на новую строку и отступа просто на переход на новую строку
    static func removeLeadingTriviaFromDecl(_ decl: DeclSyntax) -> DeclSyntax {
        var resultDecl: DeclSyntax = decl
        decl.leadingTrivia.forEach {
            switch $0 {
            case .spaces(let count): // 1
                let declString = decl.description.replacingOccurrences(of: "\n" + String(repeating: " ", count: count), with: "\n") // 2
                resultDecl = DeclSyntax(stringLiteral: declString)
                return
            default:
                break
            }
        }
        return resultDecl
    }
    
    static func capitalizingFirstLetter(_ string: String) -> String {
        return string.prefix(1).uppercased() + string.dropFirst()
    }
}
