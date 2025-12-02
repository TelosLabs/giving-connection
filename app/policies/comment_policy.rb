class CommentPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    user.present? && record.user_id == user.id
  end

  def destroy?
    user.present? && record.user_id == user.id
  end

  def edit?
    user.present? && record.user_id == user.id
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
