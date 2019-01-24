# rubocop:disable Style/SingleLineMethods, Layout/EmptyLineBetweenDefs, Naming/AccessorMethodName
class VitualTotalTestBase < ActiveRecord::Base
  self.abstract_class = true

  include VirtualFields
end

class Author < VitualTotalTestBase
  def self.connection; VitualTotalTestBase.connection; end

  has_many :books,                             :class_name => "Book", :foreign_key => "author_id"
  has_many :ordered_books,   -> { ordered },   :class_name => "Book", :foreign_key => "author_id"
  has_many :published_books, -> { published }, :class_name => "Book", :foreign_key => "author_id"
  has_many :wip_books,       -> { wip },       :class_name => "Book", :foreign_key => "author_id"
  has_many :bookmarks,                         :class_name => "Bookmark", :through => :books

  virtual_total :total_books, :books
  virtual_total :total_books_published, :published_books
  virtual_total :total_books_in_progress, :wip_books
  # same as total_books, but going through a relation with order
  virtual_total :total_ordered_books, :ordered_books
  # virtual total using through
  virtual_total :total_bookmarks, :bookmarks
  alias v_total_bookmarks total_bookmarks

  # virtual_total using a virtual_has_many
  def named_books
    # I didn't have the creativity needed to find a good ruby only check here
    books.select { |b| b.name }
  end

  virtual_has_many :named_books, :class_name => "Book"
  virtual_total :total_named_books, :named_books
  alias v_total_named_books total_named_books

  def nick_or_name
    nickname || name
  end

  virtual_attribute :nick_or_name, :string do |t|
    t.grouping(Arel::Nodes::NamedFunction.new('COALESCE', [t[:nickname], t[:name]]))
  end

  def self.create_with_books(count = 0)
    create!(:name => "foo").tap { |author| author.create_books(count) }
  end

  def create_books(count, create_attrs = {})
    count.times do
      attrs = {
        :name   => "bar",
        :author => self,
      }.merge(create_attrs)
      Book.create(attrs)
    end
  end
end

class Book < VitualTotalTestBase
  def self.connection; VitualTotalTestBase.connection end

  has_many :bookmarks, :class_name => "Bookmark", :foreign_key => "book_id"
  belongs_to :author,  :class_name => "Author",   :foreign_key => "author_id"
  scope :ordered,   -> { order(:created_on => :desc) }
  scope :published, -> { where(:published => true)  }
  scope :wip,       -> { where(:published => false) }

  virtual_delegate :name, :to => :author, :prefix => true

  def self.create_with_bookmarks(count = 0)
    a = Author.create(:name => "foo")
    create!(:name => "book", :author => a).tap { |book| book.create_bookmarks(count) }
  end

  def create_bookmarks(count, create_attrs = {})
    count.times do
      attrs = {
        :name   => "mark",
        :book   => self,
      }.merge(create_attrs)
      Bookmark.create(attrs)
    end
  end
end

class Bookmark < VitualTotalTestBase
  def self.connection; VitualTotalTestBase.connection end

  belongs_to :book, :class_name => "Book", :foreign_key => "book_id"
end
# rubocop:enable Style/SingleLineMethods, Layout/EmptyLineBetweenDefs, Naming/AccessorMethodName
