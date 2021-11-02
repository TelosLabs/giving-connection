# frozen_string_literal: true

class CreateServices < ActiveRecord::Migration[6.1]
  def change
    create_table :services do |t|
      t.string :name
      t.text :description
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end
  end
end
