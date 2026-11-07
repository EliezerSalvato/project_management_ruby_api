class AddLowerNameIndexToProjects < ActiveRecord::Migration[8.1]
  def change
    add_index :projects, "user_id, LOWER(name), id", name: "index_projects_on_user_id_and_lower_name_and_id"
  end
end
