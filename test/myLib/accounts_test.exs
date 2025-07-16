defmodule MyLib.AccountsTest do
  use MyLib.DataCase

  alias MyLib.Accounts

  describe "users" do
    alias MyLib.Accounts.User

    import MyLib.AccountsFixtures

    @invalid_attrs %{name: nil, age: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{name: "some name", age: 42}

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.name == "some name"
      assert user.age == 42
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{name: "some updated name", age: 43}

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.name == "some updated name"
      assert user.age == 43
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "books" do
    alias MyLib.Accounts.Book

    import MyLib.AccountsFixtures

    @invalid_attrs %{title: nil, author: nil, isbn: nil, published_at: nil}

    test "list_books/0 returns all books" do
      book = book_fixture()
      assert Accounts.list_books() == [book]
    end

    test "get_book!/1 returns the book with given id" do
      book = book_fixture()
      assert Accounts.get_book!(book.id) == book
    end

    test "create_book/1 with valid data creates a book" do
      valid_attrs = %{title: "some title", author: "some author", isbn: "some isbn", published_at: ~D[2025-07-15]}

      assert {:ok, %Book{} = book} = Accounts.create_book(valid_attrs)
      assert book.title == "some title"
      assert book.author == "some author"
      assert book.isbn == "some isbn"
      assert book.published_at == ~D[2025-07-15]
    end

    test "create_book/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_book(@invalid_attrs)
    end

    test "update_book/2 with valid data updates the book" do
      book = book_fixture()
      update_attrs = %{title: "some updated title", author: "some updated author", isbn: "some updated isbn", published_at: ~D[2025-07-16]}

      assert {:ok, %Book{} = book} = Accounts.update_book(book, update_attrs)
      assert book.title == "some updated title"
      assert book.author == "some updated author"
      assert book.isbn == "some updated isbn"
      assert book.published_at == ~D[2025-07-16]
    end

    test "update_book/2 with invalid data returns error changeset" do
      book = book_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_book(book, @invalid_attrs)
      assert book == Accounts.get_book!(book.id)
    end

    test "delete_book/1 deletes the book" do
      book = book_fixture()
      assert {:ok, %Book{}} = Accounts.delete_book(book)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_book!(book.id) end
    end

    test "change_book/1 returns a book changeset" do
      book = book_fixture()
      assert %Ecto.Changeset{} = Accounts.change_book(book)
    end
  end

  describe "loans" do
    alias MyLib.Accounts.Loan

    import MyLib.AccountsFixtures

    @invalid_attrs %{borrows_at: nil, due_at: nil, returned_at: nil, user_id: nil, book_id: nil}

    test "list_loans/0 returns all loans" do
      loan = loan_fixture()
      assert Accounts.list_loans() == [loan]
    end

    test "get_loan!/1 returns the loan with given id" do
      loan = loan_fixture()
      assert Accounts.get_loan!(loan.id) == loan
    end

    test "create_loan/1 with valid data creates a loan" do
      valid_attrs = %{borrows_at: ~N[2025-07-15 02:55:00], due_at: ~N[2025-07-15 02:55:00], returned_at: ~N[2025-07-15 02:55:00], user_id: "some user_id", book_id: "some book_id"}

      assert {:ok, %Loan{} = loan} = Accounts.create_loan(valid_attrs)
      assert loan.borrows_at == ~N[2025-07-15 02:55:00]
      assert loan.due_at == ~N[2025-07-15 02:55:00]
      assert loan.returned_at == ~N[2025-07-15 02:55:00]
      assert loan.user_id == "some user_id"
      assert loan.book_id == "some book_id"
    end

    test "create_loan/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_loan(@invalid_attrs)
    end

    test "update_loan/2 with valid data updates the loan" do
      loan = loan_fixture()
      update_attrs = %{borrows_at: ~N[2025-07-16 02:55:00], due_at: ~N[2025-07-16 02:55:00], returned_at: ~N[2025-07-16 02:55:00], user_id: "some updated user_id", book_id: "some updated book_id"}

      assert {:ok, %Loan{} = loan} = Accounts.update_loan(loan, update_attrs)
      assert loan.borrows_at == ~N[2025-07-16 02:55:00]
      assert loan.due_at == ~N[2025-07-16 02:55:00]
      assert loan.returned_at == ~N[2025-07-16 02:55:00]
      assert loan.user_id == "some updated user_id"
      assert loan.book_id == "some updated book_id"
    end

    test "update_loan/2 with invalid data returns error changeset" do
      loan = loan_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_loan(loan, @invalid_attrs)
      assert loan == Accounts.get_loan!(loan.id)
    end

    test "delete_loan/1 deletes the loan" do
      loan = loan_fixture()
      assert {:ok, %Loan{}} = Accounts.delete_loan(loan)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_loan!(loan.id) end
    end

    test "change_loan/1 returns a loan changeset" do
      loan = loan_fixture()
      assert %Ecto.Changeset{} = Accounts.change_loan(loan)
    end
  end
end
