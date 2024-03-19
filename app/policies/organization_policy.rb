# frozen_string_literal: true

class OrganizationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def update?
    record.organization_admins.exists?(user_id: user.id)
  end

  def delete_upload?
    record.organization_admins.exists?(user_id: user.id)
  end
end
