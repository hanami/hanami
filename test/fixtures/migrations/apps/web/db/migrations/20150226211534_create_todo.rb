class CreateTodos < Lotus::Model::Migration
  def up
    create_table :todos do
      primary_key :id
      String :title
    end
  end

  def down
    drop_table :todos
  end
end
