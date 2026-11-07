class AddDatesCheckToProjects < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :projects, "end_date >= start_date", name: "projects_end_date_not_before_start_date"
  end
end
