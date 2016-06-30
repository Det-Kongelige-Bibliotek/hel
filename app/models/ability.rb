class Ability
  include CanCan::Ability
  include Hydra::Ability

  def create_permissions

    if user_groups.include?('Chronos-Alle')
      can [:create], Work
      can [:create], Authority::Organization
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

    unless (user_groups & ['Chronos-Admin']).present?
      cannot [:destroy], ActiveFedora::Base
    end

    can [:download], ContentFile do |cf|
      test_read(cf.id)
    end

    can [:upload, :update], ContentFile do |cf|
      test_edit(cf.id)
    end

    can [:send_to_preservation, :update_adminstration], Instance do |obj|
      test_edit(obj.id)
    end

    can [:validate_tei], Instance do |obj|
      test_read(obj.id)
    end


    unless (user_groups & ['Chronos-Pligtaflevering','Chronos-Admin']).present?
      cannot [:aleph], Work
    end

    unless (user_groups & ['Chronos-Alle', 'Chronos-Pligtaflevering','Chronos-Admin']).present?
      cannot [:email], Work
    end

    unless (user_groups & ['Chronos-Admin','Chronos-Pligtaflevering','Chronos-student' ]).present?
      cannot [:edit], Authority::Person
      cannot [:viaf], Authority::Person
      cannot [:edit], Authority::Organization
      cannot [:viaf], Authority::Organization
    end


    unless (user_groups & ['Chronos-Admin']).present?
      cannot [:destroy], Authority::Person
      cannot [:destroy], Authority::Organization
      cannot [:destroy], LetterBook
      cannot [:edit], LetterBook
    end

    can [:viaf], Authority::Person
    can [:viaf], Authority::Organization

  end
end
