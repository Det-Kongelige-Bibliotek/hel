class User < ActiveRecord::Base
# Connects this user object to Hydra behaviors. 
 include Hydra::User

  #attr_accessible :email, :password, :password_confirmation if Rails::VERSION::MAJOR < 4
# Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_validation :get_ldap_email
  before_save :get_ldap_name, :get_ldap_memberOf

  def get_ldap_email
    logger.debug("getting email")
    emails = Devise::LDAP::Adapter.get_ldap_param(self.username,"mail")
    self.email = emails.first.to_s unless emails.blank?
  end

  def get_ldap_name
    names = Devise::LDAP::Adapter.get_ldap_param(self.username,"cn")
    self.name = names.first.to_s.force_encoding("utf-8") unless names.blank?
  end

  def get_ldap_memberOf
    groups = Devise::LDAP::Adapter.get_ldap_param(self.username,"memberOf")
    self.memberOf=groups.join(';').force_encoding("utf-8") unless groups.blank?
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    name
  end

  #TODO: Change to reflect the Valhal usergroups, when they are defined
  def groups
    array = []
    unless self.memberOf.blank?
      if self.memberOf.include? 'CN=Brugerbasen_SuperAdmins,OU=Brugerbasen,OU=Adgangsstyring,DC=kb,DC=dk'
        array << "admin"
      end
    end
    array
  end

end
