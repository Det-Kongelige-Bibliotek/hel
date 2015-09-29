module Datastreams
  class PermissionMetadata < ActiveFedora::OmDatastream
    # Inserted maintain existing naming of solr fields in Activefedora 8
    # And thus avoid anoing deprecation warning messages
    def prefix(*args)
      ""
    end

    set_terminology do |t|
      t.file do
        t.permission do
          t.Permission
        end
      end
      t.instance do
        t.permission do
          t.Permission
        end
      end
    end

    def get_file_groups(access,type)
      get_file_permissions.select{|p| p['access']==access && p['type']==type}.collect{|p| p['name']}
    end

    def get_instance_groups(access,type)
      get_instance_permissions.select{|p| p['access']==access && p['type']==type}.collect{|p| p['name']}
    end

    def get_file_permissions
      permissions = []
      file.permission.nodeset.each do |n|
        permissions.push({'name'=> n.css('name').text, 'access'=> n.css('access').text, 'type'=> n.css('type').text})
      end
      permissions
    end

    def add_file_permission(name,access,type)
      node = find_by_terms(:file).first
      add_child_node(node,:permission,name,access,type)
      content_will_change!
    end

    def get_instance_permissions
      permissions = []
      instance.permission.nodeset.each do |n|
        permissions.push({'name'=> n.css('name').text, 'access'=> n.css('access').text, 'type'=> n.css('type').text})
      end
      permissions
    end

    def add_instance_permission(name,access,type)
      node = find_by_terms(:instance).first
      add_child_node(node,:permission,name,access,type)
      content_will_change!
    end

    def remove_permissions
      file.permission.nodeset.each{|n| n.remove}
      instance.permission.nodeset.each{|n| n.remove}
      content_will_change!
    end

    define_template :permission do |xml, name, access, type|
      xml.permission do
        xml.Permission do
            xml.name {xml.text(name)}
            xml.access {xml.text(access)}
            xml.type {xml.text(type)}
        end
      end
    end

    def self.xml_template
      Nokogiri::XML.parse('<fields><file/><instance/></fields>')
    end
  end
end