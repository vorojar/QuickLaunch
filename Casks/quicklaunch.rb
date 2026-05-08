cask "quicklaunch" do
  version "1.0.4"
  sha256 "cfa943911dec01ec68bcc6a3c7285693651a7f3d2dc4024bc3f7ad0088df1431"

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
