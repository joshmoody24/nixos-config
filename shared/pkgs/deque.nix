{ lib, rustPlatform, fetchFromGitHub, git }:

rustPlatform.buildRustPackage rec {
  pname = "deque";
  version = "0.2.0-unstable-2026-09-29";

  src = fetchFromGitHub {
    owner = "booka66";
    repo = "deque";
    rev = "27db4a7c9019cab4af9f8fd340821b6c3747d810";
    hash = "sha256-CT8Ie9Ceprcb36I3cjpH0uYrCQBZEoH/cs+fF4yV2MA=";
  };

  cargoHash = "sha256-Qq7MN49xZ7Aw0JTnIVrIsEsV0zOHWxJ6DzYyo6kKc5M=";

  # One test renders a file's history, so it shells out to git.
  nativeCheckInputs = [ git ];

  meta = {
    description = "Slides in any terminal, from a text file";
    homepage = "https://github.com/booka66/deque";
    license = lib.licenses.mit;
    mainProgram = "deque";
  };
}
