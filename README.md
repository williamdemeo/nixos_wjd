# nixos_wjd

Notes on a journey from Ubuntu to NixOS.


## 27 January 2023

### Nix

This section is about the Nix package manager.  It is not about the Nix operating system (NixOS).  The latter is discussed in the [NixOS](#nixos) section below.

Nix is [described here][nixos.org] as a tool that takes a unique approach to package
management and system configuration, enabling one to make reproducible, declarative
and reliable systems.

The purpose of the Nix language is to create build tasks: precise descriptions of how contents of existing files are used to derive new files.

+  A build task in Nix is called a derivation.

+  The Nix language has only few basic constructs which can be combined arbitrarily:

   +  **Primitive data types**, such as integers or character strings
   +  **Compound data types**, that is, lists and attribute sets
   +  **Functions** and **operators** to produce and transform data
   +  **Name assignment** to manipulate data as units

The language is pure---that is, its evaluation does not observe or interact with the outside world---with one notable exception: reading files, to capture what build tasks will operate on.

That's all there is to it!


### Development environment with nix-shell

**Refs**.  
+ [nixos.wiki/wiki/Development_environment_with_nix-shell][nix-shell]
+ [nixos.org/guides/ad-hoc-developer-environments][nix-dev-env]

A [nix-shell][] gives you access to the exact versions of packages specified by nix.


The following "hello world" example---carried out in a terminal window, on the command 
line, at the shell prompt `$`---is illuminating.

```
~$ hello
zsh: command not found: hello

~$ nix-shell -p hello

...a bunch of output (omitted)...

[nix-shell:~/]$ hello
Hello, world!

[nix-shell:~/]$ exit

~$ hello
zsh: command not found: hello
```

What's happening here? The command `nix-shell -p hello` says, "I want a nix shell (cli) with the `hello` program installed along with its dependencies."

The line `...a bunch of output (omitted)...` in the output above is where nix went out and collected any dependencies required to make the `hello` program available.


### Searching package attribute names

You put in a shell environment anything that's in the official package list.

You can search the package list as follows:

```
$ nix-env -qaP git
gitAndTools.gitFull  git-2.25.0
gitMinimal           git-2.25.0
```

The first column is the attribute name and the second is the package name and version.

To get a brief, one-line description of the package, use the `--description` flag.


### Ad hoc shell environments

Once you have attribute names for packages, you can start a shell with (the specific versions of) those packages available:

```
$ nix-shell -p gitMinimal vim nano joe
these paths will be fetched (44.16 MiB download, 236.37 MiB unpacked):
...
/nix/store/fsn35pc8njnimgn2sn26dlsyxya1wssb-vim-8.2.0013
/nix/store/wdqjszpr5dlys53d79fym6rv9vyyz29h-joe-4.6
/nix/store/hx63qkip16i4wifaqgxwrrmxj4az53h1-git-2.25.0

[nix-shell:~]$ git --version
git version 2.25.0

[nix-shell:~]$ which git
/nix/store/hx63qkip16i4wifaqgxwrrmxj4az53h1-git-2.25.0/bin/git
```

**Note**. Even if you had Git installed before, in the shell only the exact version installed by Nix is used.

Press CTRL-D to exit the shell and those packages won't be available anymore.


### direnv

**Ref**. [nixos.org/guides/declarative-and-reproducible-developer-environments][direnv]

Besides activating the environment for each project, every time you change `shell.nix` you need to re-enter the shell.

You can use `direnv` to automate this process, with the downside that each developer needs to install it globally.

1.  [Install direnv with your OS package manager](https://direnv.net/docs/installation.html#from-system-packages)

2.  [Hook it into your shell](https://direnv.net/docs/hook.html)

3.  At the top-level of your project run `echo "use nix" > .envrc && direnv allow`.

The next time your launch your terminal and enter the top-level of your project `direnv` will check for changes.

```
cd myproject
direnv: loading myproject/.envrc
direnv: using nix
hello
```


### Evaluating Nix files

Files with the .nix suffix contain expressions in the Nix language that can be evaluated.

Use `nix-instantiate --eval` to evaluate the expression in a Nix file.

**Example**.

```
$ echo 1 + 2 > file.nix
$ nix-instantiate --eval file.nix
3
```

`nix-instantiate --eval` (with no .nix file specified)  will evaluate `default.nix` in the current directory.



### Search path

**Ref**. [nixos.org/guides/nix-language.html#search-path](https://nixos.org/guides/nix-language.html#search-path)

Also known as "angle bracket syntax".

**Example**.

```
<nixpkgs>
/nix/var/nix/profiles/per-user/root/channels/nixpkgs
```

The value of a named path is a file system path that depends on the contents of the `$NIX_PATH` environment variable.

In practice, `<nixpkgs>` points to the file system path of some revision of nixpkgs, the source repository of Nixpkgs.

For example, `<nixpkgs/lib>` points to the subdirectory lib of that file system path:

```
<nixpkgs/lib>
/nix/var/nix/profiles/per-user/root/channels/nixpkgs/lib
```

We should try to avoid the use of search paths in practice, as they are impurities which are not reproducible.

----------------------------------------------------
----------------------------------------------------

## 4 March 2023

### Installing Nix

**Ref**. [install-nix tutorial](https://nix.dev/tutorials/install-nix).

```
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

### Fundamentals

**Ref**. [nix.conf man page][]


Nix reads settings from two configuration files:

+  The system-wide configuration file: `$NIX_CONF_DIR/nix.conf` or `/etc/nix/nix.conf`if `NIX_CONF_DIR` is not set.

+  The user configuration file: `$XDG_CONFIG_HOME/nix/nix.conf` or `~/.config/nix/nix.conf` if `XDG_CONFIG_HOME` is not set.

   The configuration files consist of `name = value` pairs, one per line. Other files can be included with a 
   line like `include path`, where `path` is interpreted relative to the current file and a missing file is an 
   error unless `!include` is used. Comments start with `#`.
   
**Example**.

```
keep-outputs = true       # Nice for developers
keep-derivations = true   # Idem
```

Override settings on the cli using the `--option` flag, e.g., `--option keep-outputs false`.

### Packages and programs related to Nix

+  [nix-env][] is used to manipulate Nix user environments, which are sets of software packages available to a user at some point in time. In other words, Nix user environments are a synthesised view of the programs available in the Nix store. There may be many user environments: different users can have different environments, and individual users can switch between different environments.

   `nix-env` takes exactly one operation flag which indicates the subcommand to be performed. These flags are documented [here][nix-env].


+  [direnv][] is an extension of the shell with a new feature that can load/unload env variables depending on the current directory.

   `direnv` can be useful for creating per-project isolated development environments, or for loading secrets for deployment.

   Before each prompt, [direnv][] checks for existence of a `.envrc` (or `.env`) file in the current and parent directories and, 
   if it exists, loads it into a bash sub-shell; all exported variables are captured by [direnv][] and available in the current shell. 
   This allows project-specific env vars without cluttering `~/.profile`.

   Because [direnv][] is compiled into a single static executable, it's fast enough to be unnoticeable. It's also language-agnostic 
   and can be used to build solutions similar to `rbenv`, `pyenv`, `phpenv`, or `conda`.


+  [cachix][] is a service for hosting *Nix binary caches*. A Nix binary cache is a binary result that Nix can use instead of performing the build.

   Install the [cachix][] client with `nix-env -iA cachix -f https://cachix.org/api/v1/install` and

   ```
   sudo mkdir -p /etc/nix
   sudo touch -a /etc/nix/nix.conf
   echo "trusted-users = root williamdemeo" | sudo tee -a /etc/nix/nix.conf && sudo pkill nix-daemon
   ```

   See also: https://github.com/cachix/cachix


   **Example**.

   Built the [1lab website repo][] using [cachix][] and [Nix][] as follows:

   ```
   git clone git@github.com:formalverification/1lab.git
   cd 1lab
   cachix use 1lab
   nix-build
   ```

   (This takes quite a long time (≈20 min).)


#### github actions

**Ref**. [nix.dev/tutorials/continuous-integration-github-actions][]

-----------------------------------------------------------------------------

## Nixos

This section is about the Nix operating system (NixOS), not the Nix package manager.

### Installing NixOS

See [nixos-iso][].

### Installing other software

+  Starship: `nix-env -iA nixpkgs.starship`
+  MegaSync: `nix-env -i megasync`
+  home-manager: (currently I'm not using home-manager)

   To use home-manager, put the following in the file `/etc/nixos/home-manager.nix`

   ```
   { config, pkgs, ... }:
   let home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
   in { imports = [ (import "${home-manager}/nixos") ];
        home-manager.users.my_username = { /* your home-manager config, eg home.packages = [ pkgs.foo ]; */ }; }
   ```

   and then put `imports = [ ./home-manager.nix ]` in `/etc/nixos/configuration.nix`.

   Whenever you change you home-manager configuration, you must rerun `nixos-rebuild switch`.
   
   With this method, changing the configuration of an unprivileged user requires to run a command as root.


## Other Miscellaneous Notes

### Changing Mount Points

If you mount an external usb by clicking on its icon in the file manager,
then the mount point will be given a funky long name; in my case,

```
/run/media/williamdemeo/4741-2188
```

This makes it painful to use the cli to work with directories on the usb drive.

We would prefer if the mount point was simply called `usb`.

On ubuntu, we would have simply put the following line in `/etc/fstab`.

```
/dev/sdc1 /mnt/sdc1 auto defaults,user,rw,utf8,noauto,umask=000 0 2
```

In Nixos, the `/etc/fstab` file has a comment warning us that we should be modifying
that file directly. Instead, we should configure such system settings in

```
/etc/nixos/configuration.nix
```

file.  So, put the following lines in the `configuration.nix` file:

```
fileSystems."/usb" = {
    device = "/dev/sdb1";
    fsType = "auto";
    options = [ "defaults" "user" "rw" "utf8" "noauto" "umask=000" ];
  };
```

Then, run `nixos-generate-config` and `nixos-rebuild switch`.

### Comparing the contents of two directories

**Refs**.

+ [How To Compare Two Directories on Linux](https://www.baeldung.com/linux/compare-two-directories)

`diff --brief --recursive Dir1 Dir2`

**Examples**.

```
diff --brief --recursive Dir1 Dir2
Files Dir1/client.log and Dir2/client.log differ
Files Dir1/file02 and Dir2/file02 differ
Files Dir1/file03 and Dir2/file03 differ
Only in Dir2: file04
Files Dir1/subdir1/file12 and Dir2/subdir1/file12 differ
Files Dir1/subdir2/file22 and Dir2/subdir2/file22 differ
Only in Dir2/subdir2: file23
Only in Dir1: subdir3
```

### Miscellaneous

Andre suggests looking at the nix-build error ticket and possibly commenting out the `{-# OPTIONS -v allTactics:100 #-}` pragmas.


--------------------------------
--------------------------------

## 18 March 2023

### Routine maintenance on alonzo.

**Ref**. [Things to do after installing nixos][]

+  Install `ag`

   Add `silver-searcher` to `/etc/nixos/configuration.nix`:

   `environment.systemPackages = with pkgs; [ wget zsh meld git emacs silver-searcher ];`

+  Change hostname from nixos to alonzo in `/etc/nixos/configuration.nix`:

   `networking.hostName = "alonzo";     # after F1 driver Fernando (not Church)`

+  Update packages:

   ```
   sudo nix-channel update
   sudo nixos-rebuild switch --upgrade
   ```

+  Enable weekly garbage collection with the following in `/etc/nixos/configuration.nix`:

   ```
   # Enable automatic garbage collection (gc).
   nix.gc = {
                   automatic = true;
                   dates = "weekly";
                   options = "--delete-older-than 7d";
   };
   ```

   After `sudo nixos-rebuild switch`, check gc is running: `systemctl list-timers`.


+  Reduce "swappiness" with the following line in `/etc/nixos/configuration.nix`:

   ```
   boot.kernel.sysctl = { "vm.swappiness" = 10;};
   ```

   After `sudo nixos-rebuild switch`, check swappiness: `cat /proc/sys/vm/swappiness`.

+  Make fingerprint reader work by adding the following to `/etc/nixos/configuration.nix`:

   ```
   # fingerprint reader: login and unlock with fingerprint (if you add one with `fprintd-enroll`)
   services.fprintd.enable = true;
   services.fprintd.tod.enable = true;
   services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;
   security.pam.services.login.fprintAuth = true;
   security.pam.services.xscreensaver.fprintAuth = true;
   # similarly for other PAM providers
   ```


+  Rebuild with `sudo nixos-rebuild switch`.

Upon next restart and login the terminal printed the message 

"Install rlwrap to use node: sudo apt-get install -y rlwrap"

So I decided to install `rlwrap` (not using `apt-get` of course).

I looked for the nix package with

```
nix-env -qaP rlwrap
```

and, before the results were shown, the following warning and suggestion appeared:

"warning: name collision in input Nix expressions, skipping '/home/williamdemeo/.nix-defexpr/channels_root/nixpkgs'
suggestion: remove 'nixpkgs' from either the root channels or the user channels"

I checked that indeed I did have a `nixpkgs` channel in my user profile.

```
❯ ls .nix-defexpr/channels
```

So I invoked the following to remove it:

```
❯ nix-channel --remove nixpkgs
```

Next I added rlwrap to the following line of `/etc/nixos/configuration.nix`.

```
environment.systemPackages = with pkgs; [ wget zsh meld git emacs silver-searcher rlwrap];
```


### Install Doom Emacs

I decided to try [Doom Emacs][] as a possible replacement for spacemacs.

```
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install
```

Postinstallation message:

```
1. Don't forget to run 'doom sync', then restart Emacs, after modifying
   ~/.doom.d/init.el or ~/.doom.d/packages.el.

   This command ensures needed packages are installed, orphaned packages are
   removed, and your autoloads/cache files are up to date. When in doubt, run
   'doom sync'!

2. If something goes wrong, run `doom doctor`. It diagnoses common issues with
   your environment and setup, and may offer clues about what is wrong.

3. Use 'doom upgrade' to update Doom. Doing it any other way will require
   additional steps. Run 'doom help upgrade' to understand those extra steps.

4. Access Doom's documentation from within Emacs via 'SPC h d h' or 'C-h d h'
   (or 'M-x doom/help')
```



----------------------------------
----------------------------------

## 24 March 2023


### Routine maintenance on alonzo

+  **add packages** to nixos, rebuild, and restart
 
   ```
   sudo mg /etc/nixos/configuration.nix
   sudo nixos-rebuild switch
   sudo shutdown -r now
   ```


+  **miscellaneous admin**

    ```
    sudo nix-collect-garbage -d
    sudo nixos-rebuild switch  # didn't work (couldn't find system-3-link)
    nix-env --delete-generations old
    nix-collect-garbage -d
    nix-env --delete-generations old
    nix-store --gc
    sudo nixos-rebuild switch
    sudo nixos-rebuild boot
    ls /nix/var/nix/profiles/system
    ls -l /nix/var/nix/profiles
    sudo ln -s /nix/var/nix/profiles/system-16-link /nix/var/nix/profiles/system-3-link
    sudo nixos-rebuild switch
    nix-env -qaP emacs
    sudo mg /etc/nixos/configuration.nix
    sudo nixos-rebuild switch
    emacs --version
    ```


### downgrade emacs for use with doom

I discovered I had the wrong version of emacs for using doom (`emacsGit`, which is the (unstable) ver 30).
So I removed and reinstalled emacs (using `emacs` in `configuration.nix`).
    
+  remove config directories

   ```
   rm -rf .emacs.d
   rm -rf .doom.d
   ```

+  change `emacsGit` to `emacs` in the `environment.systemPackages` section of 
   `/etc/nixos/configuration.nix` and add the following above that section:

   ```
   # -- Doom Emacs -----------------------------------------------------------------
   # see: https://github.com/nix-community/emacs-overlay#quickstart
   # services.emacs.package = pkgs.emacsUnstable;
   nixpkgs.overlays = [
     (import (builtins.fetchTarball https://github.com/nix-community/emacs-overlay/archive/master.tar.gz))
   ];
   # -------------------------------------------------------------------------------
   ```

   Run `sudo nixos-rebuild switch` to make these changes take effect.

+  check that `emacs --version` gives 28.2 (or something compatible with doom emacs).


### install/configure emacs doom emacs on alonzo

1.  **install doom emacs**

    ```
    git clone https://github.com/hlissner/doom-emacs ~/.emacs.d
    ~/.emacs.d/bin/doom install
    ```
    
    and then  add `.doom.d/bin` to my search path by editing `~/.oh-my-zsh/custom/path.zsh`.


3.  **reinstall doom emacs and check it**
    
    ```
    git clone https://github.com/hlissner/doom-emacs ~/.emacs.d
    ~/.emacs.d/bin/doom install
    doom doctor
    doom upgrade
    mg ~/.doom.d/init.el  # fix some initial config settings
    doom refresh
    doom sync
    ```

4.  **fix problems**

    After uncommenting some packages listed in `~/.doom.d/init.el`, running `doom sync` and then running 
    `doom doctor`, I get a bunch of warnings, mostly about missing programs, so I added some more 
    to nixos by naming them in `/etc/nixos/configuration.nix`. The `environment.systemPackages` section 
    of my nixos configuration now looks like this.

    ```
    environment.systemPackages = with pkgs; [ 
        wget zsh  meld  git  ripgrep  silver-searcher  rlwrap  direnv  emacs coreutils fd
        (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
        cmake gnumake nodejs nixfmt shellcheck
        haskellPackages.ghc
        haskellPackages.cabal-install
        haskellPackages.haskell-language-server
        haskellPackages.hoogle
      ];
    ```

    then run `sudo nixos-rebuild switch` to make these changes take effect.

5.  **add doom config files to git repo**

    ```
    cd ~/git/williamdemeo/config_wjd/doom
    git add config.el custom.el init.el packages.el
    git commit -m "updates"
    git push
    ```


### install agda and agda-mode on alonzo

    ```
    mkdir -p ~/git
    mkdir -p ~/git/IO
    cd !$
    git clone git@github.com:input-output-hk/formal-ledger-specifications.git fls
    cd fls
    mkdir -p ~/IOHK
    nix-build -A agda -o ~/IOHK/ledger-agda
    ```
    

### install/configure haskell on alonzo

This is done by inserting the lines

```
        haskellPackages.ghc
        haskellPackages.cabal-install
        haskellPackages.haskell-language-server
        haskellPackages.hoogle
```

in the `environment.systemPackages` section of my `/etc/nixos/configuration.nix` file,
as mentioned above (and of course running `sudo nixos-rebuild switch`). 
    

### create an example haskell project

```
mkdir -p ~/git/LANG
mkdir -p ~/git/LANG/Haskell
mkdir -p ~/git/LANG/Haskell/arrivals
cd !$
nix-shell -p cabal-install ghc
cabal update
cd ~/git/LANG/Haskell/arrivals
cabal init
```


## 27 March 2023

### Create a LaTeX project with flakes

**Ref**. [Exploring Nix Flakes: Build LaTeX Documents Reproducibly][]

**Summarized Steps**.

1.  Create a project directory (e.g., `~/flatex`) and a file called `document.tex` inside it.

    This file, `~/flatex/document.tex`, should contain the following.
    
    ```
    \documentclass[a4paper]{article}
    \begin{document}
      Hello, World!
    \end{document}
    ```

2.  Create a file called `flake.nix` inside the project directory.

    This file, `~/flatex/flake.nix`, should contain the following.

    ```
    {
      description = "LaTeX Document Demo";
      inputs = {
        nixpkgs.url = github:NixOS/nixpkgs/nixos-21.05;
        flake-utils.url = github:numtide/flake-utils;
      };
      outputs = { self, nixpkgs, flake-utils }:
        with flake-utils.lib; eachSystem allSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tex = pkgs.texlive.combine {
              inherit (pkgs.texlive) scheme-minimal latex-bin latexmk;
          };
        in rec {
          packages = {
            document = pkgs.stdenvNoCC.mkDerivation rec {
              name = "latex-demo-document";
              src = self;
              buildInputs = [ pkgs.coreutils tex ];
              phases = ["unpackPhase" "buildPhase" "installPhase"];
              buildPhase = ''
                export PATH="${pkgs.lib.makeBinPath buildInputs}";
                mkdir -p .cache/texmf-var
                env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
                  latexmk -interaction=nonstopmode -pdf -lualatex \
                  document.tex
              '';
              installPhase = ''
                mkdir -p $out
                cp document.pdf $out/
              '';
            };
          };
          defaultPackage = packages.document;
        });
    }
    ```

3.  Create a `flake.lock` file to pin our input flakes to their current versions.

    ```
    cd ~/flatex
    nix flake lock
    ```

4.  Check our project files into a git repository, or else the nix build won't find them.

    *The variable self will only contain those files of our source that are checked into version control.*

    ```
    cd ~/flatex
    git init
    git add flake.{nix,lock} document.tex
    git commit -m "initial commit"
    ```
    
5.  Build the document and find the resulting pdf in the `~/flatex/result` directory.

    ```
    cd ~/flatex
    nix build
    evince ~/flatex/result/document.pdf
    ```

------------------------------
------------------------------


## Reference Links


+  [12factor][]
+  [1lab website repo][]
+  [626245][]

+  [cachix][]
+  [cloudflare dash][]
+  [cloudflare dashboard][]
+  [cloudflare docs][]

+  [direnv][]
+  [direnv (the nixos guide)][] 

+  [Doom Emacs][]
+  [doom emacs][]
+  [doom][]
+  [Doom Emacs on NixOS][]

+  [emacs][]
+  [Exploring Nix Flakes: Build LaTeX Documents Reproducibly][]

+  [git][]
+  [github ip addresses][]
+  [gnome-tweaks][]

+  [haskell language server][]
+  [haskell4nix][]
+  [haskell4nix readthedocs section: how to install haskell-languageserver][haskell4nix hls]
+  [How to mount internal drives as a normal user in NixOS][] (unix.SE post) and [this answer][626245] to it.

+  [Nerd Font: FiraCode 6.2][]
+  [Nix][]
+  [nix][]
+  [nix.conf man page][]
+  [nix.dev][]
+  [nix.dev/tutorials/continuous-integration-github-actions][]
+  [nix-community/emacs-overlay][]
+  [nix-dev-env][]
+  [nix-env][]
+  [nixos-iso][]
+  [nix-shell][]
+  [nixos.org][]
+  [nixos.org/guides/nix-language.html][]

+  [oh-my-zsh][]

+  [quickstart section][]

+  [spacemacs][]
+  [starship][]
+  [Sysadmin Pocket Survival Guide -- NixOS][]

+  [things to do after installing nixos][]

+  [VSCode][]

+  [zsh][]


----------------------------

[12factor]: https://12factor.net/
[1lab website repo]: https://github.com/formalverification/1lab
[626245]: https://unix.stackexchange.com/a/626245

[cachix]: https://www.cachix.org/
[cloudflare dash]: https://dash.cloudflare.com
[cloudflare dashboard]: https://dash.cloudflare.com
[cloudflare docs]: https://developers.cloudflare.com/dns/zone-setups/full-setup/setup/

[direnv]: https://direnv.net/
[direnv (the nixos guide)]: https://nixos.org/guides/declarative-and-reproducible-developer-environments.html#declarative-reproducible-envs

[Doom Emacs]: https://github.com/doomemacs/doomemacs
[doom emacs]: https://github.com/doomemacs/doomemacs
[doom]: https://github.com/doomemacs/doomemacs
[Doom Emacs on NixOS]: https://github.com/doomemacs/doomemacs/blob/master/docs/getting_started.org#nixos

[emacs]: https://www.gnu.org/software/emacs/
[Exploring Nix Flakes: Build LaTeX Documents Reproducibly]: https://flyx.org/nix-flakes-latex/

[git]: https://git-scm.com/
[github ip addresses]: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain
[gnome-tweaks]: https://wiki.gnome.org/Apps/Tweaks

[haskell4nix]: https://haskell4nix.readthedocs.io/
[haskell4nix hls]: https://haskell4nix.readthedocs.io/nixpkgs-users-guide.html#how-to-install-haskell-language-server
[haskell language server]: https://haskell-language-server.readthedocs.io/en/latest/index.html
[How to mount internal drives as a normal user in NixOS]: https://unix.stackexchange.com/questions/533265/how-to-mount-internal-drives-as-a-normal-user-in-nixos

[Nerd Font: FiraCode 6.2]: https://github.com/tonsky/FiraCode
[Nix]: https://nixos.org/
[nix]: https://nixos.org/
[nix.conf man page]: https://manpages.ubuntu.com/manpages/jammy/man5/nix.conf.5.html
[nix.dev]: https://nix.dev/
[nix.dev/tutorials/continuous-integration-github-actions]: https://nix.dev/tutorials/continuous-integration-github-actions
[nix-community/emacs-overlay]: https://github.com/nix-community/emacs-overlay/issues
[nix-dev-env]: https://nixos.org/guides/ad-hoc-developer-environments.html
[nix-env]: https://nixos.org/manual/nix/stable/command-ref/nix-env.html
[nixos-iso]: https://nixos.org/download.html#nixos-iso
[nix-shell]: https://nixos.wiki/wiki/Development_environment_with_nix-shell
[nixos.org]: https://nixos.org/
[nixos.org/guides/nix-language.html]: https://nixos.org/guides/nix-language.html

[oh-my-zsh]: https://ohmyz.sh/

[quickstart section]: https://github.com/nix-community/emacs-overlay#quickstart

[spacemacs]: https://www.spacemacs.org/
[starship]: https://starship.rs/guide/
[Sysadmin Pocket Survival Guide -- NixOS]: https://tin6150.github.io/psg/nixos.html

[things to do after installing nixos]: https://itsfoss.com/things-to-do-after-installing-nixos/

[VSCode]: https://code.visualstudio.com/

[zsh]: https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH











