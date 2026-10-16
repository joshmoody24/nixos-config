# Every machine this repo knows about. The flake builds each one's
# configuration from this list, and the Ubuntu scripts ask it which machine
# they are running on, so the hostname is spelled once.
{
  framework = { hostname = "joshm-framework"; os = "ubuntu"; };
  thinkpad = { hostname = "joshm-thinkpad"; os = "ubuntu"; };
  unit = { hostname = "unit"; os = "nixos"; };
}
