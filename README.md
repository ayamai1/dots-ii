> work in progress! (the dotbot install as described below is not here yet)

<div align="center">
    <h1>【 ayamai1's dotfiles 】</h1>
    <h3></h3>
</div>

[insert cute desktop pic]

<div align="center">
    <h2>• info •</h2>
    <h3></h3>
</div>

if you want to know more about the dotfiles, be sure to first check out the [README of end_4's dots](https://github.com/end_4/dots-hyprland) *(that this repo is based on!)*

**deviations**:

- i need maximum performance, and that includes cutting out everything *i myself* won't be using:

  - only [Artix linux](https://artixlinux.org) (with OpenRC) is supported, support for other distros or init systems is removed

  - some of the options in widget settings are removed because i'd never change them

- **dotbot** is used for installation instead of custom scripts. dotbot:

  - is easier to configure and maintain;

  - is easier to develop with:
    
      - the dotfiles are installed as *symbolic links*, so changes made **in the repo** will immediatly appear **in your computer**

  - has *idempotent* installation:
  
    - you can re-try the installation process, even after something went wrong

    - pull **all** latest changes by just re-running the install

- in addition to basic stuff — compositor, widgets, theming and compatibility software *(portals, input methods, hardware management etc.)* — there is also configuration for software that i frequently use:

    - custom shells (fish and zsh)
    
    - terminal emulator (kitty)

    - media player (mpv)
    
    - file manager (Dolphin)

  so, you can compate these dotfiles to a **full-fledged desktop environment**

<div align="center">
    <h2>• auto-install •</h2>
    <h3></h3>
</div>

on a freshly set up computer with Artix Linux, run:

```bash
mkdir ~/repos && cd ~/repos && git clone https://github.com/ayamai1/dots-ii && dots-ii/install
```

after installation is complete, don't delete the repository from your computer! otherwise the links to dotfiles will break, and thus, the installation will break