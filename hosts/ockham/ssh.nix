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
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD2ObbPPF9YrQIUZKOSEnk8I065XefLyOa3jpsLDtxOrZYoS9wtXjv/0z9w4BWnZpznLM8oDGG5pQUtmXSxM3kGirY1W6ewNJjUMCScU+ef9ts/Sumdu+gzHFdwGkGVgZZQqYZFWatiByz+Z3CnY9CrmnE86uLlMYqEos8lLr3+StV53pqla6kh/aSR+CAc0Erl4/TR6ko0bC01QCKbgumwQtGOTwBOaocsTR9Y1QpF7Z/OwT2wyvGtUSpE8bAf/Ky238Ah6WivutyBEVUmXDQEFOorFj6d8GOqsDkdsR39+VwMH7UK9LnlTsQQvvAhB2sj6LscGjGQgBnrE+PnUn59ESMheUv3YJAQRPufwrVcKB7P6JJouJnp4E+WDdyIHvBdbKsfZnON1XbQ8FPo3uyPz6Uck5ctHL6eI12vAHEsb1j/8TTzvs1nDcJT+b5jruGdVRkD0B7KLLiJxPmqcWJ7nSItKyZCvLzcGMPbXWndWWQqg/f4VsJ/ohVdB9Zv5A/mmhJsB4mzoSaqxT0Qs2IhSikpwLHKIvCH2FnLmK6UiRDhU8vd2hZR/n5YuKEWkj0cTyODBQaGE7gMDf8eCr8cbRRsnjxrvf3sSIOJWWS+saAa4yXjpMjO8JCU/+8bWNVgSyI3xHevYDvH1oLUuGObPikPtT4UvxCrxXR05AMfVw== gob@corvid.com"
    ];
  };
}
