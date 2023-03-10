{ lib, pkgs, fetchFromGitHub }:

pkgs.fishPlugins.buildFishPlugin rec {
  pname = "fish-ssh-agent";
  version = "unknown";

  src = fetchFromGitHub {
    owner = "danhper";
    repo = pname;
    rev = "fd70a2afdd03caf9bf609746bf6b993b9e83be57";
    sha256 = "1fvl23y9lylj4nz6k7yfja6v9jlsg8jffs2m5mq0ql4ja5vi5pkv";
  };

  meta = {
    description = "Fish plugin to automatically start ssh-agent";
    homepage = "https://github.com/danhper/fish-ssh-agent";
    maintainers = [ ];
  };
}

