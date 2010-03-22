require "stanford/ead_descriptor"
# Stanford SolrHelper is a controller layer mixin. It is in the controller scope: request params, session etc.
# 
# NOTE: Be careful when creating variables here as they may be overriding something that already exists.
# The ActionController docs: http://api.rubyonrails.org/classes/ActionController/Base.html
#
# Override these methods in your own controller for customizations:
# 
# class HomeController < ActionController::Base
#   
#   include Stanford::SolrHelper
#   
#   def solr_search_params
#     super.merge :per_page=>10
#   end
#   
# end
#
module Stanford::SaltControllerHelper
  
  def find_folder_siblings(document=@document)
    if document[:series_facet] && document[:box_facet] && document[:folder_facet]
      folder_search_params = {}
      folder_search_params[:phrases] = [{:series_facet => document[:series_facet].first}]
      if document[:box_facet]
        folder_search_params[:phrases] << {:box_facet => document[:box_facet].first}
        if document[:folder_facet]
          folder_search_params[:phrases] << {:folder_facet => document[:folder_facet].first}
        end
      end
      @folder_siblings = Blacklight.solr.find folder_search_params
    else 
      @folder_siblings = nil
    end
  end
  
  # Returns a list of datastreams for download.
  # Uses user's roles and "mime_type" value in submitted params to decide what to return.
  # if you pass the optional argument of :canonical=>true, it will return the canonical datastream for this object (a single object not a hash of datastreams)
  def downloadables(fedora_object=@fedora_object, opts={})
    if opts[:canonical]
      mime_type = opts[:mime_type] ? opts[:mime_type] : "application/pdf"
      result = filter_datastreams_for_mime_type(fedora_object.datastreams, mime_type).sort.first[1]
    elsif editor? 
      if params["mime_type"] == "all"
        result = fedora_object.datastreams
      else
        result = Hash[]
        fedora_object.datastreams.each_pair do |dsid,ds|
          if !ds.new_object?
            mime_type = ds.attributes["mimeType"] ? ds.attributes["mimeType"] : ""
            if mime_type.include?("pdf") || ds.label.include?("_TEXT.xml") || ds.label.include?("_METS.xml")
             result[dsid] = ds
            end 
          end 
        end
      end
    else
      result = Hash[]
      fedora_object.datastreams.each_pair do |dsid,ds|
         if ds.attributes["mimeType"].include?("pdf")
           result[dsid] = ds
         end  
       end
    end 
    # puts "downloadables result: #{result}"
    return result    
  end
  
  private
  
  def filter_datastreams_for_mime_type(datastreams_hash, mime_type)
    result = Hash[]
    datastreams_hash.each_pair do |dsid,ds|
      ds_mime_type = ds.attributes["mimeType"] ? ds.attributes["mimeType"] : ""
      if ds_mime_type == mime_type
       result[dsid] = ds
      end  
    end
    return result
  end
end