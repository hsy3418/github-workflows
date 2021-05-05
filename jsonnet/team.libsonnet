local contains(arr, val) = std.count(arr, val) > 0;

local containsEvery(compare, arr) = std.foldl(
  function(x, y) x && std.setMember(y, compare),
  arr,
  true
);

local objectHasEvery(obj, arr, i=0) = (
  if i == std.length(arr)
  then true
  else if std.objectHasAll(obj, arr[i]) && i < std.length(arr)
  then objectHasEvery(obj, arr, i + 1)
  else false
);

# # # # # # # # # # # # # # # # # #

    local UserType = {
       attrs: [],



      groups:: error std.format('User "%s" is missing parameter "groups"', self.lanid),
  lanid: error std.format('Internal error: User "%s" field "lanid" not being set', self.lanid),
  team: error std.format('Internal error: User "%s" field "team" not being set', self.lanid),
  union: error std.format('Internal error: User "%s" field "union" not being set', self.lanid),
};

local GroupType = {
  resources: {},
  description: '',
  include:: [],
  include_unions: true,
  team: error std.format('Internal error: Group "%s" field "team" not being set', self.name),
  name: error std.format('Internal error: Group "%s" field "name" not being set', self.name),
  union: error std.format('Internal error: Group "%s" field "union" not being set', self.name),
  users: error std.format('Internal error: Group "%s" field "users" not being set', self.name),
};

local TeamType = {
  name: error 'A team is missing the "name" field',
  groups: error std.format('Team "%s" is missing the "groups" field', self.name),
  teams: error std.format('Internal error: Team "%s" field "teams" not being set', self.name),
  unions:: [],
  users: error std.format('Team "%s" is missing the "users" field', self.name),
  # Methods
  usersByAttr: error std.format('Internal error: Team "%s" method "usersByAttr" is missing', self.name),
};

# # # # # # # # # # # # # # # # # #

local ValidateUser(user, groups) = (
  if !std.isArray(user.attrs)
  then error std.format('User "%s" attrs parameter must be an array', user.lanid)

  else if !std.isArray(user.groups)
  then error std.format('User "%s" groups parameter must be an array', user.lanid)

  else if !std.foldr(function(x, y) x && y, [ std.isString(group) for group in user.attrs ], true)
  then error std.format('User "%s" attrs parameter must be an array of strings', user.lanid)

  else if !std.foldr(function(x, y) x && y, [ std.isString(group) for group in user.groups ], true)
  then error std.format('User "%s" groups parameter must be an array of strings', user.lanid)

  else if !std.foldr(function(x, y) x && y, [ contains(std.objectFields(groups), group) for group in user.groups ], true)
  then error std.format('User "%s" has specified a group that hasn\'t been defined in this team', user.lanid)

  else user
);

local ValidateGroup(group) = (
  if contains(std.objectFields(group.resources), 'azuread')

  then if !contains(std.objectFields(group.resources.azuread), 'name')
  then error std.format('Group "%s" has specified the attribute "azuread" but is missing the required field "azuread.name"', group.name)

  else if !std.isString(group.resources.azuread.name)
  then error std.format('Group "%s" field "azuread.name" must be a string', group.name)

  else if group.resources.azuread.name == ''
  then error std.format('Group "%s" field "azuread.name" can\'t be empty', group.name)

  else group

  else group
);

local ValidateGroups(groups) = (
  if std.isArray(
    std.foldr(

      function(x, y) (
        local group = groups[x];

        if std.objectHas(group.resources, 'azuread') && group.resources.azuread.name != null
        then if contains(y, group.resources.azuread.name)
        then error std.format('AzureAD group names must be unique, "%s" defined multiple times.', group.resources.azuread.name)
        else y + [ group.resources.azuread.name ]
        else y
      ),
      std.objectFields(groups),
      []
    )
  )
  then groups
);

local ValidateTeam(team) = (

  if !std.isString(team.name)
  then error 'A Team "name" field is not a string'

  else if !std.isObject(team.groups)
  then error std.format('Team "%s" field "groups" not an object', team.name)

  else if !std.isArray(team.unions)
  then error std.format('Team "%s" field "unions" not an array', team.name)

  else if !std.isObject(team.users)
  then error std.format('Team "%s" field "users" not an object', team.name)

  else team
);

