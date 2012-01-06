require 'test_helper'

class PrivateCustomerInteractionsTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = "http://#{CUSTOMER_SUBDOMAIN}.lvh.me:54163"
  end
  
  test 'should search with no results and show contextual help' do
    login
    
    assert page.has_css?('#empty_catalog_help')
    
    fill_in 'search_query', with: 'inexistent document'
    
    click_button I18n.t('label.search')
    
    assert_equal catalog_path, current_path
    assert_page_has_no_errors!
    assert page.has_css?('#empty_search_in_catalog_help')
  end
  
  test 'should complete an order' do
    login
    
    fill_in 'search_query', with: 'Math'
    
    click_button I18n.t('label.search')
    
    assert_page_has_no_errors!
    assert page.has_css?('table.list')
    assert page.has_css?('a.add_to_order')
    assert !page.has_css?('a.remove_from_order')
    
    within 'table.list' do
      find('a.add_to_order').click
      assert page.has_css?('a.remove_from_order')
    end
    
    within '#menu_links' do
      click_link I18n.t('view.catalog.new_order')
    end
    
    assert_equal new_order_path, current_path
    assert_page_has_no_errors!
    assert page.has_css?('#check_order')

    assert_difference 'Order.count' do
      click_button I18n.t(
        'helpers.submit.create', model: Order.model_name.human
      )
    end
    
    assert_page_has_no_errors!
    assert page.has_css?('#show_order')
  end
  
  test 'all on client calculations in new order should work' do
    documents(:math_book).tap do |document|
      visit add_to_order_by_code_catalog_path(document.code)
      
      assert_page_has_no_errors!
    end
    
    login expected_path: new_order_path
    
    assert_page_has_no_errors!
    assert page.has_css?('#check_order')
    
    within 'form' do
      pages = find('input[name$="[two_sided]"]').click
      copies = find('input[name$="[copies]"]').value.to_i || 0
      pages = find('input[name$="[pages]"]').value.to_i || 0
      price_per_copy = find('input[name$="[price_per_copy]"]').value.to_f || 0.0
      total_should_be = copies * pages * price_per_copy
      
      within '.nested_item_actions' do
        assert find('.money').has_content?("$#{total_should_be}")
      end
    end
  end
  
  private
  
  def login(options = {})
    options.reverse_merge!(
      customer_id: :student_without_bonus,
      expected_path: catalog_path
    )
    
    visit new_customer_session_path
    
    assert_page_has_no_errors!
    
    customers(options[:customer_id]).tap do |customer|
      fill_in I18n.t('authlogic.attributes.customer_session.email'),
        with: customer.email
      fill_in I18n.t('authlogic.attributes.customer_session.password'),
        with: "#{options[:customer_id]}123"
    end
    
    click_button I18n.t('view.customer_sessions.login')
    
    assert_equal options[:expected_path], current_path
    assert_page_has_no_errors!
  end
end