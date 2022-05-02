# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: Philip McGrath <philip@philipmcgrath.com>

NIX=nix
NIXPKGS=github:NixOS/nixpkgs/b283b64580d1872333a99af2b4cef91bb84580cf
PRETTIER=$(NIX) shell $(NIXPKGS)\#nodePackages.prettier --command prettier

GUIX=guix
GUIX_TIME_MACHINE=$(GUIX) time-machine -C channels

.PHONY: all
all: .prettierignore
	$(warning Consider `make check` or `make prettier-write`)

.PHONY: check
check: prettier-check reuse-lint

.prettierignore: .gitignore
	cp $< $@

.PHONY: prettier-check
prettier-check: .prettierignore
	$(PRETTIER) --check .

.PHONY: prettier-write
prettier-write: .prettierignore
	$(PRETTIER) --write .

.PHONY: reuse-lint
reuse-lint:
	$(GUIX_TIME_MACHINE) -- shell reuse --pure --container -- reuse lint
