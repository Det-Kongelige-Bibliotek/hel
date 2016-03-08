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
    #Hack for sifd test users, which do not have an email
    logger.debug("getting email for #{self.username}")
    if (self.username.start_with? 'sfidtest')
      self.email = "#{self.username}@kb.dk"
    else
      emails = Devise::LDAP::Adapter.get_ldap_param(self.username, 'mail')
      self.email = emails.first.to_s unless emails.blank?
    end
  rescue => e
    logger.error "Could not connect to LDAP: #{e}"
  end

  def get_ldap_name
    names = Devise::LDAP::Adapter.get_ldap_param(self.username, 'cn')
    self.name = names.first.to_s.force_encoding('utf-8') unless names.blank?
  rescue => e
    logger.error "User: error getting name #{e}"
  end

  def get_ldap_member_of
    groups = Devise::LDAP::Adapter.get_ldap_param(self.username, 'memberOf')
    self.member_of=groups.join(';').force_encoding('utf-8') unless groups.blank?
  rescue => e
    logger.error "User: error getting member of #{e}"
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    name
  end

  def admin?
    self.member_of.include? 'CN=Chronos-Admin,OU=SIFD,OU=Adgangsstyring,DC=kb,DC=dk'
  end

  def student?
    self.member_of.include? 'CN=Chronos-student,OU=SIFD,OU=Adgangsstyring,DC=kb,DC=dk'
  end

  #TODO: group names should be loaded from a config file
  def groups
    groups = []
    groups << 'Chronos-Alle' unless (self.new_record?)
    # groups << 'Chronos-Admin' unless (self.new_record?)

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
      if self.member_of.include? 'CN=Chronos-student,OU=SIFD,OU=Adgangsstyring,DC=kb,DC=dk'
        groups << 'Chronos-student'
      end
 #     if self.member_of.include? 'CN=Chronos-alle,OU=SIFD,OU=Adgangsstyring,DC=kb,DC=dk'
 #       groups << 'Chronos-Alle'
 #     end
    end
    groups
  end

end
