class CreateTasks < Lotus::Model::Migration
  def up
    create_table :tasks do
      primary_key :id
      String :text
    end
  end

  def down
    drop_table :tasks
  end
end
