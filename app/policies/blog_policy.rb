class BlogPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(published: true)
    end
  end

  def show?
    true  # Anyone can view blogs
  end

  def create?
    true  # Anyone can create blogs (adjust as needed)
  end

  def update?
    true  # Anyone can update blogs (adjust as needed)
  end

  def destroy?
    true  # Anyone can delete blogs (adjust as needed)
  end
end