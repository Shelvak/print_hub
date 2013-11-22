require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:administrator)

    prepare_avatar_files
  end

  test 'should get index' do
    UserSession.create(@user)
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert_select '#unexpected_error', false
    assert_template 'users/index'
  end

  test 'should get new' do
    UserSession.create(@user)
    get :new
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#unexpected_error', false
    assert_template 'users/new'
  end

  test 'should create user' do
    UserSession.create(@user)
    assert_difference ['User.count', 'PaperTrail::Version.count'] do
      post :create, user: {
        name: 'New name',
        last_name: 'New last name',
        email: 'new_user@printhub.com',
        default_printer: '',
        lines_per_page: '12',
        language: LANGUAGES.first.to_s,
        username: 'new_user',
        password: 'new_password',
        password_confirmation: 'new_password',
        admin: '1',
        enable: '1',
        avatar: fixture_file_upload('/files/test.gif', 'image/gif')
      }
    end

    assert_redirected_to users_path
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal users(:administrator).id, PaperTrail::Version.last.whodunnit
  end

  test 'should show user' do
    UserSession.create(@user)
    get :show, id: @user.to_param
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#unexpected_error', false
    assert_template 'users/show'
  end

  test 'should get edit' do
    UserSession.create(@user)
    get :edit, id: @user.to_param
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#unexpected_error', false
    assert_template 'users/edit'
  end

  test 'should update user' do
    UserSession.create(@user)
    put :update, id: @user.to_param, user: {
      name: 'Updated name',
      last_name: 'Updated last name',
      email: 'updated_user@printhub.com',
      default_printer: '',
      lines_per_page: '12',
      language: LANGUAGES.first.to_s,
      password: 'updated_password',
      password_confirmation: 'updated_password',
      admin: '1',
      enable: '1'
    }
    assert_redirected_to users_path
    assert_equal 'Updated name', @user.reload.name
  end


  test 'should get autocomplete user list' do
    UserSession.create(@user)
    get :autocomplete_for_user_name, format: :json, q: 'admin'
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /admin/i }

    get :autocomplete_for_user_name, format: :json, q: 'invalid_operator'
    assert_response :success

    customers = ActiveSupport::JSON.decode(@response.body)

    assert customers.empty?

    get :autocomplete_for_user_name, format: :json, q: 'disabled operator'
    assert_response :success

    customers = ActiveSupport::JSON.decode(@response.body)

    assert customers.empty?
  end

  test 'should pay user shifts between dates' do
    UserSession.create(@user)
    user = users(:operator)
    start = 3.weeks.ago.to_date
    finish = Time.zone.today
    pending_shifts = user.shifts.pay_pending

    assert pending_shifts.size > 0

    assert_difference 'pending_shifts.count', -pending_shifts.count do
      put :pay_shifts_between, format: :json,
        id: user.to_param, start: start.to_s(:db), finish: finish.to_s(:db)
      assert_response :success
    end
  end

  test 'should get current workers' do
    UserSession.create(@user)
    get :current_workers, format: :json
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 4, users.size
  end
end
