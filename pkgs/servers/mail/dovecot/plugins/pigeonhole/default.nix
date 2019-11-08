{ stdenv, fetchurl, fetchpatch, dovecot, openssl }:

stdenv.mkDerivation rec {
  pname = "dovecot-pigeonhole";
  version = "0.5.8";

  src = fetchurl {
    url = "https://pigeonhole.dovecot.org/releases/2.3/dovecot-2.3-pigeonhole-${version}.tar.gz";
    sha256 = "08lhfl877xm790f1mqdhvz74xqr2kkl8wpz2m6p0j6hv1kan1f4g";
  };

  buildInputs = [ dovecot openssl ];

  preConfigure = ''
    substituteInPlace src/managesieve/managesieve-settings.c --replace \
      ".executable = \"managesieve\"" \
      ".executable = \"$out/libexec/dovecot/managesieve\""
    substituteInPlace src/managesieve-login/managesieve-login-settings.c --replace \
      ".executable = \"managesieve-login\"" \
      ".executable = \"$out/libexec/dovecot/managesieve-login\""
  '';

  configureFlags = [
    "--with-dovecot=${dovecot}/lib/dovecot"
    "--without-dovecot-install-dirs"
    "--with-moduledir=$(out)/lib/dovecot"
  ];

  patches = [
    (fetchpatch {
      url = "https://github.com/dovecot/pigeonhole/commit/3defbec146e195edad336a2c218f108462b0abd7.diff";
      sha256 = "09mvdw8gjzq9s2l759dz4aj9man8q1akvllsq2j1xa2qmwjfxarp";
      stripLen = 1;
    })
  ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    homepage = http://pigeonhole.dovecot.org/;
    description = "A sieve plugin for the Dovecot IMAP server";
    license = licenses.lgpl21;
    maintainers = with maintainers; [ rickynils globin ];
    platforms = platforms.unix;
  };
}
