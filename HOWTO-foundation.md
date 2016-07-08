bower install foundation-sites
Gruntfile.js
package.json

nick@sunrise:~/projects/fou6$ sudo npm install -g grunt-cli
npm install
  installs grunts dependencies in node_modules

grunt
  compiles files using SASS modules and all that shit

  => creates javascripts/application.min.js
  problem is, it doesn't say when it can't find JS files in Gruntfile.
  * do we have to load plugins/ ourselves?

.gitigore
  node_modules

  because the can be install via npm install



scss/application.scss
  @import "settings",
    "foundation";

    pulls foundation via Gruntfile.js from bower_components
    reference application.css in head.html
http://foundation.zurb.com/sites/docs/sass.html


_settings
http://foundation.zurb.com/sites/docs/sass.html
copy _settings to your scss dir
