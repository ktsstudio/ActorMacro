//
//  SyntaxBuilder.swift
//
//
//  Created by Анастасия Ищенко on 07.02.2024.
//

import SwiftSyntax
import SwiftSyntaxMacros

final class SyntaxBuilder: DiagnosticCapableBase {
    
    private lazy var functionsBuilder = FunctionsSyntaxBuilder(
        node: node,
        context: context
    )
    
    func buildActor(
        from classSyntax: ClassDeclSyntax,
        with modifier: DeclModifierSyntax?
    ) throws -> ActorDeclSyntax {
        let className = classSyntax.name
        // все члены класса
        let members = classSyntax.memberBlock.members
        
        // преобразование DeclModifierSyntax в DeclModifierListSyntax -  необходимо для инициализатора ActorDeclSyntax
        var modifiers = classSyntax.modifiers
        // если модификатор доступа не установлен пользователем, то используем модификатор доступа класса, к которому присоединен макрос
        if let modifier {
            modifiers = DeclModifierListSyntax(arrayLiteral: modifier)
        }
        
        return ActorDeclSyntax(
            modifiers: modifiers, // наш модификатор доступа
            actorKeyword: .keyword(.actor), // влючевое слово actor перед названием актора
            name: TokenSyntax(stringLiteral: "\(className.text)Actor"), // название актора
            genericParameterClause: classSyntax.genericParameterClause, // если родительский класс был дженериком, то актор тоже будет
            inheritanceClause: classSyntax.inheritanceClause, // наследование, подписка на протоколы
            genericWhereClause: classSyntax.genericWhereClause, // условие whwrw для дженерика
            memberBlock: try extractMembers(members) // измененные члены класса
        )
    }
    
    func buildActor(
        from structSyntax: StructDeclSyntax,
        with modifier: DeclModifierSyntax?
    ) throws -> ActorDeclSyntax {
        let structName = structSyntax.name
        let members = structSyntax.memberBlock.members
        
        var modifiers = structSyntax.modifiers
        if let modifier {
            modifiers = DeclModifierListSyntax(arrayLiteral: modifier)
        }
        
        return ActorDeclSyntax(
            modifiers: modifiers,
            actorKeyword: .keyword(.actor),
            name: TokenSyntax(stringLiteral: "\(structName.text)Actor"),
            genericParameterClause: structSyntax.genericParameterClause,
            inheritanceClause: structSyntax.inheritanceClause,
            genericWhereClause: structSyntax.genericWhereClause,
            memberBlock: try extractMembers(members)
        )
    }
    
    private func buildVariable(_ variable: VariableDeclSyntax) throws -> VariableDeclSyntax {
        /// При использовании готового синтаксиса кода, важно помнить про отступы.
        /// Важно следить, чтобы переменная не имела лишних отступов, например, при использовании код:
        ///        var editableVariable = variable
        ///        editableVariable.modifiers = .init(arrayLiteral: .init(name: .keyword(.private)))
        ///        editableVariable.leadingTrivia = .newlines(2)
        /// При входных данных:
        ///         let testStr: String
        /// Приведет к результату:
        ///         private
        ///                let testStr: String
        ///
        /// Корректный код:
        guard let decl = variable.as(DeclSyntax.self),
              var newVariable = VariableDeclSyntax(StringsHelper.removeLeadingTriviaFromDecl(decl))
        else {
            try showDiagnostic(
                ActorMacroError.invalidVariable(variable.bindings.as(PatternBindingListSyntax.self)?.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text ?? "?unknown variable name?"),
                position: variable.positionAfterSkippingLeadingTrivia
            )
            return variable
        }
        newVariable.modifiers = .init(arrayLiteral: .init(name: .keyword(.private)))
        newVariable.leadingTrivia = .newlines(2)
        newVariable.bindingSpecifier.leadingTrivia = .space
        
        return newVariable
        /// Результат:
        ///        private let testStr: String
//        return editableVariable
    }
    
    private func extractMembers(_ members: MemberBlockItemListSyntax) throws -> MemberBlockSyntax {
        var variables: [VariableDeclSyntax] = []
        var createdMemberBlockItems: [MemberBlockItemSyntax] = []
        var memberBlockItems: [MemberBlockItemSyntax] = []
         
        var hasInit = false
        try members.forEach { member in
            if member.decl.is(InitializerDeclSyntax.self) {
                hasInit = true
            }
            
            if let variable = member.decl.as(VariableDeclSyntax.self) {
                variables.append(variable)
                if !variable.isPrivate {
                    let resultVariable = try buildVariable(variable)
                    createdMemberBlockItems.append(MemberBlockItemSyntax(decl: resultVariable))
                    createdMemberBlockItems.append(contentsOf: try functionsBuilder.buildSetGetFuncs(for: variable))
                } else if let configuredMember = configureMember(member) {
                    createdMemberBlockItems.append(configuredMember)
                }
            } else if let configuredMember = configureMember(member) {
                memberBlockItems.append(configuredMember)
            }
        }
        
        // в случае, если у структуры нет инициализатора, генерируем простейший инициализатор
        if !hasInit {
            createdMemberBlockItems.append(MemberBlockItemSyntax(decl: functionsBuilder.buidInit(variables: variables)))
        }
        let resultMembers = createdMemberBlockItems + memberBlockItems
        
        return MemberBlockSyntax(members: MemberBlockItemListSyntax(resultMembers))
    }
    
    
    private func configureMember(
        _ member: MemberBlockItemSyntax
    ) -> MemberBlockItemSyntax? {
        MemberBlockItemSyntax(
            decl:  StringsHelper.removeLeadingTriviaFromDecl(member.decl)
        )
    }
}
