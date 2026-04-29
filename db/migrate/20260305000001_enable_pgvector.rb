# frozen_string_literal: true

class EnablePgvector < ActiveRecord::Migration[7.2]
  def up
    enable_extension "vector"
  end

  def down
    disable_extension "vector"
  end
end
