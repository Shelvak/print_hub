require 'test_helper'

class PrintsTest < ActionDispatch::IntegrationTest
  fixtures :all
  
  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = "http://localhost:54163"
    page.driver.options[:resynchronize] = true
  end
  
  ac_field = 'auto_document_print_job_print_print_jobs_attributes_0_'
  
  test 'should add a document with +' do
    adm_login
    
    assert_equal prints_path, current_path
    assert_page_has_no_errors!
    assert page.has_css?('#main_menu')
    
    within '#main_menu' do
      click_link I18n.t('menu.documents')
    end
    
    assert_equal documents_path, current_path
    assert_page_has_no_errors!
    code = nil
    barcode = nil
    code = find('.even td:first').match(/\[(\d+)/)[1].to_i
    within '.even' do
      find('a.add_link').click
      assert find('a.remove_link')
    end
    
    assert page.has_css?('nav.links')
    
    within 'nav.links' do
      click_link I18n.t('view.documents.new_print')
    end
    
    assert_equal new_print_path, current_path
    assert_page_has_no_errors!
    assert page.has_css?('.print_job', count: 1)
    
    barcode = find("##{ac_field}").value
    
    assert_equal code, barcode.match(/\[(\d+)/)[1].to_i, 'Se rajo'
   
  end
  
  test 'should print' do
  
    adm_login
    assert_equal prints_path, current_path
    assert_page_has_no_errors!
    
    within 'nav.links' do
      click_link I18n.t('view.prints.new')
    end
    
    assert_equal new_print_path, current_path
    assert page.has_css?('form.new_print')
    
    within 'form.new_print' do
        select(
        Cups.show_destinations.detect { |p| p =~ /pdf/i },
                     from: 'print_printer' )
    end
    
    within '.print_job' do |ac|
      fill_in "#{ac_field}", with: 'Math'
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find("##{ac_field}").native.send_keys :arrow_down, :tab
    end
    
    assert_difference 'Print.count' do
      click_button I18n.t('view.prints.print_title')
    end
    
    assert_page_has_no_errors!
    assert page.has_css?('#notice', text: I18n.t('view.prints.correctly_created') )
    
  end
  
  test 'should scheduled to the next first month day' do
  
    adm_login
    assert_equal prints_path, current_path
    assert_page_has_no_errors!
    
    within 'nav.links' do
      click_link I18n.t('view.prints.new')
    end
    
    assert_equal new_print_path, current_path
    assert page.has_css?('form.new_print')
    
    within 'form.new_print' do
      select(Cups.show_destinations.first, from: 'print_printer' )
      fill_in 'print_scheduled_at', with: ''
      assert page.has_xpath?("//table[@class='ui-datepicker-calendar']")
      within(:xpath, "//table[@class='ui-datepicker-calendar']") do
        find(:xpath, "//span[@class='ui-datepicker-next']").click
        find('1').click
      end
    end
    
    within '.print_job' do |ac|
      fill_in "#{ac_field}", with: 'Math'
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find("##{ac_field}").native.send_keys :arrow_down, :tab
    end
    
    assert_difference 'Print.count' do
      click_button I18n.t('view.prints.print_title')
    end
    
    assert_page_has_no_errors!
    assert page.has_css?('#notice', text: I18n.t('view.prints.correctly_created') )
    
  end
  
end
