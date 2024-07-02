//
//  MacroTesting.swift
//
//
//  Created by Анастасия Ищенко on 13.03.2024.
//

import MacroTesting
import SwiftSyntaxMacros
import ActorMacroMacros
import XCTest

final class MacroTesting: XCTestCase {
    
    override func invokeTest() {
        withMacroTesting(
            // чтобы diagnostics и expansion генерировались всегда заново
            // стоит учесть, что если isRecording: true, то тесты будут всегда фейлиться
            isRecording: true,
            macros: testMacros
        ) {
            super.invokeTest()
        }
    }
    
    func testMacro() throws {
        // если при запуске тестов возникли проблемы с отступами, стоит установить indentationWidth в соответствующее вашим отступам значение
        assertMacro(indentationWidth: .spaces(4)) { """
            @Actor(.public_)
            class SmallTestClass {
                
                let strLet: String
                var strVar = "str2"
                
                var strGet: String {
                    get {
                        "strGet"
                    }
                }
                
                init(strLet: String, strVar: String) {
                    self.strLet = strLet
                    self.strVar = strVar
                }
                
                func funcForTest() {
                    if strVar.isEmpty {
                        print("strVar is empty")
                    } else {
                        print("strVar is not empty")
                    }
                }
            }
            """
        } diagnostics: {
            """
            @Actor(.public_)
            class SmallTestClass {
                
                let strLet: String
                var strVar = "str2"
                ╰─ ⚠️ Для добавления методов get и set необходимо указать тип переменной strVar
                
                var strGet: String {
                    get {
                        "strGet"
                    }
                }
                
                init(strLet: String, strVar: String) {
                    self.strLet = strLet
                    self.strVar = strVar
                }
                
                func funcForTest() {
                    if strVar.isEmpty {
                        print("strVar is empty")
                    } else {
                        print("strVar is not empty")
                    }
                }
            }
            """
        } expansion: {
            """
            class SmallTestClass {
                
                let strLet: String
                var strVar = "str2"
                
                var strGet: String {
                    get {
                        "strGet"
                    }
                }
                
                init(strLet: String, strVar: String) {
                    self.strLet = strLet
                    self.strVar = strVar
                }
                
                func funcForTest() {
                    if strVar.isEmpty {
                        print("strVar is empty")
                    } else {
                        print("strVar is not empty")
                    }
                }
            }

            public actor SmallTestClassActor {

                private let strLet: String
                func getStrLet() -> String {
                    return strLet
                }

                private var strVar = "str2"

                private var strGet: String {
                    get {
                        "strGet"
                    }
                }
                func getStrGet() -> String {
                    return strGet
                }

                init(strLet: String, strVar: String) {
                    self.strLet = strLet
                    self.strVar = strVar
                }

                func funcForTest() {
                    if strVar.isEmpty {
                        print("strVar is empty")
                    } else {
                        print("strVar is not empty")
                    }
                }
            }
            """
        }
    }
}

