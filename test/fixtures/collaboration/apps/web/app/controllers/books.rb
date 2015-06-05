module Collaboration::Controllers::Books
  class New
    include Collaboration::Action
    expose :book

    def call(params)
      @book = Book.new
    end
  end

  class Index
    include Collaboration::Action
    expose :books

    def call(params)
      @books = BookRepository.all
    end
  end

  class Show
    include Collaboration::Action
    expose :book

    def call(params)
      @book = BookRepository.find(params[:id])
    end
  end

  class Edit
    include Collaboration::Action
    expose :book

    def call(params)
      @book = BookRepository.find(params[:id])
    end
  end

  class Destroy
    include Collaboration::Action

    def call(params)
      @book = BookRepository.find(params[:id])
      BookRepository.delete(@book)

      redirect_to routes.url(:books)
    end
  end

  class Create
    include Collaboration::Action

    def call(params)
      @book = Book.new(params[:book])
      @book = BookRepository.create(@book)

      redirect_to routes.url(:book, :id => @book.id)
    end
  end

  class Update
    include Collaboration::Action

    def call(params)
      @book = BookRepository.find(params[:id])
      @book.update(params[:book])
      @book = BookRepository.update(@book)

      redirect_to routes.url(:book, :id => @book.id)
    end
  end
end
