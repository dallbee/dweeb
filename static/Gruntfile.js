module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    sass: {
      dist: {
        options: {
          style: 'compressed'
        },
        files: {
          'public/dist/css/main.css': 'source/styles/main.scss'
        }
      }
    },

    browserify: {
      dist: {
        files: {
          'public/dist/js/main.js': 'source/scripts/main.js'
        }
      }
    },

    uglify: {
      build: {
        src: 'public/dist/js/main.js',
        dest: 'public/dist/js/main.js'
      }
    },

    watch: {
      grunt: { files: ['Gruntfile.js'] },

      sass: {
        files: 'source/styles/**/*.scss',
        tasks: ['sass']
      },

      browserify: {
        files: 'source/scripts/**/*.js',
        tasks: ['browserify']
      },

      uglify: {
        files: 'public/dist/js/main.js',
        tasks: ['uglify']
      }
    }
  });

  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-contrib-sass');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-watch');

  grunt.registerTask('build', ['sass', 'browserify', 'uglify']);
  grunt.registerTask('default', ['build', 'watch']);
}
