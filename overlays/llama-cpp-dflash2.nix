# llama-cpp-dflash2: the DFlash2 spec-decoding branch of llama.cpp.
#
# This overlay adds a `llama-cpp-dflash2` attribute built from ggml-org/llama.cpp
# PR #27342 ("spec : add DFlash2 support (local convolution + candidate
# selector)"). It coexists with the vanilla nixpkgs `llama-cpp` package, so you
# can install both at once:
#
#   environment.systemPackages = with pkgs; [
#     (llama-cpp.override { rpcSupport = true; })
#     (llama-cpp-dflash2.override { rpcSupport = true; cudaSupport = true; })
#   ];
#
# Why a dedicated derivation instead of `overrideAttrs` on nixpkgs' llama-cpp?
# The DFlash2 branch tracks a recent llama.cpp master whose CMake system has
# changed a lot from the nixpkgs-pinned b6981:
#   - The RPC server binary is `ggml-rpc-server` (was `rpc-server`).
#   - Tools moved from examples/ to tools/ (LLAMA_BUILD_TOOLS / LLAMA_BUILD_SERVER).
#   - The Web UI is provisioned by a CMake script that downloads assets from
#     HuggingFace or runs npm at configure time. We disable both so the build
#     stays hermetic (no network, no npm).
# We therefore write a clean derivation. Every binary is suffixed with -dflash2
# in postInstall so it never collides with the vanilla nixpkgs llama-cpp package.

final: prev:
let
  # Head commit of ggml-org/llama.cpp PR #27342.
  dflash2Rev = "f5a7ec15da6add890a5624c0990714498df837a4";
  dflash2Short = final.lib.strings.toLower (final.lib.strings.substring 0 8 dflash2Rev);

  llama-cpp-dflash2 =
    { lib
    , stdenv
    , cmake
    , ninja
    , pkg-config
    , git
    , openssl
    , config
    , cudaSupport ? config.cudaSupport
    , cudaPackages ? { }
    , autoAddDriverRunpath
    , rpcSupport ? false
    }:
    let
      # Use the CUDA backend stdenv for CUDA builds to avoid libstdc++ errors
      # (same approach as the nixpkgs llama-cpp derivation).
      effectiveStdenv =
        if cudaSupport
        then cudaPackages.backendStdenv
        else stdenv;
      inherit (lib) cmakeBool cmakeFeature optionals;

      cudaBuildInputs = with cudaPackages; [
        cccl # <nv/target>
        cuda_cudart
        libcublas
      ];
    in
    effectiveStdenv.mkDerivation (finalAttrs: {
      pname = "llama-cpp-dflash2";
      version = "0.1.2-dflash2-${dflash2Short}";

      # Tarball of the PR head commit. The github.com archive URL is stable for
      # a given commit SHA.
      src = final.fetchurl {
        url = "https://github.com/ggml-org/llama.cpp/archive/${dflash2Rev}.tar.gz";
        hash = "sha256-uA1uzhi3WP6L8wwcT77De6yFBO5pIc+GU9GuBTZbYXQ=";
      };

      nativeBuildInputs = [
        cmake
        ninja
        pkg-config
        # git is required by cmake/git-vars.cmake and build-info.cmake.
        git
      ]
      ++ optionals cudaSupport [
        cudaPackages.cuda_nvcc
        autoAddDriverRunpath
      ];

      buildInputs =
        optionals cudaSupport cudaBuildInputs
        # OpenSSL backs HTTPS support in the vendored cpp-httplib.
        ++ [ openssl ];

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        # -march=native is non-deterministic; keep it off.
        (cmakeBool "GGML_NATIVE" false)
        (cmakeBool "LLAMA_BUILD_EXAMPLES" false)
        (cmakeBool "LLAMA_BUILD_TOOLS" true)
        (cmakeBool "LLAMA_BUILD_SERVER" true)
        (cmakeBool "LLAMA_BUILD_TESTS" false)
        # Disable the Web UI: its CMake script downloads assets from
        # HuggingFace or runs npm at configure time. We build a server without
        # an embedded UI to keep the build hermetic.
        (cmakeBool "LLAMA_BUILD_UI" false)
        (cmakeBool "LLAMA_USE_PREBUILT_UI" false)
        (cmakeBool "BUILD_SHARED_LIBS" true)
        (cmakeBool "GGML_CUDA" cudaSupport)
        (cmakeBool "GGML_RPC" rpcSupport)
        (cmakeBool "LLAMA_OPENSSL" true)
        (cmakeBool "LLAMA_BUILD_IS_DEV" false)
        # Pin build info so the build is deterministic without a .git dir.
        "-DLLAMA_BUILD_COMMIT=${dflash2Short}"
        "-DLLAMA_BUILD_NUMBER=0"
      ]
      ++ optionals cudaSupport [
        (cmakeFeature "CMAKE_CUDA_ARCHITECTURES" cudaPackages.flags.cmakeCudaArchitecturesString)
      ];

      # Rename every binary with a -dflash2 suffix so this package never
      # collides with the vanilla nixpkgs llama-cpp package. Both can be
      # installed at once; pick either at runtime (e.g. `llama-server` vs
      # `llama-server-dflash2`).
      # The RPC alias is only created when the RPC server was actually built
      # (GGML_RPC=on); with rpcSupport=false the ggml-rpc-server binary does not
      # exist, so skipping the alias avoids a dangling link.
      postInstall =
        ''
          cd $out/bin

          # Rename each real binary to <name>-dflash2. The glob is expanded
          # once, so the renamed files are not re-processed.
          for f in *; do
            if [ -f "$f" ] && [ ! -L "$f" ]; then
              mv "$f" "$f-dflash2"
            fi
          done

          # Convenience alias for the unified CLI (relative symlink).
          ln -sf llama-cli-dflash2 llama-dflash2
        ''
        + lib.optionalString rpcSupport ''
          # Alias for the RPC server (now named ggml-rpc-server-dflash2).
          ln -sf ggml-rpc-server-dflash2 rpc-server-dflash2
        '';

      # The DFlash2 tests are not yet stable upstream.
      doCheck = false;

      meta = with lib; {
        description = "llama.cpp with DFlash2 speculative decoding support (PR #27342)";
        homepage = "https://github.com/ggml-org/llama.cpp";
        changelog = "https://github.com/ggml-org/llama.cpp/pull/27342";
        license = licenses.mit;
        mainProgram = "llama-dflash2";
        platforms = platforms.unix;
        badPlatforms = optionals cudaSupport platforms.darwin;
      };
    });
in
{
  llama-cpp-dflash2 = final.callPackage llama-cpp-dflash2 { };
}
