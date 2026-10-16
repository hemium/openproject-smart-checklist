# OpenProject Smart Checklist

Jira-style smart checklists for OpenProject work packages. **Work in progress** — this
repository currently contains only the plugin scaffold generated with the
`open_project:plugin` Rails generator; the actual checklist functionality is under
development.

## Requirements

- OpenProject >= 17.3 (developed and tested against OpenProject 17.3.1)
- The Ruby/Node/PostgreSQL toolchain required by the matching OpenProject core checkout
  (see OpenProject's `.ruby-version` and `package.json` engines)

## Development

The plugin lives in a sibling directory next to a local OpenProject development checkout.
Assuming this repo is at `~/repos/openproject-smart-checklist` and core is at
`~/repos/openproject`, tell core to load it by creating
`~/repos/openproject/Gemfile.plugins` with:

```ruby
group :opf_plugins do
  gem "openproject-smart_checklist", path: "../openproject-smart-checklist"
end
```

Then from the core checkout:

```bash
cd ~/repos/openproject
bundle install
bin/dev   # or restart your existing dev stack
```

Verify the plugin is registered:

```bash
bundle exec rails runner 'puts Redmine::Plugin.find(:openproject_smart_checklist).inspect'
```

It should also appear under **Administration → Plugins** (`/admin/plugins`).

Run the plugin's specs from the core checkout (the plugin has no test environment of its
own; specs run inside core's test harness):

```bash
cd ~/repos/openproject
bundle exec rspec ../openproject-smart-checklist/spec/lib/open_project/smart_checklist/engine_spec.rb
```

## Checklist format

One entry per line; leading/trailing whitespace is trimmed and blank lines are ignored.

| Line            | Meaning                              |
|-----------------|--------------------------------------|
| `# text`        | Header (`##`, `###` also allowed)    |
| `- [ ] text`    | Todo item (canonical)                |
| `- [x] text`    | Done item (`- [X]` also allowed)     |
| `- [~] text`    | In-progress item                     |
| `- [-] text`    | Skipped item                         |
| `> text`        | Note attached to the previous item   |

On input, the Jira Smart Checklist shorthand is also accepted: `- text` (todo),
`+ text` (done), `~ text` (in progress), `x text` (skipped). The canonical bracket
form wins, so `- [x] a` parses as a done item. Any other non-blank line becomes a
todo item with that text.

## API v3

The checklist is a plain text attribute `smartChecklist` on work packages, plus a
read-only `smartChecklistProgress` object (`total`, `done`, `inProgress`, `skipped`,
`todo`, `percent`; percent excludes skipped items).

Create an API key under **My account → Access tokens**, then:

```bash
# Read
curl -u "apikey:$APIKEY" http://127.0.0.1:3000/api/v3/work_packages/1 | jq '.smartChecklist, .smartChecklistProgress'

# Update (send the current lockVersion)
curl -u "apikey:$APIKEY" -X PATCH http://127.0.0.1:3000/api/v3/work_packages/1 \
  -H "Content-Type: application/json" \
  -d '{"smartChecklist": "# Sprint\n- [ ] write spec\n- [x] implement\n> note on impl", "lockVersion": 3}'
```

Changes are journaled like any other attribute: they appear in the work package
Activity feed and trigger `work_package:updated` webhooks whose `work_package`
payload includes `smartChecklist` and `smartChecklistProgress`.

## Installation in production

For production installations, see the official OpenProject plugin documentation:

- [Plugins on packaged installations](https://www.openproject.org/docs/installation-and-operations/configuration/plugins/)
- [Plugins on Docker installations](https://www.openproject.org/docs/installation-and-operations/installation/docker/#openproject-plugins)

## License

GPL-3.0 — see [LICENSE](LICENSE).
