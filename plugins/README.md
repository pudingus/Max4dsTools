# nspec

This plugin exposes functions for MAXScript for modifying explicit normals. It exposes 'nspec' class and 'inspec' interface and it's functions
```
    <int> GetNumNormals <Mesh>
    <int> GetNumFaces <Mesh>
    <point3> GetNormal <Mesh> <int normalId>
    <int> GetNormalId <Mesh> <int face> <int corner>
    <bool> SetNumNormals <Mesh> <int>
    <bool> SetNumFaces <Mesh> <int>
    SetNormal <Mesh> <int normalId> <point3 normal>
    SetNormalId <Mesh> <int face> <int corner> <int normalId>
    SetNormalExplicit <Mesh> <int normalId> <bool explicit>
    <bool> GetNormalExplicit <Mesh> <int normalId>
```
Sample usage:
```
nspec.getnormal $.mesh 14
```
or
```
nspec.inspec.getnormal $.mesh 14
```

This is how I came up with the name 'nspec'...   
I use a class called MeshNormalSpec from the SDK, so MeshNormalSpec -> NormalSpec -> nspec

## Requirements

This plugin requires Autodesk 3ds Max SDK and the SDK's dependencies

https://www.autodesk.com/developer-network/platform-technologies/3ds-max#3dsmax-sdk

The SDK also comes with the 3ds Max installer.

**nspec_2014**  
MSVC v100 (2010)    
3ds Max 2014 SDK  

**nspec_2015**  
MSVC v110 (2012)  
3ds Max 2015 SDK  

**nspec_2017**  
MSVC v140 (2015)  
3ds Max 2017 SDK  

**nspec_2018**  
MSVC v140 (2015)  
Windows SDK 10.0.10586  
3ds Max 2018 SDK  

**nspec_2019**  
MSVC v140 (2015)  
Windows SDK 10.0.10586  
3ds Max 2019 SDK  

**nspec_2020**  
MSVC v141 (2017)  
Windows SDK 10.0.17134.0  
3ds Max 2020 SDK  

**nspec_2022**  
MSVC v141 (2017)  
Windows SDK 10.0.17134.0  
3ds Max 2022 SDK

**nspec_2023**  
MSVC v142 (2019)  
Windows SDK 10.0.19041.0  
3ds Max 2023 SDK  

## Building
- Open 'nspec.sln' in Visual Studio
- Set the configuration to 'Release'
- Build