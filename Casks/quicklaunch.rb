cask "quicklaunch" do
  version "1.0.6"
  sha256 "31d7d75c5663b04d51a991aaa5270a332d5adcff766e920f7b0f3253b0e02411"

  url "https://github.com/vorojar/QuickLaunch/releases/download/v#{version}/QuickLaunch-v#{version}.dmg"
  name "QuickLaunch"
  desc "Fast app launcher"
  homepage "https://github.com/vorojar/QuickLaunch"

  depends_on macos: ">= :sonoma"

  app "QuickLaunch.app"

  zap trash: "~/Library/Application Support/QuickLaunch"
end
