{...}: {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  users.users = {
    xyven.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqKxEMH57VYdc6hCe25uBkok0KeArgwARqOs1Dw1UBu xyven@festus"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEq5E8HRvArWWc5F9+qI6AuU9Kh1CoJ8/lZ+jErnQAOC xyven@BLAKE-XPS17"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIOQXryC9EtogM+aJdeJV5OnZymb1g42xzxz0RUSeY4+ Xyven@xyvendesktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElMdQmM+B4cDLR1kbGkVqszB5VzvIzSinlxbUjlWTuO xyven@rilke"
    ];
    gob.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIC3+2FLIRDzLtuWvcq4k5YZpSBLmqnEqHXAA6RJlQcA gob@Woofwoof"
    ];
  };
}
