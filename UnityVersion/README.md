# FreeLife RP — Unity offline prototype

A separate Unity implementation of an original, offline, third-person city role-play prototype. The existing Godot project at the repository root remains unchanged.

## Requirements
- Unity 2022.3 LTS
- Android Build Support, Android SDK & NDK, and OpenJDK modules for Android builds.

## Open and run
1. Install Unity 2022.3 LTS using Unity Hub.
2. Add this repository's `UnityVersion` folder as a project.
3. Open it and wait for Unity to import scripts.
4. The editor setup script creates a starter scene and adds it to Build Settings.
5. Press Play.

## Prototype systems
- Runtime-generated low-poly test city, roads, buildings, trees and daylight.
- Third-person capsule character and follow camera.
- A test vehicle with enter/exit and basic driving.
- Touch buttons for walking and vehicle movement.
- Five job locations: taxi, bus, mechanic, teacher and farmer.
- Cash and bank balance, a house purchase point, and local save/load using PlayerPrefs.
- Offline play; no server connection is used.

## Android APK
In Unity, install Android Build Support, then choose **File → Build Settings → Android → Switch Platform → Build**. Select Landscape orientation if it is not already selected. Android signing and testing on a physical phone are still required.

## Current limitations
This is an early prototype, not a finished GTA-like game. The city uses primitive placeholder geometry; character animation, detailed vehicle physics, traffic AI, pedestrians, missions, shop interiors, Persian font shaping, and performance tuning remain to be developed. The code has been committed but has not yet been compiled or tested in the Unity Editor or on an Android device.

## Legal
This is an original project inspired by the broad open-world role-play genre. It does not include Rockstar or ArSaCiA proprietary source code, maps, models, textures, audio, or branding.
