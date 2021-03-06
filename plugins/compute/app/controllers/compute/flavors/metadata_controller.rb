module Compute
  module Flavors
    class MetadataController < Image::ApplicationController
    
      def index
        @flavor = services.compute.flavor(params[:flavor_id])
        @metadata = services.compute.flavor_metadata(params[:flavor_id])
      end
    
      def create
        @metadata = services.compute.new_flavor_metadata(params[:flavor_id])
        @metadata.add(params[:spec])
      end
    
      def destroy
        @metadata = services.compute.new_flavor_metadata(params[:flavor_id])
        @metadata.remove(params[:key])
      end
    
    end
  end
end