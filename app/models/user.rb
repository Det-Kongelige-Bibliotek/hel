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
  before_save :get_ldap_name, :get_ldap_member_of

  def get_ldap_email
    emails = Devise::LDAP::Adapter.get_ldap_param(self.username, 'mail')
    self.email = emails.first.to_s unless emails.blank?
  rescue => e
    logger.error "Could not connect to LDAP: #{e}"
  end

  def get_ldap_name
    names = Devise::LDAP::Adapter.get_ldap_param(self.username, 'cn')
    self.name = names.first.to_s.force_encoding('utf-8') unless names.blank?
  end

  def get_ldap_member_of
    groups = Devise::LDAP::Adapter.get_ldap_param(self.username, 'memberOf')
    self.member_of=groups.join(';').force_encoding('utf-8') unless groups.blank?
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    name
  end


  #TODO: group names should be loaded from a config file
  def groups
    groups = ['Chronos-Alle']
    unless self.member_of.blank?
      if self.member_of.include? 'CN=Chronos-Pligtaflevering,OU=SIFD,OU=Adgangsstyring,DC=kb,DC=dk'
        groups << 'Chronos-Pligtaflevering'
      end
      if self.member_of.include? 'CN=Chronos-NSA,OU=SIFD,OU=Adgangsstyring,DC=kb,DC=dk'
        groups << 'Chronos-NSA'
      end
      if self.member_of.include? 'CN=Chronos-Admin,OU=SIFD,OU=Adgangsstyring,DC=kb,DC=dk'
        groups << 'Chronos-Admin'
      end
 #     if self.member_of.include? 'CN=Chronos-alle,OU=SIFD,OU=Adgangsstyring,DC=kb,DC=dk'
 #       groups << 'Chronos-Alle'
 #     end
    end
    groups
  end

end
