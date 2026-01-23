class VelociraptorSetup < Formula
  desc "Automated deployment scripts for Velociraptor DFIR framework on macOS"
  homepage "https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts"
  license "MIT"
  version "5.0.5"

  # Use head for development installation (no SHA256 required)
  head "https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts.git", branch: "main"

  # For stable releases, uncomment and update SHA256 after creating a GitHub release:
  # url "https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/archive/refs/tags/v5.0.5.tar.gz"
  # sha256 "REPLACE_WITH_ACTUAL_SHA256_AFTER_RELEASE"

  depends_on "jq"
  depends_on "curl"
  depends_on xcode: ["15.0", :build] if build.with?("gui")

  option "with-gui", "Build and install the native macOS GUI application"

  ##
  # Installs Velociraptor setup artifacts into the Homebrew prefix.
  # Places the main deploy script and optional helper scripts in `bin`, configuration templates into `share/velociraptor-setup`,
  # and README/Markdown documentation into `share/doc/velociraptor-setup`. If built with the "gui" option and a `VelociraptorMacOS`
  # directory exists, compiles the native macOS GUI in release mode without installing the application bundle.
  def install
    # Install the main deployment script
    bin.install "deploy-velociraptor-standalone.sh" => "velociraptor-deploy"
    
    # Install additional scripts
    bin.install "scripts/velociraptor-cleanup.sh" => "velociraptor-cleanup" if File.exist?("scripts/velociraptor-cleanup.sh")
    bin.install "scripts/velociraptor-health.sh" => "velociraptor-health" if File.exist?("scripts/velociraptor-health.sh")
    
    # Install configuration templates
    (share/"velociraptor-setup").install "templates" if Dir.exist?("templates")
    
    # Install documentation
    (share/"doc/velociraptor-setup").install "README.md"
    (share/"doc/velociraptor-setup").install Dir["*.md"]
    
    # Build and install the native macOS GUI if requested
    if build.with?("gui") && Dir.exist?("VelociraptorMacOS")
      cd "VelociraptorMacOS" do
        system "swift", "build", "-c", "release"
        # The binary would be installed to Applications
        # For now, just build it
      end
    end
  end

  ##
  # Ensure runtime directories for Velociraptor exist under var.
  # Creates `var/log/velociraptor` and `var/lib/velociraptor` if they do not already exist.
  def post_install
    # Create necessary directories
    (var/"log/velociraptor").mkpath
    (var/"lib/velociraptor").mkpath
  end

  service do
    run [opt_bin/"velociraptor-deploy", "--service-mode"]
    keep_alive true
    log_path var/"log/velociraptor/velociraptor.log"
    error_log_path var/"log/velociraptor/velociraptor.error.log"
  end

  test do
    # Test that the script can be executed
    system "#{bin}/velociraptor-deploy", "--help"
  end

  ##
  # Provide post-installation caveats shown to the user, including install commands, configuration/log/data paths, and optional GUI notes when built with the "gui" option.
  # @return [String] The formatted caveats text displayed to the user after installation; includes an additional native macOS GUI section when the formula was built with the "gui" option.
  def caveats
    caveats_text = <<~EOS
      Velociraptor Setup Scripts have been installed.
      
      To deploy Velociraptor standalone:
        velociraptor-deploy
      
      To check system health:
        velociraptor-health
      
      To cleanup installation:
        velociraptor-cleanup
      
      Configuration files are located at:
        #{share}/velociraptor-setup/
      
      Logs are written to:
        ~/Library/Logs/Velociraptor/
      
      Data is stored at:
        ~/Library/Application Support/Velociraptor/
      
      For more information, see:
        #{share}/doc/velociraptor-setup/README.md
    EOS

    if build.with?("gui")
      caveats_text += <<~EOS
        
        Native macOS GUI Application:
          The Velociraptor macOS GUI has been built. You can find it in
          the build output directory. For full GUI installation, use the
          Velociraptor.app bundle or build with Xcode.
      EOS
    end

    caveats_text
  end
end