# y_core

y_core is the core from Ynot's Workshop, aimed to be a successor to qbx_core, and continuing the development of a solid foundation for building easy-to-use, performant, and secure server resources.

The ***main goal*** is to promote better practices, so of course, not being backwards compatible is a feature, not a bug.
*(if you care that your 2021 qbus resource still works *(that's what backwards compatibility mean btw)*, the Qbox team will love you!)*

Other ***goals*** include:
- A more modular system to be more organized
- "Bloat" the core with systems that every server needs and are often poorly implemented in separate resources (animations, reputation etc)
- An actual proper DB
- Reducing the dependencies to a minimum (ideally only oxmysql & ox_lib)
- Provide some kind of migration from qbox/qb, mostly for the DB.


## Current Plan
- [ ] new file structure
    - [ ] Use modules
        - [ ] discord
        - [ ] status
        - [ ] player
        - [ ] vehicle
        - [ ] animation
        - [ ] skin
        - [ ] group
        - [ ] crew
        - [ ] weapon
        - [ ] vehicle
        - [ ] reputation

- [ ] New Database Structure
- [ ] New group system
- [ ] New vehicle system
- [ ] New animation system

### Maybes
- [ ] Weapon stat module, modifying weapon stats using data stored in the database for easy modification by resources & hot-reloading
- [ ] Vehicle stat module, modifying vehicle stats using data stored in the database for easy modification by resources & hot-reloading

## Features

- Built-in multicharacter
- Built-in queue system for full servers
- Logger system
- Exports (a lot of them)

## Modules
The core makes available several optional modules for developers to import into their resources:
- PlayerData: A module to access player data client-side
- Hooks: For developers to provide Ox style hooks to extend the functionality of their resources
- Lib: Common functions for tables, strings, math, native audio, vehicles, and drawing text.

### Planned Modules
- Vehicle: Everything related to vehicles
- Animation: Everything related to animations
- Skin: A base system for character skin
- Groups: A whole new group system, replacing the gang/job system
- Crews: A crew system, similar to a group, but to a smaller scale to use in multiplayer (legal or not) activities
- Reputation: A reputation system, to track player, group, and crew reputation in different aspects (job, crime, etc.)

# Dependencies

- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)

#

⚠️We advise not modifying the core outside of the config files⚠️

If you feel something is missing or want to suggest additional functionality that can be added to y_core, bring it up in an Issue!

Thank you to everyone and their contributions (large or small!), as this wouldn't have been possible.
