// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
// Every Plugin file is surrounded with a closure by dashboard.
// It means that your plugin js code runs in own namespace and can't 
// break any code of other plugins. If you want to make your code available 
// outside this closure you should bind functions to monitoring. 
//  
//       
//= require_tree .  

// This function is visible only inside this file.
function test() {
  //...  
}    

// This function is available from everywhere by calling monitoring.name()
monitoring.name = function() {
  "monitoring"
};

// This is always executed on page load.
$(document).ready(function(){
  // show small loading spinner on active tab during ajax calls 
  $(document).ajaxStart( function() {
    $('.loading-place').addClass('loading');
  });
  $(document).ajaxStop( function() {
    $('.loading-place').removeClass('loading');
  });
}); 

// https://remysharp.com/2010/07/21/throttling-function-calls
// http://stackoverflow.com/questions/4364729/jquery-run-code-2-seconds-after-last-keypress
monitoring.throttle = function(f, delay){
  var timer = null;
  return function(){
      var context = this, args = arguments;
      clearTimeout(timer);
      timer = window.setTimeout(function(){
          f.apply(context, args);
      },
      delay || 500);
  };
}

monitoring.render_overview_pie = function(TYPE,DATA,CNT,W,S) {

  var width =  W || 350;
  var height = W || 350;
  var scale =  S || 1;

  if (CNT == 0) return;

  // from inner 0,5 (100%) to outer 1.05 (0%)
  // not used but maybe it is later userfull so I keep it here ;-)
  /*
  var multiplicator = 0.45 / CNT;
  var arcRadius = [];
  $.each(DATA, function(index, data) {
    var count = data['count'];
    var inner =  1-(multiplicator*count)
    arcRadius.push({inner: inner, outer:1.05});
  } );
  */
  
  nv.addGraph( function() {
      var chart = nv.models.pieChart()
          .x(function(d) { return d.label })
          .y(function(d) { return d.count })
          .width(width)
          .height(height)
          .showLegend(true)
          .showLabels(false)
          .labelsOutside(false)
			    .labelSunbeamLayout(false)
          .noData("There is no Data to display")
          .title(TYPE)
          .donut(true)
          .showTooltipPercent(true)
          //.arcsRadius(arcRadius)
          .donutRatio(0.5)
          .margin({"top": 30, "right": 20, "bottom": 20, "left": 20});

      chart.color(function (d, i) {
        // color scheme is used from _variables.scss
         switch(d.label) {
           case "Low":
              //console.log("Low");
              //$medium-blue
              return ["#226ca9"];
           case "Medium":
              //console.log("Medium");
              //$bright-orange
              return ["#de8a2e"];
           case "High":
              //console.log("High");
              //$deep-orange
              return ["#b34a2a"];
           case "Critical":
              //console.log("Critical");
              //$alarm-red
              return ["#e22"];
           case "Ok":
              //console.log("OK");
              //$medium-green
              return ["#8ab54e"];
           case "Alarm":
              //console.log("Alarm");
              //$alarm-red
              return ["#e22"];
           case "Unknown":
              //console.log("Undetermined");
              return ["#aaa"];
         }
      });

      d3.select("#"+TYPE)
          .datum(DATA)
          .transition().duration(1200)
          .attr('width', width)
          .attr('height', height*scale)
          .call(chart);

      return chart;
  } );

};
  