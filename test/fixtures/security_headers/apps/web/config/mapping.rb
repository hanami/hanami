collection :books do
  entity 'Book'
  repository 'BookRepository'

  attribute :id,   Integer
  attribute :name, String
end
