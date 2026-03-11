cask "syntax-highlight" do
  version "2.1.27"
  sha256 "c902ef7d1422f43b97ae1352220d7feaafd6aceac29460a51c32bb3d8e15daeb"

  url "https://github.com/sbarex/SourceCodeSyntaxHighlight/releases/download/#{version}/Syntax.Highlight.zip"
  name "Syntax Highlight"
  desc "Quick Look extension for source files"
  homepage "https://github.com/sbarex/SourceCodeSyntaxHighlight"

  livecheck do
    url "https://sbarex.github.io/SourceCodeSyntaxHighlight/appcast.xml"
    strategy :sparkle do |items|
      items.map(&:short_version)
    end
  end

  auto_updates true
  depends_on macos: ">= :big_sur"

  app "Syntax Highlight.app"
  binary "#{appdir}/Syntax Highlight.app/Contents/Resources/syntax_highlight_cli"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-r", "-d", "com.apple.quarantine", "#{appdir}/Syntax Highlight.app"],
                   sudo: true
  end

  zap trash: [
    "~/Library/Application Scripts/org.sbarex.SourceCodeSyntaxHighlight",
    "~/Library/Application Scripts/org.sbarex.SourceCodeSyntaxHighlight.QuicklookExtension",
    "~/Library/Application Support/Syntax Highlight",
    "~/Library/Caches/com.apple.helpd/Generated/org.sbarex.SourceCodeSyntaxHighlight.help*",
    "~/Library/Containers/org.sbarex.SourceCodeSyntaxHighlight",
    "~/Library/Containers/org.sbarex.SourceCodeSyntaxHighlight.QuicklookExtension",
    "~/Library/Preferences/org.sbarex.SourceCodeSyntaxHighlight.plist",
  ]
end
