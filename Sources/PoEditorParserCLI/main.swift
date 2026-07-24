import Commander
import Foundation
import PoEditorParser
import Rainbow

let POEditorAPIURL = "https://api.poeditor.com/v2"

let main = Group {
    $0.command(
        "download",
        Option<String>("apitoken", default: "", description: "The POEditor API token"),
        Option<Int>("projectid", default: 0, description: "The id of the project in POEditor"),
        Option<String>("language", default: "en", description: "The preferred language code in POEditor"),
        Option<String>("out", default: "Localizable.xcstrings", description: "Output .xcstrings file path"),
        description: "Download a String Catalog (all languages) from POEditor."
    ) { token, id, language, out in
        try Program().download(
            token: token,
            id: id,
            language: language,
            out: out,
            poEditorApiUrl: POEditorAPIURL
        )
    }

    $0.command(
        "generate",
        Option<String>("in", default: "Localizable.xcstrings", description: "Input .xcstrings file path"),
        Option<String>("swiftfile", default: "Sources/Literals.swift", description: "Output Swift file path"),
        Option<String>("typename", default: "Literals", description: "Type name that stores all localized vars"),
        Option<String?>("tablename", default: nil, description: "The tableName value for NSLocalizedString"),
        Option<OutputFormat>("outputformat", default: .struct, description: "Swift output format (enum or struct)"),
        Option<KeysFormat>("keysformat", default: .upperCamelCase, description: "The format for the localized key"),
        Option<String?>("language", default: nil, description: "Preferred language to source values from"),
        description: "Generate the Swift literals file from a local .xcstrings."
    ) { input, swiftFile, typeName, tableName, outputFormat, keysFormat, language in
        try Program().generate(
            input: input,
            swiftFile: swiftFile,
            typeName: typeName,
            tableName: tableName,
            outputFormat: outputFormat,
            keysFormat: keysFormat,
            language: language
        )
    }

    $0.command(
        "distribute",
        Option<String>("in", default: "Localizable.xcstrings", description: "Input multi-variant .xcstrings file path"),
        Option<String>("out", default: "Localizable.xcstrings", description: "Output single-variant .xcstrings file path"),
        Option<String>("variant", default: "", description: "The variant to extract (key[variant] suffix)"),
        description: "Split a multi-variant .xcstrings into a single-variant one."
    ) { input, out, variant in
        try Program().distribute(input: input, out: out, variant: variant)
    }

    $0.command(
        "filter",
        Option<String>("baseline", default: "", description: "Baseline .xcstrings (e.g. HEAD contents)"),
        Option<String>("working", default: "", description: "Working-tree .xcstrings"),
        Option<String>("out", default: "", description: "Output .xcstrings file path (defaults to --working)"),
        Option<String>("keys", default: "", description: "Comma-separated key patterns (* and ? wildcards)"),
        description: "Keep only matching-key changes between baseline and working; rest falls back to baseline."
    ) { baseline, working, out, keys in
        try Program().filter(
            baseline: baseline,
            working: working,
            out: out.isEmpty ? working : out,
            keys: keys.split(separator: ",").map(String.init)
        )
    }

    $0.command(
        "remove",
        Option<String>("in", default: "Localizable.xcstrings", description: "Input .xcstrings file path"),
        Option<String>("out", default: "", description: "Output .xcstrings file path (defaults to --in)"),
        Option<String>("keys", default: "", description: "Comma-separated key patterns (* and ? wildcards)"),
        Flag("dryrun", default: false, description: "Only print the keys that would be removed"),
        description: "Remove every key matching the given patterns."
    ) { input, out, keys, dryRun in
        try Program().remove(
            input: input,
            out: out.isEmpty ? input : out,
            keys: keys.split(separator: ",").map(String.init),
            dryRun: dryRun
        )
    }
}

main.run()
