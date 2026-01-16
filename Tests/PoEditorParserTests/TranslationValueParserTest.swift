import Foundation
@testable import PoEditorParser
import Testing

@Test
func testBasicVariables() throws {
    // Given
    let translationValue = "Hello {{name}}, welcome to {{appName}}!"
    let term = "welcome_message"

    // When
    let (localizedString, variables) = try TranslationValueParser.parseTranslationValue(
        term: term,
        translationValue: translationValue
    )

    // Then
    #expect(localizedString == "Hello {{name}}, welcome to {{appName}}!")
    #expect(variables.count == 2)
    #expect(variables[0].parameterKey == "name")
    #expect(variables[1].parameterKey == "appName")
}

@Test
func testDuplicateVariables() throws {
    // Given
    let translationValue = "Welcome to {{brandName}} - {{brandName}} is awesome!"
    let term = "duplicate_brand"

    // When
    let (localizedString, variables) = try TranslationValueParser.parseTranslationValue(
        term: term,
        translationValue: translationValue
    )

    // Then
    #expect(localizedString == "Welcome to {{brandName}} - {{brandName}} is awesome!")
    #expect(variables.count == 1, "Should only have one variable despite appearing twice")
    #expect(variables[0].parameterKey == "brandName")
}

@Test
func testMultipleDuplicateVariables() throws {
    // Given
    let translationValue = "{{var1}} and {{var2}} and {{var1}} and {{var2}} again"
    let term = "multiple_duplicates"

    // When
    let (localizedString, variables) = try TranslationValueParser.parseTranslationValue(
        term: term,
        translationValue: translationValue
    )

    // Then
    #expect(localizedString == "{{var1}} and {{var2}} and {{var1}} and {{var2}} again")
    #expect(variables.count == 2, "Should have two unique variables despite each appearing twice")
    #expect(variables[0].parameterKey == "var1")
    #expect(variables[1].parameterKey == "var2")
}

@Test
func testVariableOrder() throws {
    // Given
    let translationValue = "{{var2}} comes before {{var1}} but {{var2}} appears again"
    let term = "variable_order"

    // When
    let (_, variables) = try TranslationValueParser.parseTranslationValue(
        term: term,
        translationValue: translationValue
    )

    // Then
    #expect(variables.count == 2)
    #expect(variables[0].parameterKey == "var2", "First occurrence should determine order")
    #expect(variables[1].parameterKey == "var1")
}

@Test
func testNumericVariableType() throws {
    // Given
    let translationValue = "You have {{number}} items"
    let term = "numeric_variable"

    // When
    let (_, variables) = try TranslationValueParser.parseTranslationValue(
        term: term,
        translationValue: translationValue
    )

    // Then
    #expect(variables.count == 1)
    #expect(variables[0].type == .numeric, "Variable containing 'number' should be treated as numeric")
}

@Test
func testComplexCase() throws {
    // Given
    let translationValue = "{{user}} has {{number}} items in {{user}}'s cart at {{brandName}} and {{brandName}} store"
    let term = "complex_case"

    // When
    let (localizedString, variables) = try TranslationValueParser.parseTranslationValue(
        term: term,
        translationValue: translationValue
    )

    // Then
    #expect(localizedString == "{{user}} has {{number}} items in {{user}}'s cart at {{brandName}} and {{brandName}} store")
    #expect(variables.count == 3, "Should have 3 unique variables despite duplicates")
    #expect(variables.map { $0.parameterKey } == ["user", "number", "brandName"])
}

@Test
func testMalformedVariable() throws {
    // Given
    let translationValue = "This has a malformed variable {{incomplete"
    let term = "malformed"

    // Then
    do {
        _ = try TranslationValueParser.parseTranslationValue(
            term: term,
            translationValue: translationValue
        )
    } catch let thrownError {
        #expect(thrownError is AppError)
        if case let AppError.misspelledTerm(termName, _) = thrownError {
            #expect(termName == "malformed")
        } else {
            #expect(Bool(false))
        }
    }
}
