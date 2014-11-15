module Collaboration::Controllers::Books
  include Collaboration::Controller

  class New
    include Lotus::Action
    expose :book

    def call(params)
      @book = Book.new
    end
  end

  class Index
    include Lotus::Action
    expose :books

    def call(params)
      @books = BookRepository.all
    end
  end

  class Show
    include Lotus::Action
    expose :book

    def call(params)
      @book = BookRepository.find(params[:id])
    end
  end

  class Edit
    include Lotus::Action
    expose :book

    def call(params)
      @book = BookRepository.find(params[:id])
    end
  end

  class Destroy
    include Lotus::Action

    def call(params)
      @book = BookRepository.find(params[:id])
      BookRepository.delete(@book)

      redirect_to Collaboration::Routes.url(:books)
    end
  end

  class Update
    include Lotus::Action

    def call(params)
      @book = BookRepository.find(params[:id])

      redirect_to Collaboration::Routes.url(:books, :id => @book.id)
    end
  end
end
