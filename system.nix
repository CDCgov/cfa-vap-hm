{ pkgs, ... }:

let
  xrdpConf = pkgs.runCommand "xrdp-config" { } ''
    mkdir -p "$out"

    cp -r ${pkgs.xrdp}/etc/xrdp/* "$out/"
    chmod -R u+w "$out"

    # Equivalent to:
    #   echo xfce4-session > ~/.xsession
    #
    # but system-wide and declarative.
    cat > "$out/startwm.sh" <<'EOF'
    #!/bin/sh
    . /etc/profile
    exec ${pkgs.xfce4-session}/bin/xfce4-session
    EOF
    chmod +x "$out/startwm.sh"

    # Make sesman use our declarative window-manager script.
    substituteInPlace "$out/sesman.ini" \
      --replace-fail "startwm.sh" "$out/startwm.sh" \
      --replace-fail "reconnectwm.sh" "$out/reconnectwm.sh"

    # Use journald instead of mutable XRDP log files.
    substituteInPlace "$out/xrdp.ini" \
      --replace-fail "LogFile=xrdp.log" "LogFile=/dev/null" \
      --replace-fail "EnableSyslog=true" "EnableSyslog=false"

    substituteInPlace "$out/sesman.ini" \
      --replace-fail "LogFile=xrdp-sesman.log" "LogFile=/dev/null" \
      --replace-fail "EnableSyslog=true" "EnableSyslog=false"
  '';
in
{
  nixpkgs.hostPlatform = "x86_64-linux";

  # Nix equivalent of:
  #
  #   apt install xfce4 xfce4-session xrdp
  #
  environment.systemPackages = with pkgs; [
    xrdp

    xfce4-session
    xfwm4
    xfdesktop
    xfce4-panel
    xfce4-settings
    xfce4-appfinder
    xfce4-terminal
    thunar

    # Useful bits normally pulled in by a full distro XFCE installation.
    dbus
    shared-mime-info
    desktop-file-utils
    hicolor-icon-theme
    adwaita-icon-theme
  ];

  environment.pathsToLink = [
    "/share/xfce4"
    "/lib/xfce4"
    "/share/applications"
    "/share/icons"
    "/share/mime"
  ];

  # XRDP configuration generated above.
  environment.etc."xrdp".source = xrdpConf;

  # Ubuntu authentication stack for XRDP.
  #
  # This is the part `apt install xrdp` would normally install into
  # /etc/pam.d for us.
  environment.etc."pam.d/xrdp-sesman".text = ''
    #%PAM-1.0

    auth       required     pam_env.so readenv=1
    auth       required     pam_env.so readenv=1 envfile=/etc/default/locale

    @include common-auth
    @include common-account
    @include common-session
    @include common-password
  '';

  # Equivalent to systemctl enable xrdp.
  #
  # system-manager starts newly-added services and restarts changed
  # services during activation, so there is no declarative equivalent
  # of manually running `systemctl restart xrdp`.
  systemd.services.xrdp-sesman = {
    description = "xrdp session manager";

    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart =
        "${pkgs.xrdp}/bin/xrdp-sesman"
        + " --nodaemon"
        + " --config ${xrdpConf}/sesman.ini";

      ExecStop =
        "${pkgs.coreutils}/bin/kill -INT $MAINPID";
    };
  };

  systemd.services.xrdp = {
    description = "xrdp daemon";

    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "xrdp-sesman.service"
    ];
    requires = [ "xrdp-sesman.service" ];

    serviceConfig = {
      ExecStart =
        "${pkgs.xrdp}/bin/xrdp"
        + " --nodaemon"
        + " --port 3389"
        + " --config ${xrdpConf}/xrdp.ini";
    };
  };
}