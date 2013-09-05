'use strict';

module.exports = function(grunt) {

  grunt.initConfig({

    replace: {
      example: {
        src: ['test/text_files/example.txt'],
        dest: 'test/modified/',
        replacements: [{ 
          from: 'Hello', 
          to: 'Good bye' 
        }, { 
          from: /(f|F)(o{2,100})/g, 
          to: 'M$2' 
        }, { 
          from: /"localhost"/, 
          to: function (matchedWord, index, fullText, regexMatches) {
            return '"www.mysite.com"';
          } 
        }, { 
          from: '<p>Version:</p>', 
          to: '<p>Version: <%= grunt.template.date("18 Feb 2013", "yyyy-mm-dd") %></p>'
        }, {
          from: /[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{2,4}/g,
          to: function() {
            return "<%= grunt.template.date('18 Feb 2013', 'dd/mm/yyyy') %>";
          }
        }]
      },

      overwrite: {
        src: ['test/modified/example.txt'],
        overwrite: true,
        replacements: [{
          from: 'World',
          to: 'PLANET'
        }]
      },

      disable_template_processing: {
        src: ['test/text_files/template-example.txt'],
        dest: 'test/modified/',
        options: {
          processTemplates: false
        },
        replacements: [{
          from: /url\(.*\)/g,
          to: function () {
            return "url(<% some unprocessed text %>)";
          }
        }]
      }
     
    },


  });

  grunt.loadTasks('tasks');
  grunt.registerTask('default', 'replace');

};


