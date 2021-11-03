workspace "realm"
    architecture "x64"
    configurations
    {
        "Debug",
        "Release"
    }
    files
    {
        "premake5.lua"
    }


outputdir = "%{cfg.buildcfg}-%{cfg.system}-%{cfg.architecture}"
IncludeDir = {}
IncludeDir["GLFW" ]= "./deps/glfw/include"
IncludeDir["glad" ]= "./deps/glad/include"
IncludeDir["tinyobjloader"] = "./deps/tinyobjloader"
group "Dependencies"
include "./deps/glfw"
include "./deps/glad"
group ""

project "realm_game"
    kind "ConsoleApp"
    language "C"
    toolset "clang"
    staticruntime "on"
    targetdir("bin/" .. outputdir .. "/%{prj.name}")
    objdir("obj/" .. outputdir .. "/%{prj.name}")

    files
    {
        "src/**.h",
        "src/**.c",
        "src/containers/**.h",
        "src/containers/**.c",
        "resources/**.glsl"
        

    }
    includedirs
    {
        "src",
        "%{IncludeDir.GLFW}",
        "%{IncludeDir.glad}",
        "premake5.lua",
        "%{IncludeDir.tinyobjloader}"
    }
    links
    {
        "GLFW",
        "glad",
        "opengl32",
        
    }
    defines
    {
        "GLFW_INCLUDE_NONE"
    }
    
    filter "files:%{wks.location}/resources/**"
        buildaction "Embed"
    
    filter "configurations:Debug"
        runtime "Debug"
        symbols "on"

    filter "configurations:Release"
        runtime "Release"
        optimize "on"
        postbuildcommands { "{COPYDIR} \"%{wks.location}/resources\" \"bin/" .. outputdir .. "/%{prj.name}/resources\""}