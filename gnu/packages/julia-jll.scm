;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2021 Nicolò Balzarotti <nicolo@nixo.xyz>
;;; Copyright © 2021 Simon Tournier <zimon.toutoune@gmail.com>
;;; Copyright © 2021 Efraim Flashner <efraim@flashner.co.il>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages julia-jll)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system julia)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages image)
  #:use-module (gnu packages julia)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages web))

;;; TODO: Remove this autogenerated source package
;;; and build it from realse source using <https://github.com/JuliaPackaging/Yggdrasil/>

(define-public julia-compilersupportlibraries-jll
  (package
    (name "julia-compilersupportlibraries-jll")
    (version "0.4.0+1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl")
             (commit (string-append "CompilerSupportLibraries-v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "03j6xdvps259mhdzpjqf41l65w2l9sahvxg4wrp34hcf69wkrzpy"))))
    (build-system julia-build-system)
    (arguments
     `(#:tests? #f                      ; no runtests.jl
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'override-binary-path
           (lambda* (#:key inputs #:allow-other-keys)
             (map
              (lambda (wrapper)
                (substitute* wrapper
                  (("generate_wrapper_header.*")
                   (string-append
                    "generate_wrapper_header(\"CompilerSupportLibraries\", \""
                    (assoc-ref inputs "gfortran:lib") "\")\n"))))
              ;; There's a Julia file for each platform, override them all
              (find-files "src/wrappers/" "\\.jl$"))
             #t)))))
    (inputs                             ;required by artifacts
     `(("gfortran:lib" ,gfortran "lib")))
    (propagated-inputs
     `(("julia-jllwrappers" ,julia-jllwrappers)))
    (home-page "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl")
    (synopsis "Internal wrappers")
    (description "This package provides compiler support for libraries.  It is
an autogenerated source package constructed using @code{BinaryBuilder.jl}. The
originating @code{build_tarballs.jl} script can be found on the community
build tree Yggdrasil.")
    (license license:expat)))

(define-public julia-gumbo-jll
  (package
    (name "julia-gumbo-jll")
    (version "0.10.1+1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/JuliaBinaryWrappers/Gumbo_jll.jl")
             (commit (string-append "Gumbo-v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "00a182x5hfpjzyvrxdn8wh4h67q899p5dzqp19a5s22si4g41k76"))))
    (build-system julia-build-system)
    (arguments
     '(#:tests? #f ; no runtests
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'override-binary-path
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((gumbo (string-append (assoc-ref inputs "gumbo-parser"))))
               (for-each
                (lambda (wrapper)
                  (substitute* wrapper
                    (("(const libgumbo = )\"(.*)\"" all const libname)
                     (string-append const "\"" gumbo "/lib/" libname "\"\n"))
                    (("(global artifact_dir =).*" all m)
                     (string-append m " \"" gumbo "\""))))
                ;; There's a Julia file for each platform, override them all
                (find-files "src/wrappers/" "\\.jl$"))))))))
    (inputs
     `(("gumbo-parser" ,gumbo-parser)))
    (propagated-inputs
     `(("julia-jllwrappers" ,julia-jllwrappers)))
    (home-page "https://github.com/JuliaBinaryWrappers/Gumbo_jll.jl")
    (synopsis "Gumbo HTML parsing library wrappers")
    (description "This package provides a wrapper for Gumbo HTML parsing library.")
    (license license:expat)))

(define-public julia-jllwrappers
  (package
    (name "julia-jllwrappers")
    (version "1.3.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/JuliaPackaging/JLLWrappers.jl")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0v7xhsv9z16d657yp47vgc86ggc01i1wigqh3n0d7i1s84z7xa0h"))))
    (arguments
     ;; Wants to download stuff
     '(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'custom-override-path
           (lambda* (#:key inputs #:allow-other-keys)
             ;; Make @generate_wrapper_header take an optional argument that
             ;; guix packagers can pass to override the default "override"
             ;; binary path.  This won't be needed when something like
             ;; https://github.com/JuliaPackaging/JLLWrappers.jl/pull/27
             ;; will be merged.
             (substitute* "src/wrapper_generators.jl"
               (("generate_wrapper_header.*")
                "generate_wrapper_header(src_name, override_path = nothing)\n")
               (("pkg_dir = .*" all)
                (string-append
                 all "\n" "override = something(override_path,"
                 "joinpath(dirname(pkg_dir), \"override\"))\n"))
               (("@static if isdir.*") "@static if isdir($override)\n")
               (("return joinpath.*") "return $override\n"))
             #t)))))
    (build-system julia-build-system)
    (home-page "https://github.com/JuliaPackaging/JLLWrappers.jl")
    (synopsis "Julia macros used by JLL packages")
    (description "This package contains Julia macros that enable JLL packages
to generate themselves.  It is not intended to be used by users, but rather is
used in autogenerated packages via @code{BinaryBuilder.jl}.")
    (license license:expat)))

(define-public julia-jpegturbo-jll
  (package
    (name "julia-jpegturbo-jll")
    (version "2.0.1+2")
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
               (url "https://github.com/JuliaBinaryWrappers/JpegTurbo_jll.jl")
               (commit (string-append "JpegTurbo-v" version))))
        (file-name (git-file-name name version))
        (sha256
         (base32
          "1xp1x0hrj337bgwwffwpyq7xg031j2a38fim29lixqa0a0y80x6y"))))
    (build-system julia-build-system)
    (arguments
     '(#:tests? #f  ; no runtests
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'override-binary-path
           (lambda* (#:key inputs #:allow-other-keys)
             (map
               (lambda (wrapper)
                 (substitute* wrapper
                   (("artifact\"JpegTurbo\"")
                    (string-append "\"" (assoc-ref inputs "libjpeg-turbo") "\""))))
               ;; There's a Julia file for each platform, override them all
               (find-files "src/wrappers/" "\\.jl$")))))))
    (inputs
     `(("libjpeg-turbo" ,libjpeg-turbo)))
    (propagated-inputs
     `(("julia-jllwrappers" ,julia-jllwrappers)))
    (home-page "https://github.com/JuliaBinaryWrappers/JpegTurbo_jll.jl")
    (synopsis "Libjpeg-turbo library wrappers")
    (description "This package provides a wrapper for the libjpeg-turbo library.")
    (license license:expat)))

(define-public julia-mbedtls-jll
  (package
    (name "julia-mbedtls-jll")
    ;; version 2.25.0+0 is not compatible with current mbedtls 2.23.0,
    ;; upgrade this when mbedtls is updated in guix
    (version "2.24.0+1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl")
             (commit (string-append "MbedTLS-v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0kk9dlxdh7yms21npgrdfmjbj8q8ng6kdhrzw3jr2d7rp696kp99"))))
    (build-system julia-build-system)
    (arguments
     '(#:tests? #f                      ; No runtests.jl
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'override-binary-path
           (lambda* (#:key inputs #:allow-other-keys)
             (map
              (lambda (wrapper)
                (substitute* wrapper
                  (("generate_wrapper_header.*")
                   (string-append
                    "generate_wrapper_header(\"MbedTLS\", \""
                    (assoc-ref inputs "mbedtls-apache") "\")\n"))))
              ;; There's a Julia file for each platform, override them all
              (find-files "src/wrappers/" "\\.jl$"))
             #t)))))
    (inputs `(("mbedtls-apache" ,mbedtls-apache)))
    (propagated-inputs `(("julia-jllwrappers" ,julia-jllwrappers)))
    (home-page "https://github.com/JuliaBinaryWrappers/MbedTLS_jll.jl")
    (synopsis "Apache's mbed TLS binary wrappers")
    (description "This Julia module provides @code{mbed TLS} libraries and
wrappers.")
    (license license:expat)))

(define-public julia-openspecfun-jll
  (let ((commit "6c505cce3bdcd9cd2b15b4f9362ec3a42c4da71c"))
    (package
      (name "julia-openspecfun-jll")
      (version "0.5.3+4")                 ;tag not created upstream
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/JuliaBinaryWrappers/OpenSpecFun_jll.jl")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0bl2gcgndsbiwhwy8fl070cjm1fyf9kxj6gkikgirmzgjl29iakn"))))
      (build-system julia-build-system)
      (arguments
       `(#:tests? #f                      ; no runtests.jl
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'override-binary-path
             (lambda* (#:key inputs #:allow-other-keys)
               (map
                (lambda (wrapper)
                  (substitute* wrapper
                    (("generate_wrapper_header.*")
                     (string-append
                      "generate_wrapper_header(\"OpenSpecFun\", \""
                      (assoc-ref inputs "openspecfun") "\")\n"))))
                ;; There's a Julia file for each platform, override them all
                (find-files "src/wrappers/" "\\.jl$"))
               #t)))))
      (inputs
       `(("openspecfun" ,openspecfun)))
      (propagated-inputs
       `(("julia-jllwrappers" ,julia-jllwrappers)
         ("julia-compilersupportlibraries-jll" ,julia-compilersupportlibraries-jll)))
      (home-page "https://github.com/JuliaBinaryWrappers/OpenSpecFun_jll.jl")
      (synopsis "Internal wrappers")
      (description "This package provides a wrapper for OpenSpecFun.  It is an
autogenerated source package constructed using @code{BinaryBuilder.jl}. The
originating @code{build_tarballs.jl} script can be found on the community
build tree Yggdrasil.")
      (license license:expat))))

(define-public julia-zlib-jll
  (package
    (name "julia-zlib-jll")
    (version "1.2.12+1")
    (source
      (origin
        (method git-fetch)
        (uri (git-reference
               (url "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl")
               (commit (string-append "Zlib-v" version))))
        (file-name (git-file-name name version))
        (sha256
         (base32 "05ih0haqapkzr40swvq63cafnqlc4yp6yfa1wvdyq8v3n4kxhfqa"))))
    (build-system julia-build-system)
    (arguments
     '(#:tests? #f  ; no runtests
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'override-binary-path
           (lambda* (#:key inputs #:allow-other-keys)
             (map
               (lambda (wrapper)
                 (substitute* wrapper
                   (("generate_wrapper_header.*")
                    (string-append
                      "generate_wrapper_header(\"Zlib\", \""
                      (assoc-ref inputs "zlib") "\")\n"))))
               ;; There's a Julia file for each platform, override them all
               (find-files "src/wrappers/" "\\.jl$")))))))
    (inputs
     `(("zlib" ,zlib)))
    (propagated-inputs
     `(("julia-jllwrappers" ,julia-jllwrappers)))
    (home-page "https://github.com/JuliaBinaryWrappers/Zlib_jll.jl")
    (synopsis "Zlib library wrappers")
    (description "This package provides a wrapper for Zlib.")
    (license license:expat)))
