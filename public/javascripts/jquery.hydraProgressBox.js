(function($) {
  
  $.fn.hydraProgressBox = {    
    /*
    *  hydraProgressBox.checkUncheckProgress
    *  Change the checked/unchecked status of an item in the Progress Box
    *  @param 
    *
    * ie. 
    * hydraProgressBox.checkUncheckProgress($(true, 'pbCitationDetails');
    */
    checkUncheckProgress: function(elementId, bool) {  
        el = $("#"+elementId);
        if (bool) {
          el.addClass("progressItemChecked") 
          el.css("background-image",'url(/images/chkbox_checked.png)')
          // el.show();
        } else {
          el.removeClass("progressItemChecked")    
          el.css("background-image",'url(/images/chkbox_empty.png)')      
        };
        $.fn.hydraProgressBox.testReleaseReadiness();
    },
    
    showProcessingInProgress: function(elementId) {
      el = $("#"+elementId);
      el.css("background-image", 'url(/images/processing.gif)');
      // el.show();
    },
    
    testReleaseReadiness: function() {
      var titleProvided = ($("#title_info_main_title").attr("value").length > 0);
      var authorLastProvided = ($("#person_0_last_name").attr("value").length > 0);
      var authorFirstProvided =  ($("#person_0_first_name").attr("value").length > 0 );
      var licenseAgreedTo = ($("#copyright_uvalicense").attr("value")=="yes");
      var fileUploaded = ( $("a.destroy_file_asset").length > 0); 

      var releaseIsReady= false;
      if (fileUploaded && titleProvided && authorLastProvided && authorFirstProvided && licenseAgreedTo) {
					$("#submitForRelease").enable();
          releaseIsReady=true;
      } else {
          $('#submitForRelease').attr("disabled", "disabled");			
      }
      return releaseIsReady;
    }
  };
})( jQuery );
