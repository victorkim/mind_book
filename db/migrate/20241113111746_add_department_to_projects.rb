class AddDepartmentToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :department, :string, null: false, default: "All Departments"
  end
end
