# Quaternius IK-Rigged Characters — Godot 4 Addon

IK-rigged humanoid character scenes built on [Quaternius](https://quaternius.com)
CC0 Superhero models, with a full animation library. Drop-in addon for Godot 4.6+.

This is intentionally a **foundation, not a finished system**. There is no
animation controller, state machine, or procedural solver included — just a
clean full-body IK rig and a ready-to-use animation library. Take it, make it
yours.

## Installation

**Via the Godot Asset Library** (in-editor): search for *Quaternius IK Rigged*,
download, and install. The files land under `addons/quaternius_ik_rigged/`.

**Manual:** copy the `addons/quaternius_ik_rigged/` folder into your project's
`addons/` directory. Godot will import the assets on next focus.

No plugin needs to be enabled — this is an asset pack, not an editor plugin.
Just open one of the rigged scenes below.

## Requirements

- Godot **4.6+** (uses the `TwoBoneIK3D` node)

## Contents

```
addons/quaternius_ik_rigged/
├── UAL1_Standard.glb          # Animation library (Godot-retargeted)
├── Humanoid_map.tres          # Animation retargeting profile (BoneMap)
├── Godot - UE/                # Source GLTF models + textures (Superhero Male/Female)
├── Quaternius Meshes/         # Extracted ArrayMesh resources (eyes, eyebrows, body)
├── Animations/                # Extracted Animation resources (.res)
└── Models_with_rigging/
    ├── Master_Rigged.tscn     # Male — full IK rig + AnimationPlayer
    ├── Female_Rigged.tscn     # Female — full IK rig + AnimationPlayer
    └── Male_rigged.tscn       # Male variant
```

## Scene structure

Each rigged scene follows this hierarchy:

```
[Node3D]  (root)
├── Armature
│   └── GeneralSkeleton (Skeleton3D)
│       ├── Eyebrows, Eyes, Body  (MeshInstance3D)
│       ├── L_ArmIK3D   (TwoBoneIK3D)  LeftUpperArm → LeftLowerArm → LeftHand
│       ├── R_ArmIK3D   (TwoBoneIK3D)  RightUpperArm → RightLowerArm → RightHand
│       ├── L_LegIK3D   (TwoBoneIK3D)  LeftUpperLeg → LeftLowerLeg → LeftFoot
│       └── R_LegIK3D   (TwoBoneIK3D)  RightUpperLeg → RightLowerLeg → RightFoot
├── L_Hand_target / L_Hand_pole   (Marker3D)
├── R_Hand_target / R_Hand_pole   (Marker3D)
├── L_foot_target / L_foot_pole   (Marker3D)
├── R_foot_target / R_foot_pole   (Marker3D)
├── StomachLookAt                 (Marker3D)
└── AnimationPlayer               (linked to UAL1_Standard animation library)
```

Move the `Marker3D` targets and poles at runtime to drive the IK chains.
Each `TwoBoneIK3D` has `influence` set to `0.0` by default — ramp it up to
blend between the animation pose and full IK.

## Animations (UAL1_Standard)

| Category | Clips |
|---|---|
| Locomotion | Idle, Walk, Walk_Formal, Jog_Fwd, Sprint, Crouch_Idle, Crouch_Fwd |
| Jump | Jump_Start, Jump, Jump_Land |
| Combat — Melee | Punch_Jab, Punch_Cross, Push, Sword_Idle, Sword_Attack, Sword_Attack_RM |
| Combat — Ranged | Pistol_Idle, Pistol_Aim_Up/Neutral/Down, Pistol_Shoot, Pistol_Reload |
| Magic | Spell_Simple_Enter, Spell_Simple_Idle, Spell_Simple_Shoot, Spell_Simple_Exit |
| Reactions | Hit_Chest, Hit_Head, Death01, Roll, Roll_RM |
| Interactions | Interact, PickUp_Table, Fixing_Kneeling, Driving |
| Social | Dance, Idle_Talking, Idle_Torch, Sitting_Enter, Sitting_Idle, Sitting_Talking, Sitting_Exit |
| Water | Swim_Idle, Swim_Fwd |
| Utility | A_TPose |

## License & credits

Released under [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)
(see [LICENSE](LICENSE)) — public domain, no attribution required.

Models and animations by [Quaternius](https://quaternius.com), also CC0.
Attribution is appreciated but not required.
