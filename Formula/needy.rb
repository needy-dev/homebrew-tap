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
    url "https://github.com/needy-dev/needy/releases/download/v0.0.23/needy-aarch64-apple-darwin.tar.gz"
    sha256 "f8acc41989bfa979ffa29f85c04b76f20388736a4778ec776956be43adf5e04b"
  elsif Hardware::CPU.intel?
    url "https://github.com/needy-dev/needy/releases/download/v0.0.23/needy-x86_64-apple-darwin.tar.gz"
    sha256 "ff9d9fb1d6e830b9501c3890a8d3a65d344bec8be2b1b44581ac890f2eee7b65"
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
    assert_equal "needy 0.0.23", shell_output("#{bin}/needy --version").strip
  end
end
