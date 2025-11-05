class BlogPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(published: true)
    end
  end

  def show?
    true 
  end

  def create?
    true 
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
end