# # # # # # # # # # # # # # # # # #

local FmtGrpUnionName(team, name) = if !std.startsWith(name, team) then std.format('%s/%s', [ team, name ]) else name;

local BuildIncludedUsers(inc, group_k, include_unions) = (
  local err = std.format('Group "%s" field "include" has an item that is not a reference to a user (<team>.users.<user>), map of users (<team>.usersByAttr(<attr>)), group (<team>.groups.<group>) or team (<team>)', group_k);

  if !std.isObject(inc)
  then error err

  else if objectHasEvery(inc, [ 'attrs', 'lanid', 'team', 'union' ])
  then { [inc.lanid]: inc }

  else if objectHasEvery(inc, [ 'description', 'resources', 'name', 'team', 'union', 'users' ])
  then
    if include_unions
    then inc.users
    else {
      [if !inc.users[lanid].union then lanid]: inc.users[lanid]
      for lanid in std.objectFields(inc.users)
    }

  else if objectHasEvery(inc, [ 'groups', 'name', 'teams', 'users' ])
  then
    if include_unions
    then inc.users
    else {
      [if !inc.users[lanid].union then lanid]: inc.users[lanid]
      for lanid in std.objectFields(inc.users)
    }

  else if std.foldr(
    function(x, y) x && y,
    [












                  if !std.isObject(inc[k])
      then false
            else objectHasEvery(inc[k], [ 'attrs', 'groups' ])
      for k in std.objectFields(inc)
    ],
    true
  ) then
    if include_unions
    then {
      [lanid]: inc[lanid]
      for lanid in std.objectFields(inc)
    }
    else {
      [if !inc[lanid].union then lanid]: inc[lanid]
      for lanid in std.objectFields(inc)
    }

  else error err
);

# # # # # # # # # # # # # # # # # #

function(t) (

  local InputData = TeamType + t;

  ValidateTeam(InputData) {

    local User(lanid) = (
      UserType
      + InputData.users[lanid]
      + {
        lanid: lanid,
        team: $.name,
        union: false,
      }
    ),

    local UnionUser(user) = (
      if std.objectHas(super.users, user.lanid)
      then error std.format('User "%s" has been defined in both "%s" and "%s"', [ user.lanid, $.name, user.team ])
      else user {
        union: true,
      }
    ),

    local Group(group_k) = (
      local group = InputData.groups[group_k];

      GroupType
      + group
      + {
        name: group_k,
        team: $.name,
        union: false,
        users: std.foldl(
          function(x, y) x + y,
          [
            BuildIncludedUsers(inc, group_k, self.include_unions)
            for inc in self.include
          ],
          {

            [if contains($.users[lanid].groups, group_k) then lanid]: $.users[lanid]
            for lanid in std.objectFields($.users)
          }
        ),
      }
    ),

    local UnionGroup(group) = (
      group {
        union: true,
      }
    ),

    users: {
      # Validate the user against the groups defined within their
      # team. Validation against `$.groups` is a 10x perf hit.
      [lanid]: ValidateUser(User(lanid), InputData.groups)
      for lanid in std.objectFields(super.users)
    } + {
      [lanid]: UnionUser(union.users[lanid])
      for union in super.unions
      for lanid in std.objectFields(union.users)
    },

    groups: ValidateGroups({
      [group_k]: ValidateGroup(Group(group_k))
      for group_k in std.objectFields(super.groups)
    } + {
      [FmtGrpUnionName(union.groups[name].team, name)]: UnionGroup(union.groups[name])
      for union in super.unions
      for name in std.objectFields(union.groups)
    }),

    teams: [
      teams
      for union in super.unions
      for teams in union.teams
    ] + [ {
      name: $.name,
    } ],

    # Methods

    # usersByAttr returns a map of users from the team (excluding
    # unions) which contain a matching attr stirng.
    usersByAttr(attr)::
      {
        [if contains($.users[lanid].attrs, attr) && !$.users[lanid].union then lanid]: $.users[lanid]
        for lanid in std.objectFields($.users)
      },

  }

)
