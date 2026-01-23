# Homebrew Cask for Velociraptor macOS GUI Application
# This is a Cask (for GUI apps), not a Formula (for CLI tools)
#
# To install:
#   brew tap Ununp3ntium115/velociraptor
#   brew install --cask velociraptor-gui
#
# Note: This file should be placed in a tap repository's Casks directory
#       e.g., homebrew-velociraptor/Casks/velociraptor-gui.rb

cask "velociraptor-gui" do
  version "5.0.5"
  sha256 :no_check  # Update with actual SHA256 after release
  
  url "https://github.com/Ununp3ntium115/Velociraptor_ClawEdition/releases/download/v#{version}/Velociraptor-#{version}.dmg"
  name "Velociraptor"
  desc "DFIR Framework for macOS - Configuration Wizard and Incident Response"
  homepage "https://github.com/Ununp3ntium115/Velociraptor_ClawEdition"
  
  # Require macOS 13.0 (Ventura) or later
  depends_on macos: ">= :ventura"
  
  app "Velociraptor.app"
  
  # Quarantine attribute removal (if needed for unsigned builds)
  # postflight do
  #   system_command "/usr/bin/xattr",
  #                  args: ["-r", "-d", "com.apple.quarantine", "#{appdir}/Velociraptor.app"],
  #                  sudo: false
  # end
  
  zap trash: [
    "~/Library/Application Support/Velociraptor",
    "~/Library/Caches/com.velocidex.velociraptor",
    "~/Library/Logs/Velociraptor",
    "~/Library/Preferences/com.velocidex.velociraptor.plist",
    "~/Library/Saved Application State/com.velocidex.velociraptor.savedState",
  ]
  
  caveats <<~EOS
    Velociraptor macOS GUI has been installed!
    
    To get started:
      1. Launch Velociraptor from Applications or Spotlight
      2. Follow the Configuration Wizard to set up Velociraptor
      3. Use Emergency Mode for rapid deployment during incidents
    
    For command-line deployment scripts, also install:
      brew install velociraptor-setup
    
    Documentation:
      https://github.com/Ununp3ntium115/Velociraptor_ClawEdition
    
    Note: You may need to allow the app in System Preferences > Security & Privacy
    if you see a Gatekeeper warning (for unsigned or notarized builds).
  EOS
end

# Alternative: Formula for building from source
# This is the source-build version that compiles the Swift app
class VelociraptorGuiBuild < Formula
  desc "Build Velociraptor macOS GUI from source"
  homepage "https://github.com/Ununp3ntium115/Velociraptor_ClawEdition"
  url "https://github.com/Ununp3ntium115/Velociraptor_ClawEdition/archive/refs/tags/v5.0.5.tar.gz"
  sha256 :no_check  # Update with actual SHA256
  license "AGPL-3.0"
  
  depends_on xcode: ["15.0", :build]
  depends_on macos: :ventura
  
  ##
  # Builds the Velociraptor macOS GUI from source and assembles a runnable .app bundle in the formula prefix.
  # Creates `Velociraptor.app` under the formula prefix, copies the built binary, `Info.plist`, and localization resources into the bundle, and performs an ad-hoc codesign. If `project.yml` is present, generates the Xcode project with XcodeGen before building.
  def install
    cd "VelociraptorMacOS" do
      # Install XcodeGen if project.yml exists
      if File.exist?("project.yml")
        system "brew", "install", "xcodegen" unless which("xcodegen")
        system "xcodegen", "generate"
      end
      
      # Build with Swift Package Manager
      system "swift", "build", "-c", "release",
             "-Xswiftc", "-O",
             "-Xswiftc", "-whole-module-optimization"
      
      # Create app bundle in prefix
      app_bundle = prefix/"Velociraptor.app"
      (app_bundle/"Contents/MacOS").mkpath
      (app_bundle/"Contents/Resources").mkpath
      
      # Copy binary
      cp ".build/release/VelociraptorMacOS", app_bundle/"Contents/MacOS/Velociraptor"
      
      # Copy Info.plist
      cp "VelociraptorMacOS/Info.plist", app_bundle/"Contents/"
      
      # Copy resources
      if File.directory?("VelociraptorMacOS/Resources/en.lproj")
        cp_r "VelociraptorMacOS/Resources/en.lproj", app_bundle/"Contents/Resources/"
      end
      
      # Ad-hoc sign
      system "codesign", "--force", "--deep", "--sign", "-", app_bundle
    end
  end
  
  ##
  # Notes and installation instructions shown to the user after building the app.
  #
  # The message includes the built app path, a copy command to install the app into /Applications,
  # and an alternative recommendation to install the pre-built cask.
  # @return [String] The caveats text containing the build location, installation command, and cask alternative.
  def caveats
    <<~EOS
      Velociraptor.app has been built at:
        #{prefix}/Velociraptor.app
      
      To install to Applications:
        cp -r #{prefix}/Velociraptor.app /Applications/
      
      Or use the pre-built Cask version:
        brew install --cask velociraptor-gui
    EOS
  end
  
  test do
    assert_predicate prefix/"Velociraptor.app/Contents/MacOS/Velociraptor", :exist?
  end
end