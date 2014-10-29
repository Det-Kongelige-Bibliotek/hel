module Bibframe
  module Concerns
    # Passes missing methods up to bfMetadata
    # and reflects this by overriding respond_to?
    module MetadataDelegation
      extend ActiveSupport::Concern

      included do
        # Try to delegate to datastream if possible
        def method_missing(meth, *args)
          super unless bfMetadata.respond_to?(meth)
          args = args.first if args.size == 1
          args.present? ? bfMetadata.send(meth, args) : bfMetadata.send(meth)
        end

        # update respond_to to include delegated methods
        def respond_to?(meth, include_private = false)
          bfMetadata.respond_to?(meth) || super(meth, include_private)
        end
      end
    end
  end
end
