module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    sass: {
      options: {
        includePaths: ['bower_components/foundation/scss', "bower_components/slick-carousel/slick", "bower_components/jquery-ui/themes/base"]
      },
      dist: {
        options: {
          outputStyle: 'compressed'
        },
        files: {
          // compile into css/style.css.
          'css/style.css': 'scss/style.scss'
        }
      }
    },

    uglify: {
      jquery: {
        files: {
          'javascripts/jquery.min.js': ['bower_components/jquery/dist/jquery.js', "bower_components/jquery-ui/jquery-ui.js"]
        }
      },
      application: {
        files: {
          'javascripts/application.min.js': [
            // "bower_components/jquery/dist/jquery.js", // FIXME: doesn't concat properly.
            'bower_components/foundation/js/foundation.min.js',
            'bower_components/anchor-js/anchor.js',
            'bower_components/highlightjs/highlight.pack.js',
            'bower_components/modernizr/modernizr.js',
            "bower_components/slick-carousel/slick/slick.js",
          ]
        }
      }
    },

    watch: {
      grunt: { files: ['Gruntfile.js'] },

      sass: {
        files: 'scss/**/*.scss',
        tasks: ['sass']
      }
    }
  });

  grunt.loadNpmTasks('grunt-sass');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-uglify');

  grunt.registerTask('build', ['sass', "uglify"]);
  grunt.registerTask('default', ['build','watch']);
}
