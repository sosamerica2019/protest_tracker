$( document ).ready(function() {
  if (!$("body").hasClass("login-page") && !$("body").hasClass("seamless")) {
    // Adjust headlines to new design
    $("h1").text($("h2:first").text());
    $("h2:first").hide();
    subtitle = $("h2:first").next("p");
    if (subtitle) {
      $("p.panel--description").html(subtitle.html());
    } else {
      $("p.panel--description").hide();
    }
    subtitle.hide();
    
  }
	
	// regardless, enable collapsible functionality
  $(".collapser").click(function() {
      
    // expecting a data-target attribute of "#div_to_collapse" or similar
    el = $($( this ).attr("data-target"));
    if (el.is(":visible") == false) {
      $(this).addClass("active");
      el.css("visibility", "visible");
      el.slideDown();
    } else {
      $(this).removeClass("active");
      el.slideUp();
    }
  });
	
	// enable X to close flash messages (both warning and success)
  $("a.close--alert").click(function() {
    $( this ).parent().slideUp();
  });
});

function hide_form_element_and_label(id) {
  //$("#" + id).hide();
	//$("label[for='" + id + "']").hide();
	$("#" + id).parents('div.form-group').hide();
}

function show_form_element_and_label(id) {
  //$("#" + id).show();
	//$("label[for='" + id + "']").show();
	$("#" + id).parents('div.form-group').show();
}