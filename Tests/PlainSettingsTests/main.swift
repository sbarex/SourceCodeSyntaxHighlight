import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}

let shellScriptRule = PlainSettings(
    patternFile: ".*",
    patternMime: "^text/x-shellscript$",
    isRegExp: true,
    isCaseInsensitive: true,
    UTI: "public.shell-script",
    syntax: "shellscript"
)

expect(
    shellScriptRule.test(filename: "hproxy", mimeType: "text/x-shellscript"),
    "MIME regex should use the complete MIME value for short filenames"
)
expect(
    shellScriptRule.test(
        filename: String(repeating: "extensionless-shell-script-", count: 4),
        mimeType: "text/x-shellscript"
    ),
    "MIME regex should not use an out-of-bounds filename-derived range"
)
expect(
    !shellScriptRule.test(filename: "script", mimeType: "text/x-python"),
    "MIME regex should reject a different MIME type"
)

print("PlainSettingsTests passed")
