require 'test_helper'

class TagsTest < ActionDispatch::IntegrationTest
  fixtures :all
  
  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = "http://localhost:54163"
    page.driver.options[:resynchronize] = true
  end
  
  
  test 'should destroy a tag' do
    adm_login 

    assert_equal prints_path, current_path
    assert_page_has_no_errors!

    assert page.has_css?('#main_menu')

    within '#main_menu' do
      click_link I18n.t('menu.tags')
    end

    assert_equal tags_path, current_path
    assert_page_has_no_errors!
    assert page.has_css?('table.list')

    within 'table.list' do
#      assert_difference 'Tag.count', (Tag.count.to_i - 1) do
        click_button I18n.t('label.delete')
        page.driver.browser.switch_to.alert.accept
#      end
    end
    

    assert_page_has_no_errors!
    assert_equal tags_path, current_path

  end
   
  test 'should create tags into tags' do
    adm_login

    assert_equal prints_path, current_path
    assert_page_has_no_errors!

    assert page.has_css?('#main_menu')

    within '#main_menu' do
      click_link I18n.t('menu.tags')
    end

    assert_equal tags_path, current_path
    assert_page_has_no_errors!

    within 'nav.links' do
      click_link I18n.t('label.new')
    end

    assert_equal new_tag_path, current_path
    assert_page_has_no_errors!

    fill_in 'tag_name', with: 'Lali'

    assert_difference 'Tag.count' do
      click_button I18n.t('helpers.submit.create', model: Tag.model_name.human)
    end

    assert page.has_css?('#notice', 
                   text: I18n.t('view.tags.correctly_created'))
    assert_equal tags_path, current_path
    assert_page_has_no_errors!

    click_link 'Lali'

    assert_page_has_no_errors!

    within 'nav.links' do
    click_link I18n.t('label.new')
    end

    assert_equal new_tag_path, current_path
    assert_page_has_no_errors!

    fill_in 'tag_name', with: 'Rucutu'

    assert_difference 'Tag.count'do
      click_button I18n.t('helpers.submit.create', model: Tag.model_name.human)
    end

    assert_page_has_no_errors!
    assert page.has_css?('#notice', text: I18n.t('view.tags.correctly_created'))

  end
   
end
