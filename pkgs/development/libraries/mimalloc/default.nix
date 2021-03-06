{ stdenv, fetchFromGitHub, cmake
, secureBuild ? true
}:

let
  soext = stdenv.hostPlatform.extensions.sharedLibrary;
in
stdenv.mkDerivation rec {
  name    = "mimalloc-${version}";
  version = "1.0.8";

  src = fetchFromGitHub {
    owner  = "microsoft";
    repo   = "mimalloc";
    rev    = "refs/tags/v${version}";
    sha256 = "04k2d3x84q2jfqdjxngy98hlw6czmigsqlf7gi3mhs6682n127r5";
  };

  nativeBuildInputs = [ cmake ];
  enableParallelBuilding = true;

  cmakeFlags = stdenv.lib.optional secureBuild [ "-DMI_SECURE=ON" ];

  postInstall = ''
    mkdir -p $dev
    mv $out/lib/*/include $dev/include

    rm -f $out/lib/libmimalloc*${soext} # weird duplicate

    mv $out/lib/*/libmimalloc*${soext} $out/lib/libmimalloc${soext}
    mv $out/lib/*/libmimalloc*.a       $out/lib/libmimalloc.a
    mv $out/lib/*/mimalloc*.o          $out/lib/mimalloc.o

    rm -rf $out/lib/mimalloc-*
  '';

  outputs = [ "out" "dev" ];

  meta = with stdenv.lib; {
    description = "Compact, fast, general-purpose memory allocator";
    homepage    = "https://github.com/microsoft/mimalloc";
    license     = licenses.bsd2;
    platforms   = platforms.unix;
    maintainers = with maintainers; [ thoughtpolice ];
  };
}
