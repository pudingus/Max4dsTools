**Work in progress!** Based on the plugin by Mr F, but almost everything has been rewritten.

3ds Max 2009 or newer required.

![3dsmax_2020-06-25_12-15-09](https://user-images.githubusercontent.com/39903631/85701543-c8233680-b6dd-11ea-992c-d84cce7cb50a.jpg)

**What is supported:**
- Sectors
- Portals
- Meshes
- LODs
- Dummies
- [Material flags](https://user-images.githubusercontent.com/39903631/84805351-67706b80-b004-11ea-846a-2d633223620a.png)
- Culling and rendering flags
- Vertex normals (smoothing groups, or explicit normals)
- Billboards

**What is not supported (yet?):**
- Skinned meshes, morphs, bones, mirrors, targets, glows. Files containing these types can be opened, but they will be imported only partially.  

You can edit object parameters to control rendering flags, culling flags, lod fade distance, portal range...

scene.4ds files can be imported & exported without losing lighting or collisions (depends on how much you edit)

If you move pivot for an object, you have to reset it before exporting.

**How to install:**  
[Download here](https://github.com/pudingus/mafia-4ds-import-export/releases)  
Extract the files in "C:\Program Files\Autodesk\3ds Max 2020\scripts" and restart 3ds Max.

**How to use:**  
Open command panel and the utility panel, there you should see a "Mafia 4ds Tools" rollout.  
To see textures, hit Customize in the top menu > Configure Project Paths > External files. And there add your Mafia "maps" folder.

[**Creating stuff**](https://github.com/pudingus/mafia-4ds-import-export/wiki)
