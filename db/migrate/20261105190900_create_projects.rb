class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    enable_extension "unaccent"

    create_table :projects, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :client_name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.boolean :favorite, null: false, default: false

      t.timestamps
    end
  end
end
