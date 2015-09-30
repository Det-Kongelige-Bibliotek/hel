module Administration
  class Activity < ActiveFedora::Base

    include Hydra::AccessControls::Permissions
    include Concerns::AdminMetadata
    include Concerns::Preservation

    contains 'permissionMetadata', class_name: 'Datastreams::PermissionMetadata'
    validates :activity, presence: true

    before_save do
      self.edit_groups = ['Chronos-Admin']
      self.read_groups = ['Chronos-Alle']
    end

    def can_perform_cascading
      false
    end


    # this stuff clashes with the default HydraAccessControls
    # commenting it out until we find out if it should be removed or not
    def activity_permissions=(val)
      permissionMetadata.remove_permissions
      val['instance']['group'].each do |access,groups|
        groups.each{|g| permissionMetadata.add_instance_permission(g,access,'group')} unless groups.blank?
      end
      val['file']['group'].each do |access,groups|
        groups.each{|g| permissionMetadata.add_file_permission(g,access,'group')} unless groups.blank?
      end
    end

    def activity_permissions
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

    def present_in_GUI?
      adminMetadata.edit_in_GUI.present? && edit_in_GUI == "1"
    end

    def self.activities_for_dropdown
      ::Administration::Activity.all.select{|a| a.present_in_GUI?}
    end

  end
end
