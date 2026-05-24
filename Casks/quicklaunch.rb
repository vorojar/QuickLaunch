cask "quicklaunch" do
  version "1.0.5"
  sha256 "028949fbfb2ff2a1ca1ac67b8ab73a5441515f410f3265ee4c9389bd9fe92324"

  url "https://github.com/vorojar/QuickLaunch/releases/download/v#{version}/QuickLaunch-v#{version}.dmg"
  name "QuickLaunch"
  desc "Fast app launcher"
  homepage "https://github.com/vorojar/QuickLaunch"

  depends_on macos: ">= :sonoma"

  app "QuickLaunch.app"

  zap trash: "~/Library/Application Support/QuickLaunch"
end
