cask "quicklaunch" do
  version "1.0.3"
  sha256 "4b2f406486225fd58a580f532726534658834175fddae1a73765e2982ba7884c"

  url "https://github.com/vorojar/QuickLaunch/releases/download/v#{version}/QuickLaunch-v#{version}.dmg"
  name "QuickLaunch"
  desc "Fast app launcher for macOS"
  homepage "https://github.com/vorojar/QuickLaunch"

  depends_on macos: ">= :sonoma"

  app "QuickLaunch.app"

  zap trash: [
    "~/Library/Application Support/QuickLaunch",
  ]
end
