class VelociraptorSetup < Formula
  desc "Automated deployment scripts for Velociraptor DFIR framework on macOS"
  homepage "https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts"
  url "https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/archive/refs/tags/v5.0.1.tar.gz"
  sha256 "YOUR_SHA256_HERE" # This will need to be updated with actual SHA256
  license "MIT"
  version "5.0.1"

  depends_on "jq"
  depends_on "curl"

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
  end

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

  def caveats
    <<~EOS
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
  end
end