import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct ActorMacro: PeerMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        let syntaxBuilder = SyntaxBuilder(node: node, context: context)
        let protectionLevel = ParametersMapper.mapProtectionLevel(
            node.arguments?.as(LabeledExprListSyntax.self)?.first
        )
        
        if let classSyntax = declaration.as(ClassDeclSyntax.self),
           let declSyntax = try syntaxBuilder.buildActor(
            from: classSyntax,
            with: protectionLevel
           ).as(DeclSyntax.self) {
            return [declSyntax]
        } else if let structSyntax = declaration.as(StructDeclSyntax.self),
                  let declSyntax = try syntaxBuilder.buildActor(
                    from: structSyntax,
                    with: protectionLevel
                  ).as(DeclSyntax.self) {
            return [declSyntax]
        } else {
            throw ActorMacroError.invalidType
        }
    }
}

@main
struct ActorMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ActorMacro.self,
    ]
}
