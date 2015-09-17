class Ability
  include CanCan::Ability
  include Hydra::Ability

  def create_permissions

    if user_groups.include?('Chronos-Alle')
      can [:create], Work
      can [:create], Authority::Person
    end

    if user_groups.include?('Chronos-Admin')
      can [:create], Administration::Activity
      can [:create], Administration::ControlledList
    end

    if (user_groups & ['Chronos-Pligtaflevering','Chronos-Admin']).present?
      can [:create], Instance
    end
  end

  def custom_permissions
    can [:destroy], ActiveFedora::Base do |obj|
      test_edit(obj.pid)
    end

    can [:download], ContentFile do |cf|
      test_read(cf.pid)
    end

    can [:upload, :update], ContentFile do |cf|
      test_edit(cf.pid)
    end

    can [:update], Authority::Person do |p|
      test_edit(p.pid)
    end

    can [:send_to_preservation, :update_adminstration], Instance do |obj|
      test_edit(obj.pid)
    end

    can [:validate_tei], Instance do |obj|
      test_read(obj.pid)
    end


    if (user_groups & ['Chronos-Pligtaflevering','Chronos-Admin']).present?
      can [:aleph], Work
    end
  end
end
