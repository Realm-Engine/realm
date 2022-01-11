# Realm

### Hobby game framework and game in D

<img src="https://github.com/Realm-Engine/realm/blob/main/Docs/Images/engine-preview.png?raw=true" alt="Preview" width="554" height="351"/>

## Features

* Batch rendering
* Materials
* Model loading (.obj)
* Texture loading
* Debug/Line drawing
* Shadows
* Streamlined shader creation
  * With shader program caching
* Virtual file system
* Little to no overhead ECS

## Creating a project

### Dependencies

* D compiler
* [dub](https://code.dlang.org/) package manager

1. Clone repository
2. Run `./bootstrap/new-project.bat -name`from repository root
    * This will create a dub project under `./Projects/name` and register realm engine package
3. Configure dub.json
    * in the generated dub.json add the following: <br> `"dependencies" : {"realm" : "~main"}`<br>`"workingDirectory" : "../../"`
