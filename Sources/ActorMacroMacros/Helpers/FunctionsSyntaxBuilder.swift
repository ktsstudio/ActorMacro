//
//  FunctionsSyntaxBuilder.swift
//  
//
//  Created by Анастасия Ищенко on 07.02.2024.
//

import SwiftSyntax

final class FunctionsSyntaxBuilder: DiagnosticCapableBase {
    
    func buildSetGetFuncs(for variable: VariableDeclSyntax) throws -> [MemberBlockItemSyntax] {
        guard let variableName =  variable.bindings.as(PatternBindingListSyntax.self)?.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            try showDiagnostic(
                ActorMacroError.invalidVariable("?unknown_variable_name?"),
                position: variable.positionAfterSkippingLeadingTrivia
            )
            return []
        }
        
        guard let variableType = variable.bindings.first?.typeAnnotation?.type else {
            try showDiagnostic(
                ActorMacroError.noVariableTypeAnnotation(variableName),
                position: variable.positionAfterSkippingLeadingTrivia
            )
            return []
        }
        
        var resultFuncs: [MemberBlockItemSyntax] = []
        if let getterForVariable = try buildGetFunc(
            variableName: variableName,
            variableType: variableType
        ) {
            resultFuncs.append(MemberBlockItemSyntax(decl: getterForVariable))
        }
        if SyntaxHelper.shouldCreateSetFunc(for: variable), // фнкция set добавляется только к изменяемым stored property
           let setterForVariable = try buildSetFunc(
            variableName: variableName,
            variableType: variableType
           ) {
            resultFuncs.append(MemberBlockItemSyntax(decl: setterForVariable))
        }
        return resultFuncs
    }
    
    private func buildGetFunc(
        variableName: String,
        variableType: TypeSyntax
    ) throws -> FunctionDeclSyntax? {
        FunctionDeclSyntax(
            leadingTrivia: .newline,
            // эквивалентные строки:
//            funcKeyword: .init(stringInterpolation: "func"),
            funcKeyword: .keyword(.func),
            name: TokenSyntax(stringLiteral: "get\(StringsHelper.capitalizingFirstLetter(variableName))"),
            // доделать дженерики?
//            genericParameterClause: GenericParameterClauseSyntax?,
            signature: funcSignature(parameters: [], returnType: variableType),
            body: createGetFuncBody(variableName)
        )
    }
    
    private func buildSetFunc(
        variableName: String,
        variableType: TypeSyntax
    ) throws -> FunctionDeclSyntax? {
        guard let variableTypeStr = variableType.as(IdentifierTypeSyntax.self)?.name.text else {
            return nil
        }
        
        return FunctionDeclSyntax(
            leadingTrivia: .newline,
//            funcKeyword: .init(stringInterpolation: "func"),
            funcKeyword: .keyword(.func),
            name: TokenSyntax(stringLiteral: "set\(StringsHelper.capitalizingFirstLetter(variableName))"),
//            genericParameterClause: GenericParameterClauseSyntax?,
            signature: funcSignature(
                parameters: [(variableName, variableTypeStr, true)],
                returnType: nil
            ),
            body: createSetFuncBody([(variableName, variableTypeStr)])
        )
    }
    
    func buidInit(variables: [VariableDeclSyntax]) -> InitializerDeclSyntax {
        var parameters: [FunctionParameter] = []

        variables.forEach { variable in
            if variable.isStoredProperty,
                let patternBinding = variable.bindings.as(PatternBindingListSyntax.self)?.first,
               // переменной не задано значение по умолчанию
               patternBinding.initializer == nil,
               let variableName =  patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
               let variableType = patternBinding.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text {
                parameters.append((variableName, variableType, false))
            }
        }
        
        let funcBodyParams: [FunctionBodyParameter] = parameters.compactMap {
            FunctionBodyParameter($0.0, $0.1)
        }
        
        return InitializerDeclSyntax(
            leadingTrivia: .newlines(2),
            initKeyword: TokenSyntax(stringLiteral: "init"),
            signature: funcSignature(parameters: parameters, returnType: nil),
            body: createSetFuncBody(funcBodyParams)
        )
    }
    
    private func createGetFuncBody(_ variableName: String) -> CodeBlockSyntax {
        CodeBlockSyntax.init(statements: .init(arrayLiteral: "return \(raw: variableName)"))
    }
    
    private func funcSignature(
        parameters: [FunctionParameter],
        returnType: TypeSyntax?
    ) -> FunctionSignatureSyntax {
        if let returnType {
            return FunctionSignatureSyntax(
                parameterClause: .init(parameters: createFunctionParameterList(parameters)),
                returnClause: ReturnClauseSyntax(type: returnType)
            )
        } else {
            return FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(parameters: createFunctionParameterList(parameters))
            )
        }
    }
    
    private func createFunctionParameterList(_ parameters: [FunctionParameter]) -> FunctionParameterListSyntax {
        var functionParameters: [FunctionParameterSyntax] = []
        parameters.enumerated().forEach {
            functionParameters.append(
                createFunctionParameter($1, isLast: $0 == parameters.count - 1)
            )
        }
        // создание списка параметров функции из отдельных параметров
        return FunctionParameterListSyntax.init(functionParameters)
    }
    
    private func createFunctionParameter(_ parameter: FunctionParameter, isLast: Bool) -> FunctionParameterSyntax {
        // создание одного параметра для функции
        return FunctionParameterSyntax(
            firstName: parameter.ignoreName ? .wildcardToken() : TokenSyntax(stringLiteral: "\(parameter.name)"), // нижнее подчеркивание, чтобы при вызове функции параметор можно было игнорировать. В случае, если у параметра нет двух имен, то имя параметра указывается в этом поле, а не следующем
            secondName: parameter.ignoreName ? TokenSyntax(stringLiteral: "\(parameter.name)") : nil,
            colon: .colonToken(),
            type: IdentifierTypeSyntax.init(name: .init(stringLiteral: parameter.type)),
            trailingComma: isLast ? nil : .commaToken()
        )
    }
    
    private func createSetFuncBody(_ functionParameters: [FunctionBodyParameter]) -> CodeBlockSyntax {
        var statements: [CodeBlockItemSyntax] = []
        
        functionParameters.forEach { functionParameter in
            statements.append(
                CodeBlockItemSyntax(stringLiteral:  "self.\(functionParameter.name) = \(functionParameter.name)")
            )
        }
        return CodeBlockSyntax.init(statements: CodeBlockItemListSyntax(statements))
    }
}
