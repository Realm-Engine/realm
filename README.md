# Realm

### Hobby game framework and game in D

<img src="https://github.com/Realm-Engine/realm/blob/main/Docs/Images/landscape.png?raw=true" alt="Preview" width="554" height="351"/>

## Features

* Materials
* Model loading (.obj)
* Texture loading
* Debug/Line drawing
* Shadows
* Streamlined shader creation
  * With shader program caching
* Virtual file system
* UI/Screen space rendering
  * Text
  * Coloured panels


## Building

### Dependencies


* D compiler
* [dub](https://code.dlang.org/) package manager
* CMake/make/meson/MSBuild
  * For building freetype, so see [here](https://github.com/Realm-Engine/freetype/blob/master/docs/INSTALL) for what you need.
  * Or you could just get a prebuilt binary and place it in `Projects/<Project>/bin`
  * _Either way you do it be sure to get freetype 2.11_
### Process
1. First clone and get submodules using `-recursive` flag or running <br> `git submodule init` <br> `git submodule update`
2. If building freetype, its already configured to build a dynamic library, it is under `external/freetype`
   * See link above for directions
3. Go to _your_ game project root (for example Projects/RealmGame) and type <br> `dub run` or `dub config --config=realm-executable`
   * To build out to a dynamic library use `dub config --config=realm-dynamiclibrary`


## Creating a project

2. Run `./bootstrap/new-project.bat <name>`from repository root
    * This will create a dub project under `./Projects/name` and register realm engine package
3. Configure dub.json
    * in the generated dub.json add the following: <br> `"dependencies" : {"realm" : "~main"}`<br>`"workingDirectory" : "../../"`
