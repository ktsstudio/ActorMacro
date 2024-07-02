//
//  ActorMacroError.swift
//
//
//  Created by Анастасия Ищенко on 07.02.2024.
//

import Foundation
import SwiftDiagnostics

let Domain: String = "ActorMacro"

enum ActorMacroError: Error {
    
    case invalidType
    case invalidVariable(_ variableName: String)
    case noVariableTypeAnnotation(_ variableName: String)
}

extension ActorMacroError: DiagnosticMessage {
    
    var message: String {
        switch self {
        case .noVariableTypeAnnotation(let variableName):
            return "Для добавления методов get и set необходимо указать тип переменной \(variableName)"
        case .invalidType:
            return "Макрос @Actor может быть применен только к классу или структуре"
        case .invalidVariable(let variableName):
            return "Ошибка при обработке \(variableName)"
        }
    }
    
    var diagnosticID: SwiftDiagnostics.MessageID {
        switch self {
        case .noVariableTypeAnnotation:
            MessageID(domain: Domain, id: "no_type_annotation")
        case .invalidType:
            MessageID(domain: Domain, id: "invalid_type")
        case .invalidVariable:
            MessageID(domain: Domain, id: "invalid_variable")
        }
    }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
        case .noVariableTypeAnnotation, .invalidVariable:  return .warning
        case .invalidType: return .error
        }
    }
}
