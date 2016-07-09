module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    sass: {
      options: {
        includePaths: ['bower_components/foundation-sites/scss', // to find util/util, foundation.
        // "bower_components/slick-carousel/slick",
          "bower_components/font-awesome/scss"
        ]
      },
      dist: {
        options: {
          outputStyle: 'compressed'
        },
        files: {
          // compile into css/application.css.
          'css/application.css': 'scss/application.scss'
        }
      }
    },

    uglify: {
      jquery: {
        files: {
          'javascripts/jquery.min.js': ['bower_components/jquery/dist/jquery.js']
        }
      },
      application: {
        files: {
          'javascripts/application.min.js': [
            // "bower_components/jquery/dist/jquery.js", // FIXME: doesn't concat properly.
            'bower_components/foundation-sites/dist/foundation.js',
            'bower_components/what-input/what-input.min.js',
            'bower_components/anchor-js/anchor.js',
            'bower_components/highlightjs/highlight.pack.js',
            // "bower_components/slick-carousel/slick/slick.js",
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
