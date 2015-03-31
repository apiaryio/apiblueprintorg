# apiblueprint.org

This repository contains an [apiblueprint.org](http://apiblueprint.org) site. Please, do not confuse it with [API Blueprint specification](https://github.com/apiaryio/api-blueprint/).

## Static site: apiblueprint.org

- `gh-pages` branch
- [Jekyll](http://jekyllrb.com/) site, powered by [GitHub Pages](https://pages.github.com/)
- beware - anything merged in gets automatically deployed live!

### Tips for development

- see `_config.yml` for Jekyll configuration
- install Jekyll by `gem install jekyll` and then develop the site with `jekyll serve`
- if making changes in CoffeeScript files, use `coffee -wcb ./assets` to recompile them

## API: api.apiblueprint.org

- `master` branch
- [Express.js](http://expressjs.com/) app written in CoffeeScript
- Heroku config: `BUILDPACK_URL=https://github.com/ddollar/heroku-buildpack-multi.git` (see [multi buildpack](https://github.com/ddollar/heroku-buildpack-multi/))
- Documentation of the API: [docs.apiblueprintapi.apiary.io](http://docs.apiblueprintapi.apiary.io/)

### Tips for development

- install by `npm install`
- install Ruby dependencies with `bundle install`
- run the app by `coffee app.coffee`
- install `gulp` globally `npm install -g gulp`
- develop with `gulp tdd`
- verify with `gulp test`
