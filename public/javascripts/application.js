// application.js

$(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This cannot be undone!");
    if (ok) {
      //this.submit();
			
			var form = $(this); // this = event = form. wraps the form in a jquery object. allows us to use methods that jquery provdies.
			
      var request = $.ajax({
				url: form.attr("action"),  // where we are sending request too
				method: form.attr("method")  // define what method to use (http method)
	    });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status == 204) {   // checks status code response
          form.parent("li").remove(); // removes list itme form the page
        } else if (jqXHR.status == 200) {
          document.location = data;  // data = url returned by code in delete route in todo.rb ("/lists")
        }
      });

		}
  });
});