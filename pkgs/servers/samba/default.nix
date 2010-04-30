{ stdenv, fetchurl, readline, pam, openldap, popt, iniparser, libunwind, fam
, acl
, useKerberos ? false, kerberos ? null

# Eg. smbclient and smbspool require a smb.conf file.
# If you set configDir to "" an empty configuration file
# $out/lib/smb.conf is is created for you.
#
# configDir defaults to "/etc/samba" so that smbpassword picks up
# the location of its passwd db files from the system configuration file
# /etc/samba/smb.conf. That's why nixos touches /etc/samba/smb.conf even if you
# don't enable the samba upstart service.
, configDir ? "/etc/samba"
}:

stdenv.mkDerivation rec {
  name = "samba-3.5.2";

  src = fetchurl {
    url = "http://us3.samba.org/samba/ftp/stable/${name}.tar.gz";
    sha256 = "0pi946lyn57larvada77pkal48hc0rn07bjxpg2ahz0c389cknl2";
  };

  buildInputs = [readline pam openldap popt iniparser libunwind fam acl]
    ++ stdenv.lib.optional useKerberos kerberos;

  preConfigure = "cd source3";

  postInstall = ''
    mkdir -pv $out/lib/cups/backend
    ln -sv ../../../bin/smbspool $out/lib/cups/backend/smb
  '' + stdenv.lib.optionalString (configDir == "") "touch $out/lib/smb.conf";


  # Don't pass --with-private-dir=/var/samba/private
  #            --with-lockdir=/var/samba/lock
  # the build system will try to create it.
  configureFlags = ''
    --with-pam
    --with-cifsmount
    --with-aio-support
    --with-pam_smbpass
    --disable-swat
    --enable-shared-libs
    --with-configdir=${configDir}
    ${if stdenv.gcc.libc != null then "--with-libiconv=${stdenv.gcc.libc}" else ""}
  '';
}
