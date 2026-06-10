cask "quicklaunch" do
  version "1.0.7"
  sha256 "0b2cc654be9db5b96d0625d6f34800c5d596c2ec42428d4ef20dd4aa056eb6f8"

  url "https://github.com/vorojar/QuickLaunch/releases/download/v#{version}/QuickLaunch-v#{version}.dmg"
  name "QuickLaunch"
  desc "Fast app launcher"
  homepage "https://github.com/vorojar/QuickLaunch"

  depends_on macos: ">= :sonoma"

  app "QuickLaunch.app"

  zap trash: "~/Library/Application Support/QuickLaunch"
end
