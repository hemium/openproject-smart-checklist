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

## Installation in production

For production installations, see the official OpenProject plugin documentation:

- [Plugins on packaged installations](https://www.openproject.org/docs/installation-and-operations/configuration/plugins/)
- [Plugins on Docker installations](https://www.openproject.org/docs/installation-and-operations/installation/docker/#openproject-plugins)

## License

GPL-3.0 — see [LICENSE](LICENSE).
