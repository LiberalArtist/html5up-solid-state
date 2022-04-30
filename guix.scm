;; SPDX-License-Identifier: CC0-1.0
;; SPDX-FileCopyrightText: 2022 Philip McGrath <philip@philipmcgrath.com>
(use-modules (gnu packages)
             (gnu packages license)
             (gnu packages racket)
             (gnu packages version-control)
             ((gnu packages web)
              #:select (sassc tidy-html))
             (guix build-system copy)
             (guix download)
             (guix gexp)
             (guix git-download)
             (guix packages)
             (guix utils)
             ((guix licenses)
              #:prefix license:))

(define-public magnet-expat
  "magnet:?xt=urn:btih:d3d9a9a6595521f9666a5e94cc830dab83b65699&dn=expat.txt")

(define-public jquery-3.4.1.js
  (origin
    (method url-fetch)
    (uri "https://code.jquery.com/jquery-3.4.1.js")
    (sha256
     (base32
      "0mdxjn1lsjs09m2rlh0200mv9lq72b072idz52ralcmajf2ai4ss"))
    (snippet
     #~(begin
         (use-modules (guix build utils)
                      (srfi srfi-26)
                      (ice-9 match))
         (match (find-files "." "\\.js$")
           ((pth)
            (with-atomic-file-replacement pth
              (lambda (in out)
                (format out "// @license ~a Expat\n" #$magnet-expat)
                (for-each (cut apply format out "// ~a: ~a\n" <>)
                          ;; avoid literals to placate the `reuse` tool
                          '(("SPDX-License-Identifier" "MIT")
                            ("SPDX-FileCopyrightText"
                             "JS Foundation and other contributors")))
                (dump-port in out)
                (display "// @license-end\n" out)))))))))

(define-public jquery-3.4.1.min.js
  (origin
    (inherit jquery-3.4.1.js)
    ;; this is the file that was originally used
    (uri "https://code.jquery.com/jquery-3.4.1.min.js")
    (sha256
     (base32
      "16h8vz0w6har92bc2q2vxccik5x6hy7bx60yicd3jwfrgfnyh989"))))

(define-public jquery-3.6.0.js
  (origin
    (inherit jquery-3.4.1.js)
    (uri "https://code.jquery.com/jquery-3.6.0.js")
    (sha256
     (base32
      "0ffjvjsxpq80savslsbxhfdc5hwgaampq41cwxhmspm7j19vpqhz"))))

(define-public jquery-3.6.0.min.js
  (origin
    (method url-fetch)
    (uri "https://code.jquery.com/jquery-3.6.0.min.js")
    (sha256
     (base32
      "0vpylcvvq148xv92k4z2yns3nya80qk1kfjsqs29qlw9fgxj65gz"))))

(define-public jquery.js jquery-3.4.1.js)

(define-public fontawesome
  (package
    (name "fontawesome-free-web")
    (version "5.9.0")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "https://use.fontawesome.com/releases"
                       "/v" version "/fontawesome-free-" version "-web.zip"))
       (sha256
        (base32
         "0ibz2rz0jj11yf82phmvda2r4smz9z8r7xdqnqjr9bp443m9l2w0"))
       (snippet
        ;; avoid a strange error from "unzip" in the unpack phase
        #~(begin #t))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~`(("." "share/fontawesome"))))
    (home-page "https://fontawesome.com")
    (synopsis "Web icon library and toolkit")
    (description "Font Awsome is a large library of icons in a variety
of web-friendly formats.")
    (license (list license:expat license:cc-by4.0 license:silofl1.1))))

(define-public html5up-solid-state
  (package
    (name "html5up-solid-state")
    (version "0")
    (native-inputs
     (list racket ;; need `#lang at-exp`
           sassc
           fontawesome
           git-minimal
           reuse
           tidy-html))
    (source (local-file "src" #:recursive? #t))
    (build-system copy-build-system)
    (arguments
     (list
      #:modules
      '((guix build copy-build-system)
        (srfi srfi-34)
        (guix build union)
        (guix build utils))
      #:imported-modules
      `((guix build union)
        ,@%copy-build-system-modules)
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'install 'sassc
            (lambda args
              (mkdir-p "build/assets/css")
              (for-each (lambda (name)
                          (invoke "sassc"
                                  "--sourcemap=inline"
                                  (format #f "sass/~a.scss" name)
                                  (format #f "build/assets/css/~a.css" name)))
                        `("noscript"
                          "main"))))
          (add-after 'sassc 'jquery
            (lambda args
              (mkdir-p "vendor/assets/js")
              (symlink #$jquery.js "vendor/assets/js/jquery.js")))
          (add-after 'jquery 'fontawesome
            (lambda* (#:key native-inputs inputs #:allow-other-keys)
              (let ((fa (search-input-directory (or native-inputs inputs)
                                                "share/fontawesome")))
                (mkdir-p "vendor/assets/css")
                (symlink (string-append fa "/css/all.css")
                         "vendor/assets/css/fontawesome-all.css")
                (symlink (string-append fa "/webfonts")
                         "vendor/assets/webfonts"))))
          (add-before 'install 'bundle
            (lambda args
              ;; don't use symlinks in output to avoid
              ;; problems when browsing via "file://" urls
              (union-build "www"
                           '("build" "vendor" "demo")
                           #:symlink copy-file
                           #:create-all-directories? #t))))
      #:install-plan
      #~`(("www" "www"))))
    (home-page "https://html5up.net/solid-state")
    (synopsis "Solid State template by HTML5 UP")
    (description "Solid State template by HTML5 UP")
    (license license:cc-by3.0)))

html5up-solid-state
