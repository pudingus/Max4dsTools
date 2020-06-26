## Mafia 4ds Import Export
[![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/pudingus/mafia-4ds-import-export?include_prereleases)](https://github.com/pudingus/mafia-4ds-import-export/releases)

Mafia 4ds plugin for 3ds Max. Based on the work by Mr F, but almost everything has been rewritten and a lot of features were added.  

**Work in progress!**  

![3dsmax_2020-06-25_12-15-09](https://user-images.githubusercontent.com/39903631/85701543-c8233680-b6dd-11ea-992c-d84cce7cb50a.jpg)

### Features
- Sectors & portals
- Meshes with level of detail, billboards
- Dummies
- Changing of [object parameters](https://user-images.githubusercontent.com/39903631/85778105-8668af00-b722-11ea-999c-7ccf81775a53.png) and [material flags](https://user-images.githubusercontent.com/39903631/84805351-67706b80-b004-11ea-846a-2d633223620a.png)
- Vertex normals (smoothing groups, or explicit normals)
- Original scene.4ds files can be imported and exported without losing lighting or collision (depends on how much you edit)

### To do
- Skinned meshes, morphs, bones, mirrors, targets, glows. Files containing these types can be opened, but they will be imported only partially. 


### Installation
[Download here](https://github.com/pudingus/mafia-4ds-import-export/releases)  
Extract the files in "C:\Program Files\Autodesk\3ds Max 2020\scripts" and restart 3ds Max.

3ds Max 2009 or newer required. 

### Usage
Open command panel and the utility panel, there you should see a "Mafia 4ds Tools" rollout.  
To see textures, hit Customize in the top menu > Configure Project Paths > External files. And there add your Mafia "maps" folder.

If you move pivot for an object, you have to reset it before exporting.

See [wiki](https://github.com/pudingus/mafia-4ds-import-export/wiki) for tutorials
