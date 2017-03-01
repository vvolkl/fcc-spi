# fcc-spi
Repository with FCC SW integration tools


## Docpage

### Prerequisites:

- Ruby
  - Jekyll
- NPM

### Developing / compiling

In the docpage folder install `jquery` and `bootstrap-sass`:

    npm install jquery
    npm install bootstrap-sass

Change content and for local testing, serve the page with

    jekyll serve --baseurl=

and point your browser to `localhost:4000`.

### Deploying

Build page with

    jekyll build --destination=/afs/cern.ch/exp/fcc/sw/documentation

### Adding releases

Two steps required to add a release to the page:

1. Add it to `docpage/_data/versions.yml`, specifying versions of dependencies and externals
2. Add a post to `docpage/_posts` named `YYYY-MM-DD-versionVV.markdown` (VV standing for major and minor version - name does not really matter except for the date prefix, can also add patch to this string if needed) with following content:
  - front-matter:

    ~~~{.yml}
    ---
    layout: post          # for correct display
    title:  "FCCSW v0.8"  # any title
    thisversion: "0.8"    # corresponding to yaml version
    ---
    ~~~

  - followed by an optional description of the release (release notes) using markdown syntax

### Adding permalinks

Add url and name in `docpage/_data/permalinks.yml`
