class CommentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def update?
    user.present? && (record.user_id == user.id || user.try(:admin?))
  end

  def destroy?
    user.present? && (record.user_id == user.id || user.try(:admin?))
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
