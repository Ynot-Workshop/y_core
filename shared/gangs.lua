---Gang names must be lower case (top level table key)
---@type table<string, Gang>
---TODO: along with new groups system, move this to the db by an import sql file
return {
    ['none'] = {
        label = 'No Gang',
        grades = {
            [0] = {
                name = 'Unaffiliated'
            },
        },
    },
    ['lostmc'] = {
        label = 'The Lost MC',
        grades = {
            [0] = {
                name = 'Recruit'
            },
            [1] = {
                name = 'Enforcer'
            },
            [2] = {
                name = 'Shot Caller'
            },
            [3] = {
                name = 'Boss',
                isboss = true,
                bankAuth = true
            },
        },
    },
    ['ballas'] = {
        label = 'Ballas',
        grades = {
            [0] = {
                name = 'Recruit'
            },
            [1] = {
                name = 'Enforcer'
            },
            [2] = {
                name = 'Shot Caller'
            },
            [3] = {
                name = 'Boss',
                isboss = true,
                bankAuth = true
            },
        },
    },
    ['vagos'] = {
        label = 'Vagos',
        grades = {
            [0] = {
                name = 'Recruit'
            },
            [1] = {
                name = 'Enforcer'
            },
            [2] = {
                name = 'Shot Caller'
            },
            [3] = {
                name = 'Boss',
                isboss = true,
                bankAuth = true
            },
        },
    },
    ['cartel'] = {
        label = 'Cartel',
        grades = {
            [0] = {
                name = 'Recruit'
            },
            [1] = {
                name = 'Enforcer'
            },
            [2] = {
                name = 'Shot Caller'
            },
            [3] = {
                name = 'Boss',
                isboss = true,
                bankAuth = true
            },
        },
    },
    ['families'] = {
        label = 'Families',
        grades = {
            [0] = {
                name = 'Recruit'
            },
            [1] = {
                name = 'Enforcer'
            },
            [2] = {
                name = 'Shot Caller'
            },
            [3] = {
                name = 'Boss',
                isboss = true,
                bankAuth = true
            },
        },
    },
    ['triads'] = {
        label = 'Triads',
        grades = {
            [0] = {
                name = 'Recruit'
            },
            [1] = {
                name = 'Enforcer'
            },
            [2] = {
                name = 'Shot Caller'
            },
            [3] = {
                name = 'Boss',
                isboss = true,
                bankAuth = true
            },
        },
    }
}