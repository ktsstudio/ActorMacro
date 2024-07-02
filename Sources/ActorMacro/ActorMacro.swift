
@attached(peer, names: suffixed(Actor))
public macro Actor(_ actorProtectionLevel: ProtectionLevel?) = #externalMacro(
    module: "ActorMacroMacros",
    type: "ActorMacro"
)
