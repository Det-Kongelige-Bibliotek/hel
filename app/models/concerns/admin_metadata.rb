# -*- encoding : utf-8 -*-
module Concerns
  # Handles the administrative metadata.
  module AdminMetadata
    extend ActiveSupport::Concern

    included do
      has_metadata :name => 'adminMetadata', :type => Datastreams::AdminDatastream
      has_metadata :name => 'permissionMetadata', :type=> Datastreams::PermissionMetadata

      has_attributes :activity, :workflow_status, :embargo, :embargo_date, :embargo_condition, :access_condition,
                     :copyright, :material_type, :availability, :collection, :type,
                     datastream: 'adminMetadata', :multiple => false

      def permissions=(val)
        permissionMetadata.remove_permissions
        val['instance']['group'].each do |access,groups|
          groups.each{|g| permissionMetadata.add_instance_permission(g,access,'group')} unless groups.blank?
        end
        val['file']['group'].each do |access,groups|
          groups.each{|g| permissionMetadata.add_file_permission(g,access,'group')} unless groups.blank?
        end
      end

      def permissions
        permissions = {}
        permissions['file'] = {}
        permissions['file']['group'] = {}

        permissions['file']['group']['discover'] = permissionMetadata.get_file_groups('discover','group')
        permissions['file']['group']['read'] = permissionMetadata.get_file_groups('read','group')
        permissions['file']['group']['edit'] = permissionMetadata.get_file_groups('edit','group')

        permissions['instance'] = {}
        permissions['instance']['group'] = {}

        permissions['instance']['group']['discover'] = permissionMetadata.get_instance_groups('discover','group')
        permissions['instance']['group']['read'] = permissionMetadata.get_instance_groups('read','group')
        permissions['instance']['group']['edit'] = permissionMetadata.get_instance_groups('edit','group')

        permissions
      end
    end
  end
end
