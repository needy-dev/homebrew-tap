class Needy < Formula
  desc "Separate the program that drives work from the environments where it runs"
  homepage "https://github.com/needy-dev/needy"
  license "AGPL-3.0-only"

  # TODO(homebrew-linux): Linuxbrew is deferred until both Linux artifacts have
  # tap-side installation evidence and an owner-approved support slice.
  depends_on :macos

  # NOTICE: Homebrew loads tap formulae under Linux architecture contexts
  # during validation. Select the archive by CPU here; the macOS requirement
  # rejects Linux installation before it can use this URL.
  if Hardware::CPU.arm?
    url "https://github.com/needy-dev/needy/releases/download/v0.0.26/needy-aarch64-apple-darwin.tar.gz"
    sha256 "835c5b2bcdeadf4e8adeb43cd8fdf746c56f3f01f26993ada33cf84cafcc574d"
  elsif Hardware::CPU.intel?
    url "https://github.com/needy-dev/needy/releases/download/v0.0.26/needy-x86_64-apple-darwin.tar.gz"
    sha256 "a80a7b15cc2a94c6ec2e698613e69a98aa90e936a616813f7c9bb5ee4b21359c"
  end

  # NOTICE: Homebrew's cleaner makes every file it does not recognise as an
  # executable (a Linux ELF on macOS) read-only, 0444; actors must be able to
  # execute the guest needy, so keep the mode the archive gives it.
  skip_clean "bin/needy-linux-aarch64"

  def install
    bin.install "needy"
    # The arm64 archive also carries the guest needy, a static Linux binary
    # that actors on this Mac run; needy looks for it next to itself.
    bin.install "needy-linux-aarch64" if File.exist?("needy-linux-aarch64")
  end

  # NOTICE(homebrew-service): no `service do` block. brew services would run
  # a second launchd job beside needy's own (`dev.needy.control`), without
  # AbandonProcessGroup, so stopping it would kill the actors a run still
  # owns. post_install cannot start needy's service either: it runs in
  # Homebrew's sandbox, which denies ~/Library/LaunchAgents. The caveats name
  # the command instead; the install script runs it itself.
  # Source: https://github.com/Homebrew/brew/blob/785949e709ce098f2182182afcdc90e3060809ca/Library/Homebrew/formula_installer.rb#L1533-L1555
  # Reference: https://docs.brew.sh/Formula-Cookbook#service-files
  def caveats
    <<~EOS
      To start the needy control daemon now and at login:
        needy daemon service install --now
      After upgrading needy, restart the daemon on the new version:
        needy daemon service install --replace --now
    EOS
  end

  test do
    assert_equal "needy 0.0.26", shell_output("#{bin}/needy --version").strip
  end
end
