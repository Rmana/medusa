
require 'solr'

require 'lib/shelver/extractor.rb'

INDEX_FULL_TEXT = true unless defined?(INDEX_FULL_TEXT) 

module Shelver
class Indexer

  #
  # Class variables
  #
  @@unique_id = 0

  def self.unique_id
    @@unique_id
  end

  #
  # Member variables
  #
  attr_accessor :connection, :extractor

  #
  # This method performs initialization tasks
  #
  def initialize()
    @extractor = Extractor.new
    connect
  end

  #
  # This method connects to the Solr instance
  #
  def connect
    # @connection = Solr::Connection.new( SHELVER_SOLR_URL, :autocommit => :on )
    @connection = Solr::Connection.new( Blacklight.solr_config[:url], :autocommit => :on )
  end

  #
  # This method extracts the full-text keywords from the given Fedora object's full-text datastream
  #
  def extract_full_text( obj, ds_name )
    full_text_ds = Repository.get_datastream( obj, ds_name )
    keywords = extractor.extractFullText( full_text_ds.content )
  end

  #
  # This method extracts the facet categories from the given Fedora object's external tag datastream
  #
  def extract_facet_categories( obj, ds_name )
    facet_ds = Repository.get_datastream( obj, ds_name )
    extractor.extract_facets( facet_ds.content )
    #extractor.extractFacetCategories( facet_ds.content )
  end
  
  #
  # This method extracts the extProperties info from the given Fedora object's external tag datastream
  #
  def extract_ext_properties( obj, ds_name )
    ext_properties_ds = Repository.get_datastream( obj, ds_name )
    extractor.extract_ext_properties( ext_properties_ds.content )
  end

  #
  # This method extracts the facet categories from the given Fedora object's external tag datastream
  #
  def extract_xml_to_solr( obj, ds_name, solr_doc=Solr::Document.new )
    xml_ds = Repository.get_datastream( obj, ds_name )
    extractor.xml_to_solr( xml_ds.content, solr_doc )
  end
  
  def extract_tags(obj, ds_name)
    tags_ds =  Repository.get_datastream( obj, ds_name )
    extractor.extract_tags( tags_ds.content )
  end
  
  #
  # This method creates a Solr-formatted XML document
  #
  def create_document( obj )

    # retrieve a comprehensive list of all the datastreams associated with the given
    #   object and categorize each datastream based on its filename
    full_text_ds_names = Array.new
    ext_properties_ds_names = Array.new
    xml_ds_names = Array.new
    properties_ds_names = []
    ds_names = Repository.get_datastreams( obj )
    ds_names.each do |ds_name|
      if( ds_name =~ /.*.xml$/ and ds_name !~ /.*_TEXT.*/ and ds_name !~ /.*_METS.*/ and ds_name !~ /.*_LogicalStruct.*/ )
        full_text_ds_names << ds_name
      elsif( ds_name =~ /extProperties/ )
        ext_properties_ds_names << ds_name
      elsif( ds_name =~ /descMetadata/ )
        xml_ds_names << ds_name
      elsif ds_name =~ /^properties/
        properties_ds_names << ds_name
      end
    end

    # extract full-text
    keywords = String.new
    if INDEX_FULL_TEXT
      full_text_ds_names.each do |full_text_ds_name|
        keywords += extract_full_text( obj, full_text_ds_name )
      end
    end
    # extract facet categories
    ext_properties = extract_ext_properties( obj, ext_properties_ds_names[0] )
    tags = extract_tags(obj, properties_ds_names[0])
    (ext_properties[:facets] ||={}).merge!(tags)

    # create the Solr document
    solr_doc = Solr::Document.new
    solr_doc << Solr::Field.new( :id => "#{obj.pid}" )
    solr_doc << Solr::Field.new( :text => "#{keywords}" )
    Indexer.solrize(ext_properties, solr_doc)
    #facets.each { |key, value| solr_doc << Solr::Field.new( :"#{key}_facet" => "#{value}" ) }
    
    # Pass the solr_doc through extract_simple_xml_to_solr
    xml_ds_names.each { |ds_name| extract_xml_to_solr(obj, ds_name, solr_doc)}

    # increment the unique id to ensure that all documents in the search index are unique
    @@unique_id += 1

    return solr_doc
  end

  #
  # This method adds a document to the Solr search index
  #
  def index( obj )
    print "Indexing '#{obj.pid}'..."
    solr_doc = create_document( obj )
    connection.add( solr_doc )
    puts "done"
  end

  #
  # This method queries the Solr search index and returns a response
  #
  def query( query_str )
    response = conn.query( query_str )
  end

  #
  # This method prints out the results of the given query string by iterating through all the hits
  #
  def printResults( query_str )
    query( query_str ) do |hit|
      puts hit.inspect
    end
  end

  #
  # This method deletes a document from the Solr search index by id
  #
  def deleteDocument( id )
    connection.delete( id )
  end
  
  # Populates a solr doc with values from a hash.  
  # Accepts two forms of hashes:
  # => {'technology'=>["t1", "t2"], 'company'=>"c1", "person"=>["p1", "p2"]}
  # or
  # => {:facets => {'technology'=>["t1", "t2"], 'company'=>"c1", "person"=>["p1", "p2"]} }
  #
  # Note that values for individual fields can be a single string or an array of strings.
  def self.solrize( input_hash, solr_doc=Solr::Document.new )    
    facets = input_hash.has_key?(:facets) ? input_hash[:facets] : input_hash
    facets.each_pair do |facet_name, value|
      case value.class.to_s
      when "String"
        solr_doc << Solr::Field.new( :"#{facet_name}_facet" => "#{value}" )
      when "Array"
        value.each { |v| solr_doc << Solr::Field.new( :"#{facet_name}_facet" => "#{v}" ) } 
      end
    end
    
    if input_hash.has_key?(:symbols) 
      input_hash[:symbols].each do |symbol_name, value|
        case value.class.to_s
        when "String"
          solr_doc << Solr::Field.new( :"#{symbol_name}_s" => "#{value}" )
        when "Array"
          value.each { |v| solr_doc << Solr::Field.new( :"#{symbol_name}_s" => "#{v}" ) } 
        end
      end
    end
    return solr_doc
  end
  
  def extr
    
  end
  

  private :connect, :create_document, :extract_full_text, :extract_facet_categories

end
end
