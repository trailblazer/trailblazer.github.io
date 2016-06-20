module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    sass: {
      options: {
        includePaths: ['bower_components/foundation/scss']
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
          'javascripts/jquery.min.js': 'bower_components/jquery/dist/jquery.js'
        }
      },
      application: {
        files: {
          'javascripts/application.min.js': [
            // "bower_components/jquery/dist/jquery.js", // FIXME: doesn't concat properly.
            'bower_components/foundation/js/foundation.min.js',
            'bower_components/anchor-js/anchor.js',
            'javascripts/highlight.pack.js',
            'bower_components/modernizr/modernizr.js'
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
