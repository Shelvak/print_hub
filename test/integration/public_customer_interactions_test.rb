require 'test_helper'

class PublicCustomerInteractionsTest < ActionDispatch::IntegrationTest
  setup do
    subdomain = APP_CONFIG['subdomains']['customers']
    Capybara.app_host = "http://#{subdomain}.lvh.me:54163"
  end

  test 'should register a new customer and should login' do
    visit new_customer_session_path

    assert_page_has_no_errors!

    click_link I18n.t('view.customers.register')

    assert_page_has_no_errors!
    assert_equal new_customer_path, current_path

    fill_in Customer.human_attribute_name('name'), with: 'Jar Jar'
    fill_in Customer.human_attribute_name('lastname'), with: 'Binks'
    fill_in Customer.human_attribute_name('identification'), with: '111'
    fill_in Customer.human_attribute_name('email'), with: 'jar_jar@printhub.com'
    fill_in Customer.human_attribute_name('password'), with: 'jj12'
    fill_in Customer.human_attribute_name('password_confirmation'), with: 'jj12'

    ['Customer.count', 'Sidekiq::Extensions::DelayedMailer.jobs.size'].tap do |c|
      assert_difference(c) { click_button I18n.t('view.customers.register') }
    end

    assert_equal new_customer_session_path, current_path
    assert_page_has_no_errors!
    assert page.has_content?(I18n.t('view.customers.correctly_registered'))

    fill_in I18n.t('authlogic.attributes.customer_session.email'),
      with: 'jar_jar@printhub.com'
    fill_in I18n.t('authlogic.attributes.customer_session.password'),
      with: 'jj12'

    click_button I18n.t('view.customer_sessions.login')

    assert_equal catalog_path, current_path
    assert_page_has_no_errors!
  end

  test 'should reset password' do
    visit new_customer_session_path

    assert_page_has_no_errors!

    click_link I18n.t('view.customers.forgot_password')

    assert_page_has_no_errors!
    assert_equal new_password_reset_path, current_path

    customers(:student).tap do |customer|
      fill_in Customer.human_attribute_name('email'), with: customer.email

      assert_difference 'Sidekiq::Extensions::DelayedMailer.jobs.size' do
        click_button I18n.t('view.password_resets.request_reset')
      end

      assert_equal new_customer_session_path, current_path
      assert_page_has_no_errors!

      assert page.has_css?('.alert', text:
        I18n.t('view.password_resets.instructions_delivered')
      )
    end
  end

  test 'should give positive feedback in new customer help' do
    visit new_customer_path

    assert_page_has_no_errors!

    within '.feedback' do
      assert_difference 'Feedback.positive.count' do
        click_link 'Si'

        assert page.has_content?(I18n.t('view.feedbacks.positive_return'))
      end

      assert_equal 'new_customer',
        Feedback.positive.order('created_at').last.item
    end
  end

  test 'should give negative feedback with comment in new customer help' do
    visit new_customer_path

    assert_page_has_no_errors!

    within '.feedback' do
      assert_difference 'Feedback.negative.count' do
        click_link 'No'

        assert page.has_content?(I18n.t('view.feedbacks.negative_return'))
      end

      Feedback.negative.order('created_at').last.tap do |feedback|
        assert_equal 'new_customer', feedback.item
        assert feedback.comments.blank?
      end

      fill_in 'feedback_comments', with: 'No me sirve'

      click_button I18n.t('view.feedbacks.submit')
      assert page.has_content?(I18n.t('view.feedbacks.negative_comment_return'))

      assert_equal 'No me sirve',
        Feedback.negative.order('created_at').last.comments
    end
  end
end
